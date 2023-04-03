//
//  RandomProvider.swift
//  
//
//  Created by Carlyn Maw on 3/25/23.
//

import Foundation
import UWCSamplerC


//Note: functions that casting to Int on exit could be avoided if the C functions used `size_t` instead of `int` (which is Int32).
//Using int in these example to show use cases.



@available(macOS 12, *)
public struct RandomProvider {
    
    
    public init(seed:CUnsignedLong? = nil) {
        //make a call to srand?
        if seed != nil {
            //Why doesn't CUnsignedLong work here? (b/c it isn't a long, head-smack)
            //C:-- void seed_random(unsigned int seed);
            seed_random(UInt32(seed.unsafelyUnwrapped)) //saves the check. Use only when code really needs speed.
        } else {
            //C:-- void seed_random(unsigned int seed);
            seed_random(UInt32(Double.random(in: 0...1)*Double(UInt32.max)))
        }
    }
    
    //MARK: Single Values
    
    public func getRandomIntExplicitPointer() -> Int {
        //equivalent to: int* p = malloc(capacity * sizeof(int));
        let ptr = UnsafeMutablePointer<CInt>.allocate(capacity: 1)
        
        //Pass to C function
        //C:-- void random_int_with_result_pointer(int* result);
        random_int_with_result_pointer(ptr);
        
        // Set holding variable on the stack
        // ptr.pointee == *ptr
        let tmp = Int(ptr.pointee);
        
        //Release the memory
        //free(p);
        ptr.deallocate()
        
        //return the holding variable.
        return tmp
    }
    
    public func getRandomIntClosure() -> Int {
        var tmp:CInt = 0;
        withUnsafeMutablePointer(to: &tmp) { intPtr in
            //C:-- void random_number_in_range_with_result_pointer(const int min, const int max, int* result);
            random_int_with_result_pointer(intPtr)
        }
        return Int(tmp)
    }
    
    //Using a CInt means don't have to have a tmp var
    public func addRandom(to baseInt:CInt, cappingAt:CInt = CInt.max) -> CInt {
        withUnsafePointer(to: baseInt) { (min_ptr) -> CInt in
            withUnsafePointer(to: cappingAt) { (max_ptr) -> CInt in
                //C:-- int random_number_in_range(const int* min, const int* max);
                return random_number_in_range(min_ptr, max_ptr);
            }
        }
    }
    
    //MARK: Arrays of Values
    
    public func makeArrayOfRandomIntExplicitPointer(count:Int) -> [Int] {
        let start = UnsafeMutablePointer<CInt>.allocate(capacity: count)
        
        //C:-- void random_array_of_zero_to_one_hundred(int* array, const size_t n);
        random_array_of_zero_to_one_hundred(start, count)
        
        //Make a buffer pointer for easy casting.
        let outPut = UnsafeBufferPointer<CInt>(start: start,count: count)
        
        let tmp = [CInt](outPut)
        
        start.deinitialize(count: count)
        start.deallocate()
        
        return tmp.map { Int($0) }
    }
    
    public func makeArrayOfRandomIntClosure(count:Int) -> [Int] {
        //Count for this initializer is really MAX count possible, function may return an array with fewer items defined.
        //both buffer and initializedCount are inout
        let tmp = Array<CInt>(unsafeUninitializedCapacity: count) { buffer, initializedCount in
            //C:-- void random_array_of_zero_to_one_hundred(int* array, const size_t n);
            random_array_of_zero_to_one_hundred(buffer.baseAddress, count)
            initializedCount = count // if initializedCount is not set, Swift assumes 0, and the array returned is empty.
        }
        return tmp.map { Int($0) }
    }
    
    //Explicit buffer pointer management
    public func makeArrayOfRandomInRange(min base:CInt, max:CInt, count:Int) -> [Int] {
        let max_delta = max - base
        let start = UnsafeMutablePointer<CInt>.allocate(capacity: count)
        start.initialize(repeating: CInt(base), count: count)
        
        
        //C:-- void add_random_to_all_with_max_on_random(int* array, const size_t n, const int max);
        add_random_to_all_with_max_on_random(start, count, max_delta)
        
        let outPut = UnsafeBufferPointer<CInt>(start: start, count: count)
        let tmp = [CInt](outPut)
        
        start.deinitialize(count: count)
        start.deallocate()
        //DO NOT outPut.deallocate() AND start.deallocate()
        //appears to be a double free().
        
        return tmp.map { Int($0) }
        
        //NOTE: This also works in case starting from an UnsafeBufferPointer
        //        guard let base_ptr = UnsafeMutablePointer(mutating: outPut.baseAddress)  else {
        //            fatalError("randomValueInRange: no mutable base pointer available")
        //        }
        //        add_random_to_all_with_max_on_random(base_ptr, count, upTo)
        
    }
    
