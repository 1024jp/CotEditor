//
//  SyntaxHighlightParseOperation.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-01-06.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2018 1024jp
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

private struct QuoteCommentItem {
    
    let type: SyntaxType
    let token: String
    let role: Role
    let range: NSRange
    
    
    enum Token {
        static let inlineComment = "inlineComment"
        static let blockComment = "blockComment"
    }
    
    
    struct Role: OptionSet {
        
        let rawValue: Int
        
        static let begin = Role(rawValue: 1 << 0)
        static let end   = Role(rawValue: 1 << 1)
    }
}



// MARK: -

final class SyntaxHighlightParseOperation: Operation, ProgressReporting {
    
    struct ParseDefinition {
        
        var extractors: [SyntaxType: [HighlightExtractable]]
        var pairedQuoteTypes: [String: SyntaxType]  // dict for quote pair to extract with comment
        var inlineCommentDelimiter: String?
        var blockCommentDelimiters: Pair<String>?
    }
    
    typealias HighlightBlock = (_ highlights: [SyntaxType: [NSRange]], _ completionHandler: @escaping () -> Void) -> Void
    
    
    
    // MARK: Public Properties
    
    let string: String
    let progress: Progress  // can be updated from a background thread
    
    
    // MARK: Private Properties
    
    private let definition: ParseDefinition
    private let parseRange: NSRange
    private let highlightBlock: HighlightBlock
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init(definition: ParseDefinition, string: String, range parseRange: NSRange, highlightBlock: @escaping HighlightBlock) {
        
        self.definition = definition
        self.string = string
        self.parseRange = parseRange
        self.highlightBlock = highlightBlock
        
        // +1 for extractCommentsWithQuotes()
        // +1 for highlighting
        self.progress = Progress(totalUnitCount: Int64(definition.extractors.count + 2))
        
        super.init()
        
        self.progress.cancellationHandler = { [weak self] in
            self?.cancel()
        }
    }
    
    
    
    // MARK: Operation Methods
    
