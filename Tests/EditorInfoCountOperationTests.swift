//
//  EditorInfoCountOperationTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-01-25.
//
//  ---------------------------------------------------------------------------
//
//  © 2020-2022 1024jp
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

import XCTest
@testable import CotEditor

final class EditorInfoCountOperationTests: XCTestCase {
    
    private let testString = """
        dog is 🐕.
        cow is 🐄.
        Both are 👍🏼.
        """
    
    func testNoRequiredInfo() throws {
        
        let selectedRange = Range(NSRange(0..<3), in: self.testString)!
        let counter = EditorInfoCounter(
            string: self.testString,
            selectedRange: selectedRange,
            requiredInfo: [],
            countsWholeText: true)
        
        let result = try counter.count()
        
        XCTAssertNil(result.count)
        XCTAssertNil(result.selectedCount)
        XCTAssertNil(result.location)
        XCTAssertNil(result.line)
        XCTAssertNil(result.column)
    }
    
    
    func testAllRequiredInfo() throws {
        
        let selectedRange = Range(NSRange(11..<21), in: self.testString)!
        let counter = EditorInfoCounter(
            string: self.testString,
            selectedRange: selectedRange,
            requiredInfo: .all,
            countsWholeText: true)
        
        let result = try counter.count()
        
        XCTAssertEqual(result.count!.characters, 31)
        XCTAssertEqual(result.count!.lines, 3)
        XCTAssertEqual(result.count!.words, 6)
        
        XCTAssertEqual(result.selectedCount!.characters, 9)
        XCTAssertEqual(result.selectedCount!.lines, 1)
        XCTAssertEqual(result.selectedCount!.words, 2)
        
        XCTAssertEqual(result.location, 11)
        XCTAssertEqual(result.column, 1)
        XCTAssertEqual(result.line, 2)
    }
    
    
    func testWholeTextSkip() throws {
        
        let selectedRange = Range(NSRange(11..<21), in: self.testString)!
        let counter = EditorInfoCounter(
            string: self.testString,
            selectedRange: selectedRange,
            requiredInfo: .all,
            countsWholeText: false)
        
        let result = try counter.count()
        
        XCTAssertNil(result.count)
        
        XCTAssertEqual(result.selectedCount!.characters, 9)
        XCTAssertEqual(result.selectedCount!.lines, 1)
        XCTAssertEqual(result.selectedCount!.words, 2)
        
        XCTAssertEqual(result.location, 11)
        XCTAssertEqual(result.column, 1)
        XCTAssertEqual(result.line, 2)
    }
    
    
    func testCRLF() throws {
        
        let string = "a\r\nb"
        let selectedRange = Range(NSRange(1..<4), in: string)!
        let counter = EditorInfoCounter(
            string: string,
            selectedRange: selectedRange,
            requiredInfo: .all,
            countsWholeText: true)
        
        let result = try counter.count()
        
        XCTAssertEqual(result.count!.characters, 3)
        XCTAssertEqual(result.count!.lines, 2)
        XCTAssertEqual(result.count!.words, 2)
        
        XCTAssertEqual(result.selectedCount!.characters, 2)
        XCTAssertEqual(result.selectedCount!.lines, 2)
        XCTAssertEqual(result.selectedCount!.words, 1)
        
        XCTAssertEqual(result.location, 2)
        XCTAssertEqual(result.column, 2)
        XCTAssertEqual(result.line, 1)
    }
    
}