    //MARK: Modifying Arrays
    
    //MUCH Cleaner than randomValueInRange, closure style call handles allocate & deallocate
    public func addRandomTo(_ baseArray:[CInt], randomValueUpTo randomMax:CInt) -> [CInt] {
        var arrayCopy = baseArray
        arrayCopy.withUnsafeMutableBufferPointer { bufferPointer in
            //Note: bufferPointer.count == arrayCopy.count
            //C:-- void add_random_to_all_with_max_on_random(int* array, const size_t n, const int max);
            add_random_to_all_with_max_on_random(bufferPointer.baseAddress, bufferPointer.count, randomMax)
        }
        return arrayCopy
    }
    
    public func addRandomWithCap(_ baseArray:[UInt32], newValueCap:UInt32) -> [UInt32] {
        var arrayCopy = baseArray
        //C:-- void add_random_to_all_capped(unsigned int* array, const size_t n, unsigned int cap);
        add_random_to_all_capped(&arrayCopy, arrayCopy.count, newValueCap)
        return arrayCopy
        
    }
    
    //MARK: Complex Call Example - Fuzz Values in a UInt8 array.
    
    //Use C to call the underlying function to make sure it works.
    public func testBufferProcess() {
        call_buffer_process_test()
    }
    
    //See notes in fuzzBuffer function.
    public let base_buffer:[UInt8] = [ 0x33, 0x33, 0x33, 0x66, 0x66, 0x66, 0x99, 0x99, 0x99,
                                       0xCC, 0xCC, 0xCC, 0xEE, 0xEE, 0xEE, 0xEE, 0x00, 0x00,
                                       0x00, 0xEE, 0x00, 0x00, 0xEE, 0x00, 0x11, 0x11, 0x11 ]
    
    
    public func fuzzedBaseBuffer(fuzzAmount:UInt8) -> [UInt8] {
        
        //NOTE: Since acknowledge_uint8_buffer takes a defined type, Swift brings in the C function as a UnsafePointer, which can be used with a let.
        //S:-- acknowledge_uint8_buffer(UnsafePointer<UInt8>!, Int)
        //C:-- void acknowledge_uint8_buffer(const uint8_t* array, const size_t n)
        acknowledge_uint8_buffer(base_buffer, base_buffer.count)
        
        //NOTE: Since fuzz_buffer takes a void*, which means an UnsafeRawPointer, it cannot be used with a let
        var m_base_buffer = base_buffer
        
        //vars that don't really do much beyond being passed to function to prove they can be.
        var settings:[CInt] = [300, 2883, 499832, 6]
        var width = 3
        var height = 3
        let bytes_per_pixel = 3
        
        //results buffer
        var outputBuffer:[UInt8] = Array(repeating: 0, count: width * height * bytes_per_pixel)
        //Note: Reserving capacity is not good enough. Must be written to.
        //outputBuffer.reserveCapacity(width * height * bytes_per_pixel)
        
        //also a result container, implicitly cast to UnsafeMutablePointer<Int> in function call.
        var sizeResult:Int = 0
        
        //S:-- fuzz_buffer(settings: UnsafeMutablePointer<Int32>!, settings_count: u_int, width_ptr: UnsafePointer<Int>!, height_ptr: UnsafePointer<Int>!, bytes_per_pixel: Int, calculated_size_ptr: UnsafeMutablePointer<Int>!, input_buffer: UnsafeRawPointer!, output_buffer: UnsafeMutableRawPointer!)
        //C:-- int fuzz_buffer(int* settings,u_int settings_count,const size_t* width_ptr,const size_t* height_ptr,size_t bytes_per_pixel,size_t* calculated_size_ptr,const void* input_buffer,void* output_buffer);
        fuzz_buffer(&settings, CUnsignedInt(settings.count), &width, &height, bytes_per_pixel, &sizeResult, fuzzAmount, &m_base_buffer, &outputBuffer)
        //fuzz_buffer uses `unsigned char char_whiffle(const unsigned char* byte, const unsigned char wiffle)` to add a ±random amount to each char in the buffer.
        
        //This function DID take a let, because a typed array-pointer, which is different than
        // a pointer to other types.
        //let copy = outputBuffer
        //C:-- void acknowledge_uint8_buffer(const uint8_t* array, const size_t n)
        //acknowledge_uint8_buffer(copy, outputBuffer.count)
        
        return outputBuffer
    }
    
