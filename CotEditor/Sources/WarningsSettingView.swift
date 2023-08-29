//
//  WarningsSettingView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-08-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2023 1024jp
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

struct WarningsSettingView: View {
    
    weak var parent: NSHostingController<Self>?
    
    
    @AppStorage(.suppressesInconsistentLineEndingAlert) private var suppressesInconsistentLineEndingAlert: Bool
    
    
    var body: some View {
        
        VStack {
            Form {
                Text("Suppress following warnings:")
                Toggle("Inconsistent line endings", isOn: $suppressesInconsistentLineEndingAlert)
            }
            
            HStack {
                HelpButton(anchor: "howto_manage_warnings")
                Spacer()
                Button("OK") {
                    self.parent?.dismiss(nil)
                }.keyboardShortcut(.defaultAction)
            }.padding(.top)
        }
        .fixedSize()
        .scenePadding()
    }
}



// MARK: - Preview

#Preview {
    WarningsSettingView()
}
