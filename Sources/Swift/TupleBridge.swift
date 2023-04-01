//
//  File.swift
//  
//
//  Created by Carlyn Maw on 3/31/23.
//

import Foundation
import UWCSamplerC


//ONLY FO USE WITH HOMOGENEOUS TUPLES!!!

//This Code is experimental and has not been tested.


public struct TupleBridgeArrayBased<N:Numeric> {
    let size:Int
    let values:[N]
    
    public init(array:[N]) {
        if N.self != CInt.self {
            
            fatalError("Example code requires CInt")
            
        }
        self.values = array
        self.size = values.count
    }
    
    public init<U>(tuple: U, count:Int, type:N.Type) {
        if N.self != CInt.self {
            
            fatalError("Example code requires CInt")
            
        }
        precondition(MemoryLayout.size(ofValue: tuple) == MemoryLayout<N>.stride * count)
        var tmp:[N] = []
        withUnsafePointer(to: tuple) { tuplePtr in
            tuplePtr.withMemoryRebound(to: N.self, capacity: count) { reboundTuplePtr in
                let bufferPointer = UnsafeBufferPointer<N>(start:reboundTuplePtr, count: count)
                tmp.append(contentsOf: bufferPointer)
                //                for i in stride(from: bufferPointer.startIndex, to: bufferPointer.endIndex, by: 1) {
                //                    tmp.append(bufferPointer[i])
                //                }
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
            tuplePointer.withMemoryRebound(to: N.self, capacity: size) { reboundPointer in
                let bufferPointer = UnsafeMutableBufferPointer(start: UnsafeMutablePointer(reboundPointer), count: count)
                //precondition(count * MemoryLayout<N>.stride == rawBytes.count)
                //precondition(Int(bitPattern: rawBytes.baseAddress).isMultiple(of: MemoryLayout<N>.alignment))
                for i in stride(from: bufferPointer.startIndex, to: bufferPointer.endIndex, by: 1) {
                    bufferPointer[i] = values[i]
                }
//              for (index, value) in values.enumerated() {
//                  bufferPointer[index] = value
//              }
            }
            
        }
    }
    
    public func memCopyToTuple<U>(tuple: inout U, count:Int, type:N.Type) {
        precondition(count == self.size)
        precondition(type == N.self)
        precondition(MemoryLayout.size(ofValue: tuple) == MemoryLayout<N>.stride * count)
        
        values.withUnsafeBufferPointer { bufferPointer in
            //Function that takes a type N.self in this example. a CInt
            //C:-- void erased_tuple_receiver(const int* values, const size_t n);
            memcpy(<#T##__dst: UnsafeMutableRawPointer!##UnsafeMutableRawPointer!#>, <#T##__src: UnsafeRawPointer!##UnsafeRawPointer!#>, <#T##__n: Int##Int#>)
            
        }
        memcpy(tuple, , <#T##__n: Int##Int#>)
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
    
//    //Saw this code but its TERRIBLE how do you know tuple is the right size??
//    func bindArrayToTuple<T, U>(array: Array<T>, tuple: inout U) {
//        //precondition(array.count == Mirror(reflecting: tuple).children.count)
//        withUnsafeMutablePointer(to: &tuple) {
//            $0.withMemoryRebound(to: T.self, capacity: array.count) {
//                let ptr = UnsafeMutableBufferPointer<T>(start: $0, count: array.count)
//                for (index, value) in array.enumerated() {
//                    ptr[index] = value
//                }
//            }
//        }
//    }
    


