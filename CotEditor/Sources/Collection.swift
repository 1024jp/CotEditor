//
//  Collection.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-27.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2024 1024jp
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

extension RangeReplaceableCollection where Element: Equatable {
    
    /// Removes first collection element that is equal to the given `element`.
    ///
    /// - Parameter element: The element to be removed.
    /// - Returns: The index of the removed element, or `nil` if not contains.
    @discardableResult
    mutating func removeFirst(_ element: Element) -> Index? {
        
        guard let index = self.firstIndex(of: element) else { return nil }
        
        self.remove(at: index)
        
        return index
    }
    
    
    /// Adds a new element to the end of the collection by keeping all the collection's elements unique.
    ///
    /// - Parameters:
    ///   - element: The element to append.
    ///   - maximum: The maximum number of the elements to keep in the collection. The overflowed elements will be removed.
    mutating func appendUnique(_ element: Element, maximum: Int) {
        
        self.removeAll { $0 == element }
        self.append(element)
        
        if self.count > maximum {
            self.removeFirst(self.count - maximum)
        }
    }
}



extension Collection {
    
    /// Returns the element at the specified index only if it is within bounds, otherwise nil.
    ///
    /// - Parameter index: The position of the element to obtain.
    subscript(safe index: Index) -> Element? {
        
        self.indices.contains(index) ? self[index] : nil
    }
}



extension Sequence {
    
    // Asynchronously returns an array containing the results of mapping the given closure over the sequence’s elements.
    func asyncMap<T>(_ transform: @Sendable (Element) async throws -> T) async rethrows -> [T] {
        
        var values = [T]()
        for element in self {
            try await values.append(transform(element))
        }
        
        return values
    }
}



extension Sequence where Element: Equatable {
    
    /// An array consists of unique elements of receiver by keeping ordering.
    var uniqued: [Element] {
        
        self.reduce(into: []) { (unique, element) in
            guard !unique.contains(element) else { return }
            
            unique.append(element)
        }
    }
}



extension Array where Element: Equatable {
    
    /// Removes duplicated elements by keeping ordering.
    mutating func unique() {
        
        self = self.uniqued
    }
}



extension Dictionary {
    
    /// Returns a new dictionary containing the keys transformed by the given closure with the values of this dictionary.
    ///
    /// - Parameter transform: A closure that transforms a key. Every transformed key must be unique.
    /// - Returns: A dictionary containing transformed keys and the values of this dictionary.
    func mapKeys<T>(_ transform: (Key) throws -> T) rethrows -> [T: Value] {
        
        try self.reduce(into: [:]) { $0[try transform($1.key)] = $1.value }
    }
    
    
    /// Returns a new dictionary containing the keys transformed by the given keyPath with the values of this dictionary.
    ///
    /// - Parameter keyPath: The keyPath to the value to transform key. Every transformed key must be unique.
    /// - Returns: A dictionary containing transformed keys and the values of this dictionary.
    func mapKeys<T>(_ keyPath: KeyPath<Key, T>) -> [T: Value] {
        
        self.mapKeys { $0[keyPath: keyPath] }
    }
    
    /// Returns a new dictionary containing the keys transformed by the given closure with the values of this dictionary.
    ///
    /// - Parameter transform: A closure that transforms a key. Every transformed key must be unique.
    /// - Returns: A dictionary containing transformed keys and the values of this dictionary.
    func compactMapKeys<T>(_ transform: (Key) throws -> T?) rethrows -> [T: Value] {
        
        try self.reduce(into: [:]) {
            guard let key = try transform($1.key) else { return }
            $0[key] = $1.value
        }
    }
    
    
    /// Syntax sugar to use RawRepresentable keys in dictionaries whose key is the actual raw value.
    ///
    /// - Parameter key: The raw representable whose raw value is the one of the receiver's key.
    /// - Returns: The value corresponding to the given key.
    subscript<K>(_ key: K) -> Value? where K: RawRepresentable, K.RawValue == Key {
        
        get { self[key.rawValue] }
        set { self[key.rawValue] = newValue }
    }
}



// MARK: - Sort

extension Sequence {
    
    /// Returns the elements of the sequence, sorted using the value that the given key path refers as the comparison between elements.
    ///
    /// - Parameter keyPath: The key path to the value to compare.
    /// - Returns: A sorted array of the sequence’s elements.
    func sorted(_ keyPath: KeyPath<Element, some Comparable>) -> [Element] {
        
        self.sorted { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
    }
}


extension MutableCollection where Self: RandomAccessCollection {
    
    /// Sorts the collection in place, using the value that the given key path refers as the comparison between elements.
    ///
    /// - Parameter keyPath: The key path to the value to compare.
    mutating func sort(_ keyPath: KeyPath<Element, some Comparable>) {
        
        self.sort { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
    }
}



// MARK: - Count

extension Sequence {
    
    /// Counts up elements by enumerating collection until encountering the element that doesn't satisfy the given predicate.
    ///
    /// - Parameters:
    ///    - predicate: A closure that takes an element of the sequence as its argument
    ///                 and returns a Boolean value indicating whether the element should be counted.
    /// - Returns: The number of elements that satisfies the given predicate and are sequentially from the first index.
    func countPrefix(while predicate: (Element) throws -> Bool) rethrows -> Int {
        
        try self.prefix(while: predicate).count
    }
}
