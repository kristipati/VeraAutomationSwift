// The MIT License (MIT)
// 
// Copyright (c) 2014 Nate Cook
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

public struct Set<T: Hashable> : Equatable {
    public typealias Element = T
    fileprivate var contents: [Element: Bool]
    
    public init() {
        self.contents = [Element: Bool]()
    }

    public init<S: Sequence>(_ sequence: S) where S.Iterator.Element == Element {
        self.contents = [Element: Bool]()
        _ = sequence.map({self.contents[$0] = true})
    }

    /// The number of elements in the Set.
    public var count: Int { return contents.count }
    
    /// Returns `true` if the Set is empty.
    public var isEmpty: Bool { return contents.isEmpty }
    
    /// The elements of the Set as an array.
    public var elements: [Element] { return Array(self.contents.keys) }

    /// Returns `true` if the Set contains `element`.
    public func contains(_ element: Element) -> Bool {
        return contents[element] ?? false
    }
        
    /// Add `newElements` to the Set.
    public mutating func add(_ newElements: Element...) {
        _ = newElements.map { self.contents[$0] = true }
    }
    
    /// Remove `element` from the Set.
    public mutating func remove(_ element: Element) -> Element? {
        return contents.removeValue(forKey: element) != nil ? element : nil
    }
    
    /// Removes all elements from the Set.
    public mutating func removeAll() {
    	contents = [Element: Bool]()
    }

    /// Returns a new Set including only those elements `x` where `includeElement(x)` is true.
    public func filter(_ includeElement: (T) -> Bool) -> Set<T> {
        return Set(self.contents.keys.filter(includeElement))
    }

    /// Returns a new Set where each element `x` is transformed by `transform(x)`.
    public func map<U>(_ transform: (T) -> U) -> Set<U> {
        return Set<U>(self.contents.keys.map(transform))
    }

    /// Returns a single value by iteratively combining each element of the Set.
    public func reduce<U>( _ initial: U, combine: (U, T) -> U) -> U {
        return self.reduce(initial, combine: combine)
    }
}

// MARK: SequenceType

extension Set : Sequence {
    public typealias Iterator = LazyMapIterator<DictionaryGenerator<T, Bool>, T>
    
    /// Creates a generator for the items of the set.
    public func makeIterator() -> Iterator {
        return contents.keys.makeIterator()
    }
}

// MARK: ArrayLiteralConvertible

extension Set : ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        self.contents = [Element: Bool]()
        _ = elements.map { self.contents[$0] = true }
    }

    public static func convertFromArrayLiteral(_ elements: T...) -> Set<T> {
        return Set(elements)
    }
}

// MARK: Set Operations

extension Set {
    /// Returns `true` if the Set has the exact same members as `set`.
    public func isEqualToSet(_ set: Set<T>) -> Bool {
        return self.contents == set.contents
    }
    
    /// Returns `true` if the Set shares any members with `set`.
    public func intersectsWithSet(_ set: Set<T>) -> Bool {
        for elem in self {
            if set.contains(elem) {
                return true
            }
        }
        return false
    }

    /// Returns `true` if all members of the Set are part of `set`.
    public func isSubsetOfSet(_ set: Set<T>) -> Bool {
        for elem in self {
            if !set.contains(elem) {
                return false
            }
        }
        return true
    }

    /// Returns `true` if all members of `set` are part of the Set.
    public func isSupersetOfSet(_ set: Set<T>) -> Bool {
        return set.isSubsetOfSet(self)
    }

    /// Modifies the Set to add all members of `set`.
    public mutating func unionSet(_ set: Set<T>) {
        for elem in set {
            self.add(elem)
        }
    }

    /// Modifies the Set to remove any members also in `set`.
    public mutating func subtractSet(_ set: Set<T>) {
        for elem in set {
            self.remove(elem)
        }
    }
    
    /// Modifies the Set to include only members that are also in `set`.
    public mutating func intersectSet(_ set: Set<T>) {
        self = self.filter { set.contains($0) }
    }
    
    /// Returns a new Set that contains all the elements of both this set and the set passed in.
    public func setByUnionWithSet(_ set: Set<T>) -> Set<T> {
        var newSet = set
        newSet.append(self)
        return newSet
    }

    /// Returns a new Set that contains only the elements in both this set and the set passed in.
    public func setByIntersectionWithSet(_ set: Set<T>) -> Set<T> {
        var newSet = set
        newSet.intersectSet(self)
        return newSet
    }

    /// Returns a new Set that contains only the elements in this set *not* also in the set passed in.
    public func setBySubtractingSet(_ set: Set<T>) -> Set<T> {
        var newSet = self
        newSet.subtractSet(set)
        return newSet
    }
}

// MARK: ExtensibleCollectionType

extension Set : RangeReplaceableCollection {
    public typealias Index = Int
    public var startIndex: Int { return 0 }
    public var endIndex: Int { return self.count }

    public subscript(i: Int) -> Element {
        return Array(self.contents.keys)[i]
    }

    /// Adds newElement to the Set.
    public mutating func append(_ newElement: Element) {
        self.add(newElement)
    }
    
    /// Extends the Set by adding all the elements of `seq`.
    public mutating func append<S : Sequence>(contentsOf seq: S) where S.Iterator.Element == Element {
        _ = seq.map( { self.contents[$0] = true })
    }
    
    public mutating func replaceSubrange<C : Collection>(_ subRange: Range<Set.Index>, with newElements: C) where C.Iterator.Element == Iterator.Element {
        
    }
    public mutating func insert(_ newElement: Set.Iterator.Element, at i: Set.Index) {
        
    }
    
    public mutating func insert<C : Collection>(contentsOf newElements: C, at i: Set.Index) where C.Iterator.Element == Iterator.Element {
        
    }
    public mutating func removeSubrange(_ subRange: Range<Set.Index>) {
        
    }
    public mutating func removeFirst(_ n: Int) {
        
    }
    public mutating func removeAll(keepingCapacity keepCapacity: Bool) {
        
    }
    public mutating func reserveCapacity(_ n: Set.Index.Distance) {
        
    }

}

// MARK: Printable

extension Set : CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return "Set(\(self.elements))"
    }

    public var debugDescription: String {
        return description
    }
}

// MARK: Operators

public func +=<T>(lhs: inout Set<T>, rhs: T) {
    lhs.add(rhs)
}

public func +=<T>(lhs: inout Set<T>, rhs: Set<T>) {
    lhs.unionSet(rhs)
}

public func +<T>(lhs: Set<T>, rhs: Set<T>) -> Set<T> {
    return lhs.setByUnionWithSet(rhs)
}

public func ==<T>(lhs: Set<T>, rhs: Set<T>) -> Bool {
    return lhs.isEqualToSet(rhs)
}



