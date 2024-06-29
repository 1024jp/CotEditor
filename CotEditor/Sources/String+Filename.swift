//
//  String+Filename.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-06-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2024 1024jp
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

extension String {
    
    /// The remainder of string after last dot removed.
    var deletingPathExtension: String {
        
        self.replacing(/^(.+)\.[^ .]+$/, with: \.1)
    }
}


extension Collection<String> {
    
    /// Creates a unique name from the receiver's elements by adding the suffix and also a number if needed.
    ///
    /// - Parameters:
    ///   - proposedName: The name candidate.
    ///   - suffix: The name suffix to be appended before the number.
    /// - Returns: An unique name.
    func createAvailableName(for proposedName: String, suffix: String? = nil) -> String {
        
        let spaceSuffix = suffix.flatMap { " " + $0 } ?? ""
        
        let (rootName, baseCount): (String, Int?) = {
            let suffixPattern = NSRegularExpression.escapedPattern(for: spaceSuffix)
            let regex = try! NSRegularExpression(pattern: suffixPattern + "(?: ([0-9]+))?$")
            
            guard let result = regex.firstMatch(in: proposedName, range: proposedName.nsRange) else { return (proposedName, nil) }
            
            let root = (proposedName as NSString).substring(to: result.range.location)
            let numberRange = result.range(at: 1)
            
            guard !numberRange.isNotFound else { return (root, nil) }
            
            let number = Int((proposedName as NSString).substring(with: numberRange))
            
            return (root, number)
        }()
        
        let baseName = rootName + spaceSuffix
        
        guard baseCount != nil || self.contains(baseName) else { return baseName }
        
        return ((baseCount ?? 2)...).lazy
            .map { baseName + " " + String($0) }
            .first { !self.contains($0) }!
    }
}
