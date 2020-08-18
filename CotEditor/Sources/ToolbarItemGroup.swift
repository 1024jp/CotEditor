//
//  ToolbarItemGroup.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-08-10.
//
//  ---------------------------------------------------------------------------
//
//  © 2020 1024jp
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

import AppKit

final class ToolbarItemGroup: NSToolbarItemGroup, Validatable {
    
    override func validate() {
        
        super.validate()
        
        // validate subitem selection
        self.isEnabled = self.validate()
    }
    
}


extension NSToolbarItemGroup {
    
    func useSubitemsForMenuFormRepresentation() {
        
        assert(!self.subitems.isEmpty)
        
        let menu = NSMenuItem(title: self.label, action: nil, keyEquivalent: "")
        menu.submenu = NSMenu(title: self.label)
        menu.submenu?.items = self.subitems
            .map { NSMenuItem(title: $0.label, action: $0.action, keyEquivalent: "") }
        
        self.menuFormRepresentation = menu
    }
    
}
