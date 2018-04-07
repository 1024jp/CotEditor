//
//  SyntaxTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-11.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2018 1024jp
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
import YAML
@testable import CotEditor

let styleDirectoryName = "Syntaxes"
let styleExtension = "yaml"


class SyntaxTests: XCTestCase, SyntaxStyleDelegate {
    
    var htmlStyle: SyntaxStyle?
    var htmlSource: String?
    
    var outlineParseExpectation: XCTestExpectation?
    
    
    
    override func setUp() {
        
        super.setUp()
        
        let bundle = Bundle(for: type(of: self))
        
        // load XML style
        let styleURL = bundle.url(forResource: "HTML", withExtension: styleExtension, subdirectory: styleDirectoryName)
        let data = try? Data(contentsOf: styleURL!)
        let dict = try? YAMLSerialization.object(withYAMLData: data, options: kYAMLReadOptionMutableContainersAndLeaves) as? [String: Any]
        self.htmlStyle = SyntaxStyle(dictionary: dict!, name: "HTML")
        
        XCTAssertNotNil(self.htmlStyle)
        
        // load test file
        let sourceURL = bundle.url(forResource: "sample", withExtension: "html")
        self.htmlSource = try? String(contentsOf: sourceURL!, encoding: .utf8)
        
        XCTAssertNotNil(self.htmlSource)
    }
    
    
    func testEquality() {
        
        XCTAssertEqual(self.htmlStyle, self.htmlStyle)
    }
    
    
    func testNoneSytle() {
        
        let style = SyntaxStyle(dictionary: nil, name: "foo")
        
        XCTAssertEqual(style.styleName, "foo")
        XCTAssert(style.isNone)
        XCTAssertFalse(style.canParse)
        XCTAssertNil(style.inlineCommentDelimiter)
        XCTAssertNil(style.blockCommentDelimiters)
    }
    
    
    func testXMLSytle() {
        
        guard let style = self.htmlStyle else { return }
        
        XCTAssertEqual(style.styleName, "HTML")
        XCTAssertFalse(style.isNone)
        XCTAssert(style.canParse)
        XCTAssertNil(style.inlineCommentDelimiter)
        XCTAssertEqual(style.blockCommentDelimiters?.begin, "<!--")
        XCTAssertEqual(style.blockCommentDelimiters?.end, "-->")
    }
    
    
    func testOutlineParse() {
        
        guard let style = self.htmlStyle, let source = self.htmlSource else { return }
        
        // create dummy textView
        let textView = NSTextView()
        textView.string = source
        
        style.textStorage = textView.textStorage
        style.delegate = self
        
        // test outline parsing with delegate
        self.outlineParseExpectation = self.expectation(description: "didParseOutline")
        style.invalidateOutline()
        self.waitForExpectations(timeout: 1)
    }
    
    
    func syntaxStyle(_ syntaxStyle: SyntaxStyle, didParseOutline outlineItems: [OutlineItem]) {
        
        self.outlineParseExpectation?.fulfill()
        
        XCTAssertEqual(outlineItems.count, 3)
        
        XCTAssertEqual(syntaxStyle.outlineItems, outlineItems)
        
        let item = outlineItems[1]
        XCTAssertEqual(item.title, "   h2: 🐕🐄")
        XCTAssertEqual(item.range.location, 354)
        XCTAssertEqual(item.range.length, 13)
        XCTAssertTrue(item.style.isEmpty)
    }
    
}
