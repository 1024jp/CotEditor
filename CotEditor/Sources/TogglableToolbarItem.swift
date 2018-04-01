//
//  ToggleToolbarItem.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-05-26.
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

import Cocoa

final class TogglableToolbarItem: SmallToolbarItem {
    
    // MARK: Public Properties
    
    var state: NSControl.StateValue = .on {
        
        didSet {
            guard let base = self.image?.name()?.rawValue.components(separatedBy: "_").first else {
                assertionFailure("TogglableToolbarItem must habe an image that has name with \"_On\" and \"_Off\" suffixes.")
                return
            }
            
            let suffix = (state == .on) ? "On" : "Off"
            let name = NSImage.Name(base + "_" + suffix)
            if let image = NSImage(named: name) {
                self.image = image
            }
        }
    }
    
}
