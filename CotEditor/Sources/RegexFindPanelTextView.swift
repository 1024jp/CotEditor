//
//  RegexFindPanelTextView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-04-05.
//
//  ---------------------------------------------------------------------------
//
//  © 2018 1024jp
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

import Cocoa

final class RegexFindPanelTextView: FindPanelTextView {
    
    // MARK: Public Properties
    
    var isRegularExpressionMode: Bool = false {
        
        didSet {
            self.invalidateRegularExpression()
        }
    }
    
    
    // MARK: -
    // MARK: Text View Methods
    
    /// content string did update
    override func didChangeText() {
        
        super.didChangeText()
        
        self.invalidateRegularExpression()
    }
    
    
    /// adjust word selection range
    override func selectionRange(forProposedRange proposedCharRange: NSRange, granularity: NSSelectionGranularity) -> NSRange {
        
        let range = super.selectionRange(forProposedRange: proposedCharRange, granularity: granularity)
        
        guard self.isRegularExpressionMode else { return range }
        
        guard granularity == .selectByWord else { return range }
        
        // settle result on expanding selection or if there is no possibility for clicking a bracket
        guard proposedCharRange.length == 0, range.length == 1 else { return range }
        
        let characterIndex = Range(range, in: self.string)!.lowerBound
        
        // select inside of brackets
        if let pairIndex = self.string.indexOfBracePair(at: characterIndex, candidates: [BracePair("(", ")"), BracePair("[", "]")], ignoring: BracePair("[", "]")) {
            switch pairIndex {
            case .begin(let beginIndex):
                return NSRange(beginIndex...characterIndex, in: self.string)
            case .end(let endIndex):
                return NSRange(characterIndex...endIndex, in: self.string)
            case .odd:
                return NSRange(characterIndex...characterIndex, in: self.string)
            }
        }
        
        return range
    }
    
    
    /// selection did change
    override func setSelectedRange(_ charRange: NSRange, affinity: NSSelectionAffinity, stillSelecting stillSelectingFlag: Bool) {
        
        super.setSelectedRange(charRange, affinity: affinity, stillSelecting: stillSelectingFlag)
        
        guard self.isRegularExpressionMode, !stillSelectingFlag else { return }
        
        self.highligtMatchingBrace(candidates: [BracePair("(", ")"), BracePair("[", "]")], ignoring: BracePair("[", "]"))
    }
    
    
    
    // MARK: Private Methods
    
    /// highlight string as regular expression pattern
    private func invalidateRegularExpression() {
        
        guard let layoutManager = self.layoutManager else { return }
        
        // clear the last highlight anyway
        layoutManager.removeTemporaryAttribute(.foregroundColor, forCharacterRange: self.string.nsRange)
        
        guard
            self.isRegularExpressionMode,
            (try? NSRegularExpression(pattern: self.string)) != nil  // check if pattern is valid
            else { return }
        
        for type in RegularExpressionSyntaxType.priority.reversed() {
            for range in type.ranges(in: self.string) {
                layoutManager.addTemporaryAttribute(.foregroundColor, value: type.color, forCharacterRange: range)
            }
        }
    }
    
}


private extension RegularExpressionSyntaxType {
    
    var color: NSColor {
        
        switch self {
        case .character: return #colorLiteral(red: 0.1176470596, green: 0.4011936392, blue: 0.5, alpha: 1)
        case .backReference: return #colorLiteral(red: 0.7471567648, green: 0.07381642141, blue: 0.5326599043, alpha: 1)
        case .symbol: return #colorLiteral(red: 0.3934386824, green: 0.5045222784, blue: 0.1255275325, alpha: 1)
        case .quantifier: return #colorLiteral(red: 0.4634826636, green: 0, blue: 0.6518557685, alpha: 1)
        case .anchor: return #colorLiteral(red: 0.7450980544, green: 0.1236130619, blue: 0.07450980693, alpha: 1)
        }
    }
    
}
