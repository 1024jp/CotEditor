//
//  GoToLineView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-07.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2022 1024jp
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

import SwiftUI
import Cocoa

struct GoToLineView: View {
    
    weak var parent: NSHostingController<Self>?  // workaround presentationMode.dismiss() doesn't work
    
    @State private var value: String
    private let completionHandler: (_ lineRange: FuzzyRange) -> Bool
    
    @State private var buttonWidth: CGFloat?
    
    
    
    /// Initialize view with given values.
    ///
    /// - Parameters:
    ///   - lineRange: The current line range.
    ///   - completionHandler: The callback method to perform when the command was accepted.
    init(lineRange: FuzzyRange, completionHandler: @escaping (_ lineRange: FuzzyRange) -> Bool) {
        
        self._value = State(initialValue: lineRange.string)
        self.completionHandler = completionHandler
    }
    
    
    var body: some View {
        
        VStack {
            Form {
                TextField("Line:", text: $value, prompt: Text("Line Number"))
                    .font(.body.monospacedDigit())
            }
            
            HStack(alignment: .firstTextBaseline) {
                HelpButton(anchor: "howto_jump")
                
                Spacer()
                
                Button {
                    self.parent?.dismiss(nil)
                } label: {
                    Text("Cancel")
                        .background(WidthGetter(key: WidthKey.self))
                        .frame(width: self.buttonWidth)
                }.keyboardShortcut(.cancelAction)
                
                Button {
                    guard
                        let lineRange = FuzzyRange(string: self.value),
                        self.completionHandler(lineRange)
                    else { return NSSound.beep() }
                    
                    self.parent?.dismiss(nil)
                } label: {
                    Text("Go")
                        .background(WidthGetter(key: WidthKey.self))
                        .frame(width: self.buttonWidth)
                }.keyboardShortcut(.defaultAction)
            }.onPreferenceChange(WidthKey.self) { self.buttonWidth = $0 }
        }
        .fixedSize()
        .padding()
    }
    
}



// MARK: - Preview

struct GoToLineView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        GoToLineView(lineRange: FuzzyRange(location: 1, length: 1)) { _ in true }
    }
    
}
