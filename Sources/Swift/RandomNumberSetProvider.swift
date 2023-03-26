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
    
    
    
    
    
}