    /// is ready to run
    override var isReady: Bool {
        
        return true
    }
    
    
    /// parse string in background and return extracted highlight ranges per syntax types
    override func main() {
        
        let results = self.extractHighlights()
        
        guard !self.isCancelled else { return }
        
        self.progress.localizedDescription = "Applying colors to text".localized
        
        let progress = self.progress
        self.highlightBlock(results) {
            progress.completedUnitCount += 1
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// extract all highlight ranges in the parse range
    private func extractHighlights() -> [SyntaxType: [NSRange]] {
        
        var highlights = [SyntaxType: [NSRange]]()
        
        // extract standard highlight ranges
        let rangesQueue = DispatchQueue(label: "com.coteditor.CotEdiotor.syntax.ranges", attributes: .concurrent)
        for syntaxType in SyntaxType.allCases {
            guard let extractors = self.definition.extractors[syntaxType] else { continue }
            
            self.progress.localizedDescription = String(format: "Extracting %@…".localized, syntaxType.localizedName)
            
            let childProgress = Progress(totalUnitCount: Int64(extractors.count), parent: self.progress, pendingUnitCount: 1)
            
            var ranges = [NSRange]()
            
            DispatchQueue.concurrentPerform(iterations: extractors.count) { (index: Int) in
                guard !self.isCancelled else { return }
                
                let extractedRanges = extractors[index].ranges(in: self.string, range: self.parseRange)
                
                rangesQueue.async(flags: .barrier) {
                    childProgress.completedUnitCount += 1
                    ranges += extractedRanges
                }
            }
            
            highlights[syntaxType] = rangesQueue.sync { ranges }
            
            childProgress.completedUnitCount = childProgress.totalUnitCount
        }
        
        guard !self.isCancelled else { return [:] }
        
        // extract comments and quoted text
        self.progress.localizedDescription = String(format: "Extracting %@…".localized, "comments and quoted texts".localized)
        highlights.merge(self.extractCommentsWithQuotes()) { $0 + $1 }
        
        guard !self.isCancelled else { return [:] }
        
        let sanitized = sanitize(highlights: highlights)
        
        self.progress.completedUnitCount += 1
        
        return sanitized
    }
    
    
    /// extract ranges of quoted texts as well as comments in the parse range
    private func extractCommentsWithQuotes() -> [SyntaxType: [NSRange]] {
        
        let string = self.string as NSString
        var positions = [QuoteCommentItem]()
        
        if let delimiters = self.definition.blockCommentDelimiters {
            positions += string.ranges(of: delimiters.begin, range: self.parseRange)
                .map { QuoteCommentItem(type: .comments, token: QuoteCommentItem.Token.blockComment, role: .begin, range: $0) }
            positions += string.ranges(of: delimiters.end, range: self.parseRange)
                .map { QuoteCommentItem(type: .comments, token: QuoteCommentItem.Token.blockComment, role: .end, range: $0) }
        }
        
        if let delimiter = self.definition.inlineCommentDelimiter {
            positions += string.ranges(of: delimiter, range: self.parseRange)
                .flatMap { range -> [QuoteCommentItem] in
                    let lineRange = string.lineRange(for: range)
                    let endRange = NSRange(location: lineRange.upperBound, length: 0)
                    
                    return [QuoteCommentItem(type: .comments, token: QuoteCommentItem.Token.inlineComment, role: .begin, range: range),
                            QuoteCommentItem(type: .comments, token: QuoteCommentItem.Token.inlineComment, role: .end, range: endRange)]
                }
        }
        
        for (quote, type) in self.definition.pairedQuoteTypes {
            positions += string.ranges(of: quote, range: self.parseRange)
                .map { QuoteCommentItem(type: type, token: quote, role: [.begin, .end], range: $0) }
        }
        
        // filter escaped ones
        positions = positions.filter { !self.string.isCharacterEscaped(at: $0.range.location) }
        
        // sort by location
        positions.sort {
            if $0.range.location < $1.range.location { return true }
            if $0.range.location > $1.range.location { return false }
            
            if $0.range.length == 0 { return true }
            if $1.range.length == 0 { return false }
            
            guard $0.role.rawValue == $1.role.rawValue else {
                return $0.role.rawValue > $1.role.rawValue
            }
            return $0.range.length > $1.range.length
        }
        
        // scan quoted strings and comments in the parse range
        var highlights = [SyntaxType: [NSRange]]()
        var seekLocation = self.parseRange.location
        var searchingItem: QuoteCommentItem?
        
        for position in positions {
            // search next begin delimiter
            guard let item = searchingItem else {
                if position.role.contains(.begin), position.range.location >= seekLocation {
                    searchingItem = position
                }
                continue
            }
            
            // search corresponding end delimiter
            if position.role.contains(.end), position.token == item.token {
                let range = NSRange(item.range.lowerBound..<position.range.upperBound)
                
                highlights[item.type, default: []].append(range)
                
                searchingItem = nil
                seekLocation = range.upperBound
            }
        }
        
        // highlight until the end if not closed
        if let item = searchingItem {
            let range = NSRange(item.range.lowerBound..<self.parseRange.upperBound)
            
            highlights[item.type, default: []].append(range)
        }
        
        return highlights
    }
    
}



// MARK: Private Functions

/// Remove duplicated coloring ranges.
///
/// This sanitization will reduce performance time of `applyHighlights:highlights:layoutManager:` significantly.
/// Adding temporary attribute to a layoutManager is quite sluggish,
/// so we want to remove useless highlighting ranges as many as possible beforehand.
private func sanitize(highlights: [SyntaxType: [NSRange]]) -> [SyntaxType: [NSRange]] {
    
    var sanitizedHighlights = [SyntaxType: [NSRange]]()
    let highlightedIndexes = NSMutableIndexSet()
    
    for type in SyntaxType.allCases.reversed() {
        guard let ranges = highlights[type] else { continue }
        var sanitizedRanges = [NSRange]()
        
        for range in ranges {
            guard !highlightedIndexes.contains(in: range) else { continue }
            
            sanitizedRanges.append(range)
            highlightedIndexes.add(in: range)
        }
        
        guard !sanitizedRanges.isEmpty else { continue }
        
        sanitizedHighlights[type] = sanitizedRanges
    }
    
    return sanitizedHighlights
}