    //MARK: Void* Array Handling
    
    //All the C functions below take void* reference.
    //TODO: MemoryLayout<R>.size (byte count) or MemoryLayout<R>.stride (byte count after packing) in these functions?
    
    //Convenience Raw pointer.
    public func bufferSetHigh<R:Numeric>(count:Int, ofType:R.Type) -> [R] {
        var dataBuffer = Array<R>(repeating: 0, count: count)
        //C: void set_all_bits_high(void* array, const size_t n, const size_t type_size);
        set_all_bits_high(&dataBuffer, count, MemoryLayout<R>.stride) //maybe should be .stride??
        return dataBuffer
    }
    
    //This is the same as the above, but explicit.
    public func bufferSetLow<R:Numeric>(count:Int, ofType:R.Type) -> [R] {
        var dataBuffer = Array<R>(repeating: 0, count: count)
        dataBuffer.withUnsafeMutableBytes { bufferPointer in
            //C: void set_all_bits_low(void* array, const size_t n, const size_t type_size);
            set_all_bits_low(bufferPointer.baseAddress, count, MemoryLayout<R>.stride) //maybe should be .stride??
        }
        return dataBuffer
    }
    
    //Array initializer.
    public func bufferSetToRandomBytes<R:Numeric>(count:Int, ofType:R.Type) -> [R] {
        Array<R>(unsafeUninitializedCapacity: count) { buffer, initializedCount in
            //C: void set_all_bits_random(void* array, const size_t n, const size_t type_size);
            set_all_bits_random(&buffer, count, MemoryLayout<R>.stride) //maybe should be .stride??
            initializedCount = count
        }
    }
    
    //TODO: Have not tested cPrintHexAnyArray with non numeric types.
    func cPrintHexAnyArray(_ array:[Any]) {
        print("opaque:")
        //withUnsafeBufferPointer does not work in this case of passing to void*, need to make a var to make a implicit mutable pointer
        var for_pointer = array
        //C:--  void print_opaque(const void* p, const size_t byte_count);
        print_opaque(&for_pointer, array.count)
    }
    
    //MARK: CColorRGBA Union Color
    
    public func printUInt32AsColor(colorInt:UInt32) {
        //C:-- void print_color_components(const uint32_t color_val)
        //This function casts the uint32_t to a CColorRGBA internally
        print_color_components(colorInt)
    }
    
    public func makeRandomUInt32Buffer(count:Int) -> [UInt32] {
        var dataBuffer = Array<UInt32>(repeating: 0, count: count)
        //C:-- void random_colors_full_alpha(uint32_t* array, const size_t n);
        random_colors_full_alpha(&dataBuffer, count);
        return dataBuffer
    }
    
    
    public func printUInt32BufferAsColor(_ buffer:[UInt32]) {
        for item in buffer {
            //print(String(format: "0x%08x", item))
            print(String(item, radix: 16, uppercase: true))
        }
    }
    
    public func printCColorRGBA(_ color:CColorRGBA) {
        print(color.full)
        print(color.bytes)
        print(color.red, color.green, color.blue, color.alpha)
    }
    
    public func makeAndVerifyCColor(_ colorInt:UInt32) ->  CColorRGBA {
        let color = CColorRGBA(full: colorInt)
        printCColorRGBA(color)
        return color
    }
    
    
    public func castUInt32BufferAsColors(_ buffer:[UInt32]) -> [CColorRGBA] {
        buffer.lazy.map { CColorRGBA(full: $0) }  //TODO: does lazy matter here? Only when in an extension?
    }
    
    public func printCColorRGBABuffer(_ buffer:[CColorRGBA]) {
        for item in buffer {
            //print(String(format: "0x%08x", item))
            print(String(item.full, radix: 16, uppercase: true))
        }
    }
    
