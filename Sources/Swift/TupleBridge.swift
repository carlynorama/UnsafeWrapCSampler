//
//  File.swift
//  
//
//  Created by Carlyn Maw on 3/31/23.
//

// Swift treats C fixed-size arrays as Tuples.
// Here is a way to store the tuple as an Array and, if needed
// turn it back again.

// ONLY FOR USE WITH HOMOGENEOUS TUPLES!!!

// This Code is experimental. It all "works", but mostly for use as reference.


import Foundation
import UWCSamplerC


public struct TupleBridgeArrayBased<N:Numeric> {
    let size:Int
    let values:[N]
    
    /// usage:
    ///    `public func fetchBaseBufferRGBA() -> [UInt32] {
    ///    `    fetchFixedSizeCArray(source: random_provider_RGBA_array, boundToType: UInt32.self)
    ///    `}
    static func fetchFixedSizeCArray<T, R>(source:T, boundToType:R.Type) -> [R] {
        withUnsafeBytes(of: source) { (rawPointer) -> [R] in
            let bufferPointer = rawPointer.assumingMemoryBound(to: boundToType)
            return [R](bufferPointer)
        }
    }
    
    public init(array:[N]) {
        self.values = array
        self.size = values.count
    }
    
    public init<U>(tuple: U, count:Int, type:N.Type) {
        precondition(MemoryLayout.size(ofValue: tuple) == MemoryLayout<N>.stride * count)
        var tmp:[N] = []
        withUnsafePointer(to: tuple) { tuplePtr in
            tuplePtr.withMemoryRebound(to: N.self, capacity: count) { reboundTuplePtr in
                let bufferPointer = UnsafeBufferPointer<N>(start:reboundTuplePtr, count: count)
                tmp.append(contentsOf: bufferPointer)
            }
        }
        
        self.init(array: tmp)
    }
    
    public func printMe() {
        print(size)
        print(values)
    }
    
    public func loadIntoTupleFromArray<U>(tuple: inout U, count:Int, type:N.Type) {
        precondition(count == self.size)
        precondition(type == N.self)
        precondition(MemoryLayout.size(ofValue: tuple) == MemoryLayout<N>.stride * count)
        
        withUnsafeMutablePointer(to: &tuple) { tuplePointer in
            precondition(Int(bitPattern: tuplePointer).isMultiple(of: MemoryLayout<N>.alignment))
            tuplePointer.withMemoryRebound(to: N.self, capacity: size) { reboundPointer in
                let bufferPointer = UnsafeMutableBufferPointer(start: UnsafeMutablePointer(reboundPointer), count: count)
                //precondition(count * MemoryLayout<N>.stride == rawBytes.count)
                
                for i in stride(from: bufferPointer.startIndex, to: bufferPointer.endIndex, by: 1) {
                    bufferPointer[i] = values[i]
                }
                //              for (index, value) in values.enumerated() {
                //                  bufferPointer[index] = value
                //              }
            }
            
        }
    }
    
    //YOLO.
    public func memCopyToTuple<U>(tuple: inout U, count:Int, type:N.Type) {
        precondition(count == self.size)
        precondition(type == N.self)
        precondition(MemoryLayout.size(ofValue: tuple) == MemoryLayout<N>.stride * count)
        precondition(MemoryLayout.size(ofValue: tuple) == MemoryLayout<N>.stride * size)
        //precondition(MemoryLayout.size(ofValue: tuple) == MemoryLayout.size(ofValue: values)) <-- This fails. Hmmmm...
        withUnsafeMutablePointer(to: &tuple) { tuplePointer in
            precondition(Int(bitPattern: tuplePointer).isMultiple(of: MemoryLayout<N>.alignment))
            let _ = values.withUnsafeBufferPointer { bufferPointer in
                memcpy(tuplePointer, bufferPointer.baseAddress, count * MemoryLayout<N>.stride)
            }
            
        }
    }
}

extension TupleBridgeArrayBased where N == CInt {
    public func erasedForCExample() {
        values.withUnsafeBufferPointer { bufferPointer in
            //Function that takes a type N.self in this example. a CInt
            //C:-- void erased_tuple_receiver(const int* values, const size_t n);
            erased_tuple_receiver(bufferPointer.baseAddress, bufferPointer.count)
            
        }
    }
}


