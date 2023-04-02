//
//  MiscHandy.swift
//  
//
//  Created by Carlyn Maw on 3/31/23.
//  Most code from WWDC 2020 "Safely Manage Pointers in Swift."
//
import Foundation
import UWCSamplerC


public struct MiscHandy {
    public init() {}
    
    //MARK: Retrieving Fixed Size Arrays of Known Types
    
    public func fetchBaseBuffer() -> [UInt8] {
        //"let array = random_provider_uint8_array" Returns tuple size of fixed size array.
        fetchFixedSizeCArray(source: random_provider_uint8_array, boundToType: UInt8.self)
    }

    public func fetchBaseBufferRGBA() -> [UInt32] {
        fetchFixedSizeCArray(source: random_provider_RGBA_array, boundToType: UInt32.self)
    }

    //Okay to use assumingMemoryBound here IF using type ACTUALLY bound to.
    //Else see UnsafeBufferView struct example using .loadBytes to recast read values without
    //changing underlying memory.
    func fetchFixedSizeCArray<T, R>(source:T, boundToType:R.Type) -> [R] {
        withUnsafeBytes(of: source) { (rawPointer) -> [R] in
            let bufferPointer = rawPointer.assumingMemoryBound(to: boundToType)
            return [R](bufferPointer)
        }
    }

    //TODO: Test non-numerics
    func loadFixedSizeCArray<T, R>(source:T, ofType:R.Type) -> [R]? {
        withUnsafeBytes(of: source) { (rawPointer) -> [R]? in
            rawPointer.baseAddress?.load(as: [R].self)
//            let bufferPointer = rawPointer.assumingMemoryBound(to: boundToType)
//            return [R](bufferPointer)
        }
    }
    
