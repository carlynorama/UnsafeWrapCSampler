//
//  MiscHandy.swift
//  
//
//  Created by Carlyn Maw on 3/31/23.
//  Most code from WWDC 2020 "Safely Manage Pointers in Swift."
//
import Foundation
import UWCSamplerC


struct MiscHandy {
    
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

    //TODO: Test
    func loadFixedSizeCArray<T, R>(source:T, ofType:R.Type) -> [R]? {
        withUnsafeBytes(of: source) { (rawPointer) -> [R]? in
            rawPointer.baseAddress?.load(as: [R].self)
//            let bufferPointer = rawPointer.assumingMemoryBound(to: boundToType)
//            return [R](bufferPointer)
        }
    }
    
    //MARK: Misc
    func rawBufferWork<T>(count:Int, initializer:T) {
        let rawPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<T>.stride * count, alignment: MemoryLayout<T>.alignment)
        let tPtr = rawPointer.initializeMemory(as: T.self, repeating: initializer, count: count)
        //Do something that needs a pointer bound to T
        tPtr.deinitialize(count: count)
        rawPointer.deallocate()
    }
    
    func exampleAssembler<Header>(header:Header, data:[Int32]) {
        let offset = MemoryLayout<Header>.stride
        let byteCount = offset + MemoryLayout<Int32>.stride * data.count
        assert(MemoryLayout<Header>.alignment >= MemoryLayout<Int32>.alignment)
        let bufferPointer = UnsafeMutableRawPointer.allocate(
            byteCount: byteCount, alignment: MemoryLayout<Header>.alignment)
        let headerPointer = bufferPointer.initializeMemory(as: Header.self, repeating: header, count: 1)
        //TODO: how to init with contents of data
        let elementPointer = (bufferPointer + offset).initializeMemory(as: Int32.self, repeating: 0, count: data.count)
        
        //DO SOMETHING
        
        elementPointer.deinitialize(count: data.count)
        headerPointer.deinitialize(count: 1)
        bufferPointer.deallocate()
    }
    
    func precessData<T>(data:Data, as type:T.Type) {
        let result = data.withUnsafeBytes { buffer -> T in
            //let rawPointer = UnsafeRawPointer(buffer.baseAddress!)
            //rawPointer.load(fromByteOffset: MemoryLayout<T>.stride, as: type)
            return buffer.load(as: type)
        }
        print(result)
    }
    
    //ONLY works for tuples because homogeneous
    public func tupleEraser() {
        let tuple:(CInt, CInt, CInt) = (0, 1, 2)
        withUnsafePointer(to: tuple) { (tuplePointer: UnsafePointer<(CInt, CInt, CInt)>) in
            //C:-- void erased_tuple_receiver(const int* values, const size_t n);
            erased_tuple_receiver(UnsafeRawPointer(tuplePointer).assumingMemoryBound(to: CInt.self), 3)
        }
    }
    
    //Safer
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
    //    let data = Data([0x71, 0x3d, 0x0a, 0xd7, 0xa3, 0x10, 0x45, 0x40])
    //aligned data is data that NOT a slice. [0] is at a pointer that is at the 0 of a register/granularity section.
    //https://developer.ibm.com/articles/pa-dalign/
    //TODO: Need to check on load to see if it can safely handle slices.
    //TODO: Does Data ever provide a slice?
    public func readNumericFrom<N:Numeric>(alignedData:Data, as numericType:N.Type) -> N {
        //Compound types should use stride?
        precondition(alignedData.count == MemoryLayout<N>.size) //Could determine type switch on data count with error.
        return alignedData.withUnsafeBytes {
            $0.load(as: N.self)
        }
    }
    
    public func readNumericFrom<N:Numeric>(correctCountData data:Data, as numericType:N.Type) -> N {
        //Compound types should use stride?
        precondition(data.count == MemoryLayout<N>.size) //Could determine type switch on data count with error.
        var newValue:N = 0
        let copiedCount = withUnsafeMutableBytes(of: &newValue, { data.copyBytes(to: $0)} )
        precondition(copiedCount == MemoryLayout.size(ofValue: newValue))
        return newValue
    }
    
    //What happens if data is longer? This is what the video shows. Is it this easy?
    public func readNumeric<N:Numeric>(from data:Data, at offset:Int = 0, as:N.Type) -> N {
        data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
            //buffer.load(as: T.Type)
            buffer.load(fromByteOffset: offset, as: N.self)
        }
    }
    

    public func readNumeric<N:Numeric>(from data:Data, at offset:Int = 0, asArrayOf:N.Type) -> [N] {
        data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
            //buffer.load(as: T.Type)
            buffer.load(fromByteOffset: offset, as: [N].self)
        }
    }
    
    
    
}

fileprivate struct ExampleStruct {
    let myNumber:CInt = 42
    let myString:String = "Hello"
}