    public func castingTests(theInt:UInt32, theColor:CColorRGBA) {
        //Nope.
        //let castItC = theInt as? CColorRGBA
        //let castCtI = theColor as? UInt32
        
        if let forceLoadAsColor:CColorRGBA = withUnsafeBytes(of: theInt, { bytesPointer in
            return bytesPointer.baseAddress?.load(as: CColorRGBA.self)
        }) {
            printCColorRGBA(forceLoadAsColor)
        }
        
        
        //---------- Using full initializer ------------
        let reinit = CColorRGBA(full: theInt)
        printCColorRGBA(reinit)
        
        
        //---------- Using bytes initializer ------------
        let tupleInit = withUnsafeBytes(of: theInt) { bytesPointer in
            let array = [UInt8](bytesPointer)
            //fixed size arrays in C are treated in Swift as tuples.
            return CColorRGBA(bytes: (array[0], array[1], array[2], array[3]))
        }
        printCColorRGBA(tupleInit)
        
        let tupleInitLoadAs:CColorRGBA = withUnsafeBytes(of: theInt) { bytesPointer in
            return CColorRGBA(bytes: (bytesPointer.baseAddress?.load(as: (UInt8, UInt8, UInt8, UInt8).self)).unsafelyUnwrapped)
        }
        printCColorRGBA(tupleInitLoadAs)
        
        let tupleInitMemcpy:CColorRGBA = CColorRGBA(bytes:uint32ToTuple_memcpy_yolo(theInt))
        printCColorRGBA(tupleInitMemcpy)
        
        //---------- end using anon struct initializer ------------
        //CColorRGBA(CColorRGBA.__Unnamed_struct___Anonymous_field2)
        let structInit = withUnsafeBytes(of: theInt) { bytesPointer in
            let structCast = bytesPointer.baseAddress?.load(as: CColorRGBA.__Unnamed_struct___Anonymous_field2.self)
            return CColorRGBA(structCast!)
            
            //Notes: Can init an array if want explicit destinations for the UInts
            //let array = [UInt8](bytesPointer)
            //return CColorRGBA(CColorRGBA.__Unnamed_struct___Anonymous_field2(alpha: array[0], blue: array[1], green: array[2], red: array[3]))
            
            //If use a named struct it's less ugly.
            //CColorRGBA2(components: c_color_comp(alpha: T##UInt8, blue: T##UInt8, green: T##UInt8, red: T##UInt8))
        }
        printCColorRGBA(structInit)
        
    }
    
    //MARK: Crazy Int32 <-> tuple/CColor mechanisms. All less safe and more arcane than the .load(as)
    //---------------------------------------------------------------------------------------
    //---------------------------------------------------------------------------------------
    public func testTransfer() {
        let quadInt = [98, 344444, 82737364, 2827272]
        let quadInt32:[UInt32] = [64000, 32000, 8654, 12]
        let quadDouble:[Double] = [7.5553322, 2717481.2, 27171.271712, 3.14373727272]
        
        let tInt = arrayQuadToTuple_memcpy_yolo(quadInt)
        let tInt32 = arrayQuadToTuple_memcpy_yolo(quadInt32)
        let tDouble = arrayQuadToTuple_memcpy_yolo(quadDouble)
        
        print(tInt, tInt32, tDouble)
        
        print(uint32ToTuple_memcpy_yolo(0x44778822))
        print(uint32ToTupleUsingBind(0x44778822))
        
        let testVar:UInt32 = 0x44778822
        var color = uint32ToCColorUsingRebound(testVar)
        color.red = 0x99
        print(testVar)
        print(color.full)
    }
    
    func arrayQuadToTuple_memcpy_yolo<N:Numeric>(_ array:[N]) -> (N, N, N, N) {
        var tuple:(N, N, N, N) = (0, 0, 0, 0)
        let _ = withUnsafeMutablePointer(to: &tuple) { tuplePointer in
            //destination pointer, source, number of bytes
            memcpy(tuplePointer, array, 4*MemoryLayout<N>.size)
        }
        return tuple
    }
    
    func uint32ToTuple_memcpy_yolo(_ sourceUInt32:UInt32) -> (UInt8,UInt8,UInt8,UInt8) {
        var tuple:(UInt8,UInt8,UInt8,UInt8) = (0, 0, 0, 0)
        let _ = withUnsafeMutablePointer(to: &tuple) { tuplePointer in
            withUnsafePointer(to: sourceUInt32) { intPointer in
                //destination pointer, source, number of bytes
                memcpy(tuplePointer, intPointer, 4)
            }
        }
        return tuple
    }
    
