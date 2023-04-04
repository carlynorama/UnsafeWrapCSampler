//
//  TupleBridge.swift
//  
//
//  Created by Carlyn Maw on 3/31/23.
//
import Foundation
import UWCSamplerC


// ONLY FOR USE WITH HOMOGENEOUS TUPLES!!!

// Swift treats C fixed-size arrays as Tuples. This causes a number of snags. Including C functions not being able to receive them back in.


// This function makes the Tuple passable as a C array back into C.  For See TupleBridge extension for version available to test.
fileprivate func tupleEraser() {
    let tuple:(CInt, CInt, CInt) = (0, 1, 2)
    withUnsafePointer(to: tuple) { (tuplePointer: UnsafePointer<(CInt, CInt, CInt)>) in
        //C:-- void erased_tuple_receiver(const int* values, const size_t n);
        erased_tuple_receiver(UnsafeRawPointer(tuplePointer).assumingMemoryBound(to: CInt.self), 3)
    }
}



// TupleBridge is experimental. It all "works", but mostly for use as reference.

public struct TupleBridge<N:Numeric> {
    let size:Int
    let values:[N]
    

    
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

extension TupleBridge where N == CInt {
    public func erasedForCExample() {
        values.withUnsafeBufferPointer { bufferPointer in
            //Function that takes a type N.self in this example. a CInt
            //C:-- void erased_tuple_receiver(const int* values, const size_t n);
            erased_tuple_receiver(bufferPointer.baseAddress, bufferPointer.count)
            
        }
    }
}



//DISTRACTION: Get some insights into passing a Generic into a Generic

//Works, here outside of TupleBridge, but have to specify type on TupleBridge?
//Has nothing to do with type of return. That is the parameter.
//func genericToGenericTest() {
//    let array:[UInt32] = TupleBridge<UInt16>.fetchFixedSizeCArray(source:random_provider_RGBA_array, boundToType:UInt32.self)
//    let tmp = TupleBridge(array: array)
//}

//This one does not need to specify.
//func genericToGenericTest2() {
//    let array = MiscHandy().fetchFixedSizeCArray(source:random_provider_RGBA_array, boundToType:UInt32.self)
//    let tmp = TupleBridge(array: array)
//}

extension TupleBridge {
    
    //This static function will keep you from getting the tuple as a tuple.
    /// usage:
    ///    `public func fetchBaseBufferRGBA() -> [UInt32] {
    ///    `    fetchFixedSizeCArray(source: random_provider_RGBA_array, boundToType: UInt32.self)
    ///    `}
//    static func fetchFixedSizeCArray<T, R>(source:T, boundToType:R.Type) -> [R] {
//        withUnsafeBytes(of: source) { (rawPointer) -> [R] in
//            let bufferPointer = rawPointer.assumingMemoryBound(to: boundToType)
//            return [R](bufferPointer)
//        }
//    }
    
    //Cannot convert value of type '[UInt32]' to expected argument type '[N]'
//    static func TupleBridgeMaker() -> TupleBridge {
//        let array  = Self.fetchFixedSizeCArray(source: random_provider_RGBA_array, boundToType: UInt32.self)
//        let tmp = Self.init(array: array)
//        return tmp
//    }
    //
//    public init<T, N>(source:T, boundToType type:N.Type){
//        self.init(array: Self.fetchFixedSizeCArray(source: source, boundToType: N.self))
//    }
//
//    public init<T, N>(src:T, boundToType type:N.Type){
//        self.init(array: MiscHandy().fetchFixedSizeCArray(source: src, boundToType: type))
//    }
//
//    public init<T, N>(source:T, bindTo type:N.Type){
//        let tmp = MiscHandy().fetchFixedSizeCArray(source: source, boundToType: type)
//        self.init(array: tmp)
//    }
    
    //Cannot convert value of type '(UnsafeRawBufferPointer) -> [N]' to expected argument type '(UnsafeRawBufferPointer) throws -> [N]'
//    public init<T, N>(source:T, boundToType:N.Type) {
//        self.values = withUnsafeBytes(of: source) { (rawPointer) -> [N] in
//            let bufferPointer = rawPointer.assumingMemoryBound(to: boundToType)
//            return [N](bufferPointer)
//        }
//        self.size = values.count
//    }
}


