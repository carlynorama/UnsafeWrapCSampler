//
//  UnsafeBufferView.swift
//  
//
//  Created by Carlyn Maw on 3/29/23.
//  Code from 25:52 of WWDC 2020 "Safely Manage Pointers in Swift."

// In the subscript, using .load(fromByteOffset:as) prevents rebinding of memory for access. This struct can point to memory bound as a different type without overriding.

import Foundation

struct UnsafeBufferView<Element>: RandomAccessCollection {
    
    let rawBytes: UnsafeRawBufferPointer
    let count: Int
    
    init(reinterpret rawBytes:UnsafeRawBufferPointer, as: Element.Type) {
        self.rawBytes = rawBytes
        self.count = rawBytes.count / MemoryLayout<Element>.stride
        precondition(self.count * MemoryLayout<Element>.stride == rawBytes.count)
        precondition(Int(bitPattern: rawBytes.baseAddress).isMultiple(of: MemoryLayout<Element>.alignment))
    }
    
    public var startIndex: Int { 0 }
    public var endIndex: Int { count }
    
    subscript(position: Int) -> Element {
        rawBytes.load(fromByteOffset: position * MemoryLayout<Element>.stride, as: Element.self)
    }
    
}