    func uint32ToTupleUsingBind(_ sourceUInt32:UInt32)  -> (UInt8,UInt8,UInt8,UInt8) {
        let rebound = withUnsafePointer(to: sourceUInt32) { intPointer -> (UInt8, UInt8, UInt8, UInt8) in
            UnsafeRawPointer(intPointer).bindMemory(to: (UInt8,UInt8,UInt8,UInt8).self, capacity: 1).pointee
        }
        return rebound
    }
    
    func uint32ToCColorUsingReboundViaBytes(_ sourceUInt32:UInt32)  -> CColorRGBA {
        let color = withUnsafePointer(to: sourceUInt32) { intPointer -> CColorRGBA in
            UnsafeRawPointer(intPointer).withMemoryRebound(to: (UInt8,UInt8,UInt8,UInt8).self, capacity: 1) { valuePointer in
                CColorRGBA(bytes: valuePointer.pointee)
            }
        }
        return color
    }
    
    func uint32ToCColorUsingRebound(_ sourceUInt32:UInt32)  -> CColorRGBA {
        let color = withUnsafePointer(to: sourceUInt32) { sourcePointer -> CColorRGBA in
            UnsafeMutableRawPointer(mutating: sourcePointer).withMemoryRebound(to: CColorRGBA.self, capacity: 1) { valuePointer in
                return valuePointer.pointee
            }
        }
        return color
    }
    
    func quadTupleToInt32(_ tuple:(UInt8,UInt8,UInt8,UInt8)) -> UInt32? {
        withUnsafeBytes(of: tuple, { bytesPointer in
            return bytesPointer.baseAddress?.load(as: UInt32.self)
        })
    }
    
    func eraseQuadTupleToCArray(_ tuple:(CInt, CInt, CInt, CInt)) {
        withUnsafePointer(to: tuple) { (tuplePointer) in
            //C:-- void erased_tuple_receiver(const int* values, const size_t n);
            erased_tuple_receiver(UnsafeRawPointer(tuplePointer).assumingMemoryBound(to: CInt.self), 4)
        }
    }
    
    
    //---------------------------------------------------------------------------------------
    //---------------------------------------------------------------------------------------
    
    //MARK: Strings
    
    
    //Init buffer known to be bigger than what you'll get out.
    public func getAnswer() -> String {
        //fill with 0 (NULL) and C string functions will consider it empty.
        //512 in this case reps the maximum size expect to get back.
        var dataBuffer = Array<UInt8>(repeating: 0, count: 512)
        
        dataBuffer.withUnsafeMutableBufferPointer { bufferPointer in
            //C:-- void answer_to_life(char* result)
            answer_to_life(bufferPointer.baseAddress)
        }
        return String(cString: dataBuffer)
    }
    
    public func randomLetter() -> String{
        let letter:Data = Data([UInt8(random_letter())])
        return  String(data: letter, encoding: .utf8) ?? "Not a letter.";
    }
    
    //Combines cPrintMessage(message:String) and getString() examples.
    public func scrambleMessage(message:String) -> String {
        print(message.count)
        var length = 0
        //trying to pass &message to function doesn't work. & requires a var
        //but explicit withUnsafePointer(to:message) means can preserve the let
        print_opaque(message, message.count)
        return withUnsafePointer(to:message) { (message_ptr) -> String in
            //C:-- void random_scramble(const char* input, char* output, size_t* length);
            random_scramble(message_ptr, nil, &length)
            print("length:\(length)")
            return String(unsafeUninitializedCapacity: length) { buffer in
                //C:-- void random_scramble(const char* input, char* output, size_t* length);
                random_scramble(message_ptr, buffer.baseAddress, &length)
                print(String(cString: buffer.baseAddress!))
                precondition(buffer[length-1]==0)
                return buffer.count - 1
            }
        }
    }
    
    //const char* message will take message:String, no problems.
    public func cPrintMessage(message:String) {
        //C:-- void print_message(const char* message);
        print_message(message)
        
        //If needed to get a return value:
        //let result:SomeType =  message.withCSString { (str) -> SomeType  in ...}
    }
    
    
    //when keeping the allocation small is more important than the double call
    public func getString() -> String {
        var length = 0
        //C:-- void build_concise_message(char* result, size_t* length);
        build_concise_message(nil, &length)
        return String(unsafeUninitializedCapacity: length) { buffer in
            //C:-- void build_concise_message(char* result, size_t* length);
            build_concise_message(buffer.baseAddress, &length)
            print(String(cString: buffer.baseAddress!))
            precondition(buffer[length-1]==0)
            return buffer.count - 1
        }
    }
    
}



