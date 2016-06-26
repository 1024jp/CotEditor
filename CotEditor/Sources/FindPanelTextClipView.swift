/*
 
 FindPanelTextClipView.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2015-03-05.
 
 ------------------------------------------------------------------------------
 
 © 2015-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

class FindPanelTextClipView: NSClipView {
    
    // MARK: Private Properties
    
    private let leftPadding: CGFloat = 28.0
    
    
    
    // MARK: View Methods
    
    /// add left padding for popup button
    override var frame: NSRect {
        didSet {
            guard frame.minX < self.leftPadding else { return }  // avoid infinity loop
            
            frame.origin.x += self.leftPadding
            frame.size.width -= self.leftPadding
        }
    }
    
}