    //TODO: Actual example.
    //Make a rawBuffer to hand of to C that lasts just for the duration of the function.
    func rawBufferWork<T>(count:Int, initializer:T) {
        let rawPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<T>.stride * count, alignment: MemoryLayout<T>.alignment)
        let tPtr = rawPointer.initializeMemory(as: T.self, repeating: initializer, count: count)
        //Do something that needs a pointer bound to T
        tPtr.deinitialize(count: count)
        rawPointer.deallocate()
    }
    
    //Make a rawBuffer to hand of to C that lasts just for the duration of the function.
    public func exampleAssembler<Header, DataType:Numeric>(header:Header, data:[DataType]) {
        let offset = MemoryLayout<Header>.stride
        
        let byteCount = offset + MemoryLayout<DataType>.stride * data.count
        print("offset:\(offset), dataCount:\(data.count), dataTypeStride:\(MemoryLayout<DataType>.stride),  byteCount:\(byteCount)")
        assert(MemoryLayout<Header>.alignment >= MemoryLayout<DataType>.alignment)
        
        let rawPointer = UnsafeMutableRawPointer.allocate(
            byteCount: byteCount, alignment: MemoryLayout<Header>.alignment)
        let headerPointer = rawPointer.initializeMemory(as: Header.self, repeating: header, count: 1)
        //TODO: how to init with contents of data
        
        let elementPointer = (rawPointer + offset).initializeMemory(as: DataType.self, repeating: 0, count: data.count)
        
        data.withUnsafeBufferPointer { sourcePointer in
            elementPointer.assign(from: sourcePointer.baseAddress!, count: sourcePointer.count)
        }
        print("raw:\(rawPointer)")
        print("header:\(headerPointer)")
        print("element:\(elementPointer)")
        
        
        //---------------  DO Something
//        let bufferPointer = UnsafeRawBufferPointer(start: rawPointer, count: byteCount)
//
//        print(bufferPointer)
        
        // cant just return Data(bytes: rawPointer, count: byteCount) because must deallocate before leaving.
        let tmp = Data(bytes: rawPointer, count: byteCount)
        
        for dataByte in tmp {
            print(dataByte, terminator: ", ")
        }
        print()
        
        //--------------- END DO Something
        
        elementPointer.deinitialize(count: data.count)
        headerPointer.deinitialize(count: 1)
        rawPointer.deallocate()
        

        //--------------- IF NEEDED: return tmp
    }
    
    

    
    //ONLY works for tuples that are homogeneous
    //See also TupleBridge
    public func tupleEraser() {
        let tuple:(CInt, CInt, CInt) = (0, 1, 2)
        withUnsafePointer(to: tuple) { (tuplePointer: UnsafePointer<(CInt, CInt, CInt)>) in
            //C:-- void erased_tuple_receiver(const int* values, const size_t n);
            erased_tuple_receiver(UnsafeRawPointer(tuplePointer).assumingMemoryBound(to: CInt.self), 3)
        }
    }
    

    
    public func loadAsUInt8GetAsUInt32() {
        
        let uint8Pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
        uint8Pointer.initialize(repeating: 127, count: 16)
        let uint32Pointer = UnsafeMutableRawPointer(uint8Pointer).bindMemory(to: UInt32.self, capacity: 4)
        //DO NOT TOUCH uint8Pointer ever again. Not for use if thing would exist outside of function
        // pass to something that needs 32
        uint32Pointer.deallocate()
    }
    //also withMemoryRebound, .load better choices

    
    //MARK: Load From Data
    
    //Requires aligned data.
    //aligned data is data where [0] is at a pointer that is at the 0 of a register/granularity section.
    //https://developer.ibm.com/articles/pa-dalign/
    
    //Note checks one could add:
    //precondition(data.count == MemoryLayout<N>.stride)
    //precondition(offset % MemoryLayout<T>.stride == 0)
    
    public func processData<T>(data:Data, as type:T.Type) -> T {
        let result = data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) -> T in
            return buffer.load(as: type)
        }
        print(result)
        return result
    }
    
    //
    //offset needs to be  offset % MemoryLayout<T>.stride == 0
    public func processData2<T>(data:Data, as type:T.Type, offsetBy offset:Int = 0) -> T {
        //precondition(offset % MemoryLayout<T>.stride == 0)
        let result = data.withUnsafeBytes { buffer -> T in
            return buffer.load(fromByteOffset: offset, as: T.self)
        }
        print(result)
        return result
    }
    
    public func processUnalignedData<T>(data:Data, as type:T.Type, offsetBy offset:Int = 0) -> T {
        let result = data.withUnsafeBytes { buffer -> T in
            return buffer.loadUnaligned(fromByteOffset: offset, as: T.self)
        }
        print(result)
        return result
    }
    
    public func processDataIntoArray<T>(data:Data, as type:T.Type, count:Int) -> [T] {
        precondition(data.count == MemoryLayout<T>.stride * count)
        let result = data.withUnsafeBytes { buffer -> [T] in
            var values:[T] = []
            for i in (0..<count) {
                values.append(buffer.load(fromByteOffset: MemoryLayout<T>.stride * i, as: T.self))
            }
            return values
        }
        return result
    }
    
    public func processUnalignedDataIntoArray<T>(data:Data, as type:T.Type, byOffset offset:Int, count:Int) -> [T] {
        precondition((data.count - offset) > (MemoryLayout<T>.stride * count))
        let result = data.withUnsafeBytes { buffer -> [T] in
            var values:[T] = []
            for i in (0..<count) {
                values.append(buffer.loadUnaligned(fromByteOffset: offset + (MemoryLayout<T>.stride * i), as: T.self))
            }
            return values
        }
        return result
    }
    
//  Shove 'em in.
//    public func readNumericFrom<N:Numeric>(correctCountData data:Data, as numericType:N.Type) -> N {
//        //Non numerics should really use stride.
//        precondition(data.count == MemoryLayout<N>.size) //Could determine type switch on data count with error.
//        var newValue:N = 0
//        let copiedCount = withUnsafeMutableBytes(of: &newValue, { data.copyBytes(to: $0)} )
//        precondition(copiedCount == MemoryLayout.size(ofValue: newValue))
//        return newValue
//    }
    
    //Safer than calculatedPointerToStructItem
    public func conveniencePointerToStructItem() {
        let example = ExampleStruct()
        withUnsafePointer(to: example.myString) { ptr_to_string in
            print(ptr_to_string)
        }
    }
    
    //Less safe. Only possible for single value types?
    public func calculatedPointerToStructItem() {
        let example = ExampleStruct()
        
        withUnsafePointer(to: example) { (ptr: UnsafePointer<ExampleStruct>) in
            let rawPointer = (UnsafeRawPointer(ptr) + MemoryLayout<ExampleStruct>.offset(of: \.myNumber)!)
            erased_struct_member_receiver(rawPointer.assumingMemoryBound(to: CInt.self))
        }
    }
    
}

fileprivate struct ExampleStruct {
    let myNumber:CInt = 42
    let myString:String = "Hello"
}
