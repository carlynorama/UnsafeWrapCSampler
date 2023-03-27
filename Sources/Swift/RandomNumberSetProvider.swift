//
//  File.swift
//  
//
//  Created by Labtanza on 3/25/23.
//

import Foundation
import UWCSamplerC
//https://docs.swift.org/swift-book/documentation/the-swift-programming-language/generics/


@available(macOS 12, *)
public struct RandomNumberSetProvider {
    public init(seed:CUnsignedLong? = nil) {
        //make a call to srand?
        if seed != nil {
            //Why doesn't CUnsignedLong work here?
            seed_random(UInt32(seed.unsafelyUnwrapped))
        } else {
            //seed_random(UInt32(Date.now.timeIntervalSince1970))
            seed_random(UInt32(Double.random(in: 0...1)*Double(UInt32.max)))
        }
    }
    
    public func getRandomInt() -> Int {
        //int* p = malloc(capacity * sizeof(int));
        let ptr = UnsafeMutablePointer<CInt>.allocate(capacity: 1)
        
        //if setting the value in Swift
        //*ptr = 42;
        //ptr.initialize(to: 42)
        
        random_int_pointer(ptr);
        // ptr.pointee == *ptr
        let tmp = Int(ptr.pointee);
        
        //free(p);
        ptr.deallocate()
        return tmp
    }
    
    public func makeArrayOfRandomInt(count:Int) -> [Int] {

        let start = UnsafeMutablePointer<CInt>.allocate(capacity: count)

        random_array_of_zero_to_one_hundred(start, count)
        
        //Make a buffer pointer for easy casting.
        let outPut = UnsafeBufferPointer<CInt>(
            start: start,
            count: count)

        let tmp = [CInt](outPut)

        start.deinitialize(count: count)
        start.deallocate()
        
        return tmp.map { Int($0) }
    }
    
    
    public func randomValueInRange(min base:UInt, max:UInt, count:Int) -> [Int] {
        let upTo = max - base
        let start = UnsafeMutablePointer<CInt>.allocate(capacity: count)
        start.initialize(repeating: CInt(base), count: count)
//        for index in 0..<count {
//            (start + index).initialize(to: base)
//        }
        
        let outPut = UnsafeBufferPointer<CInt>(
            start: start,
            count: count)

        add_random_value_up_to(start, count, CInt(upTo))
        
        //NOTE: This also works.
//        guard let base_ptr = UnsafeMutablePointer(mutating: outPut.baseAddress)  else {
//            fatalError("randomValueInRange: no mutable base pointer available")
//        }
//        add_random_value_up_to(base_ptr, count, CInt(upTo))
        

        let tmp = [CInt](outPut)

        start.deinitialize(count: count)
        start.deallocate()
        //DO NOT outPut.deallocate() AND start.deallocate()
        //appears to be a double free().
        
        return tmp.map { Int($0) }
        
    }
    
    //MUCH Cleaner
    public func addRandomTo(_ baseArray:[CInt], upTo:CInt) -> [CInt] {
        var arrayCopy = baseArray
        arrayCopy.withUnsafeMutableBufferPointer { bufferPointer in
            //bufferPointer.count == arrayCopy.count
            add_random_value_up_to(bufferPointer.baseAddress, bufferPointer.count, CInt(upTo))
        }
        return arrayCopy
    }
    
    
//    public func testBufferProcess() {
//        call_buffer_process_test()
//    }
    
    
    //tricky thing, if wanted to pass this directly to c func as a const void*  STILL must be a var, which causes problems
    let base_buffer:[UInt8] = [ 0x33, 0x33, 0x33, 0x66, 0x66, 0x66, 0x99, 0x99, 0x99,
        0xCC, 0xCC, 0xCC, 0xEE, 0xEE, 0xEE, 0xEE, 0x00, 0x00,
        0x00, 0xEE, 0x00, 0x00, 0xEE, 0x00, 0x11, 0x11, 0x11 ]
    

    public func processBuffer(baseBuffer:[UInt8]? = nil) -> [UInt8] {
        var m_base_buffer = baseBuffer ?? base_buffer
        var settings:[CInt] = [300, 2883, 499832, 6]
        var width = 3
        var height = 3
        let bytes_per_pixel = 3
        
        var outputBuffer:[UInt8] = Array(repeating: 0, count: width * height * bytes_per_pixel)
        //Note: Reserving capacity is not good enough. Must be written to.
        //outputBuffer.reserveCapacity(width * height * bytes_per_pixel)
        
        let size_result = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        size_result.initialize(to: 0)
        
       // buffer_process(T##settings: UnsafeMutablePointer<Int32>!##UnsafeMutablePointer<Int32>!, T##settings_count: u_int##u_int, T##width_ptr: UnsafePointer<Int>!##UnsafePointer<Int>!, T##height_ptr: UnsafePointer<Int>!##UnsafePointer<Int>!, T##bytes_per_pixel: Int##Int, T##calculated_size_ptr: UnsafeMutablePointer<Int>!##UnsafeMutablePointer<Int>!, T##input_buffer: UnsafeRawPointer!##UnsafeRawPointer!, T##output_buffer: UnsafeMutableRawPointer!##UnsafeMutableRawPointer!)
    

        buffer_process(&settings, CUnsignedInt(settings.count), &width, &height, bytes_per_pixel, size_result, &m_base_buffer, &outputBuffer)
        
        print(size_result.pointee)
        print(outputBuffer)
        
        cPrintUInt8Array(outputBuffer)
        
        //fetchCArray()
        
        return outputBuffer
    }
    
    func cPrintUInt8Array(_ array:[UInt8]) {
        print("opaque:")
        var for_pointer = array
        print_opaque(&for_pointer, array.count)
    }
    
//    public func fetchCArray<T>(expectedType:T.Type) -> [T] {
//        let c_array_pointer = random_sampler_global_array.self;
//        print("Pointer:", c_array_pointer, c_array_pointer.self)
//    }
    
//    public func fetchCArray() {
//        let bufferPointer = UnsafeRawBufferPointer(random_sampler_global_array)
//    }
    
    
}
