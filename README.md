# UnsafeWrapCSampler

Practice for using the Unsafe APIs to wrap C library. 

Uses Swift 5.7 and has only been compiled for MacOS 13, but there is no UI code in this repo so cross compatibility should be pretty high.

The package file has two targets, a target for the C and one for the Swift. The Swift target uses the C target as a dependency. 

For examples on how to use these functions in an actual application see the companion project [UnsafeExplorer](https://github.com/carlynorama/UnsafeExplorer). 

This companion project never imports the C target, so it cannot call the C functions directly. It is worth noting that it can recognize (but not create) the more complex C types that are fully defined in the header even without the import. (See [RandomColorsView](https://github.com/carlynorama/UnsafeExplorer/blob/main/UnsafeExplorer/SubViews/RandomColorsView.swift), testColorFunctions(), where c_color is allowed to exist as a CColorRGBA, but a new one cannot be created there. )

## References

The bulk of the repo's code was made by following along with the two WWDC videos and making examples

- https://developer.apple.com/documentation/Swift/manual-memory-management
- Unsafe Swift https://developer.apple.com/videos/play/wwdc2020/10648/
- Safely manage pointers in Swift https://developer.apple.com/videos/play/wwdc2020/10167/
- https://developer.apple.com/documentation/swift/using-imported-c-structs-and-unions-in-swift
- https://developer.apple.com/documentation/swift/opaquepointer


## Using the UnsafeWrapCSample repo

This repo is not designed to import into production code as much as to use as a reference. To quickly get a sense of what it can do, download the companion project mentioned above. It has Views for each of the major concepts. 

- First scan the `random.h` for the types of C function that the Swift examples bridge to. The header file is commented with the location of the Swift code that calls it. The C functions were written to test the Swift code, not to demonstrate best practices in C. For example, `rand()` is not a great source for random numbers, there is very little error checking, some fairly sloppy typing (`int` when should be `uint` or `size_t`, unnecessary `void*`), lots of pointers where one wouldn't necessarily use one, etc. 

- The bulk of the code is in `RandomProvider` which is divided into sections, each providing a different kind of random information from numbers, to arrays of numbers, to strings, to a C struct representing 32bit color information.

- `BridgeColor_ColorBridge` contains two definitions: the struct BridgeColor, the class `ColorBridge`. These represent two different approaches for working with the OpaquePointers need to interface with C OpaqueTypes, e.g. `typedef struct COpaqueColor COpaqueColor;`

- `MiscHandy` has examples of loading in `Data` to different types using `Unsafe` APIs. There are also a couple of examples to get pointers into complex `Structs`.  After the initial examples of how to fetch fixed arrays from C, there actually isn't much that uses C. But being able to work with Data/[UInt8] formats is important for interfacing with Non-Swift APIs.

- `TupleBridge` contains some thoughts on how to deal with the fact that fixed length C arrays import into Swift as tuples by default. 

- `PseudoUnion` makes no C calls at all, but is an attempt to reproduce the behavior of the C union `CColorRGBA` using just Swift.

- `UnsafeBufferView is lifted straight from 25:52 of WWDC 2020 "Safely Manage Pointers in Swift." (link in references)


## Lessons Learned

Top take-a-ways from the exercise:

### Use the closure syntax

There is a great closure syntax for many of the APIS which means not needing to manually allocate and deallocate pointers. The closures can return any type wanted. This example uses a special Array initializer which I thought was pretty cool in and of itself. It's a little trick because initializedCount absolutely needs to be set to tell Swift how big the array ended up being. 

```Swift 
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
```

### Use the .load function whenever possible.

If bytes bound to one memory type need to look like something else to the code, `.load(as:)` is your friend.

```swift
    func quadTupleToInt32(_ tuple:(UInt8,UInt8,UInt8,UInt8)) -> UInt32? {
        withUnsafeBytes(of: tuple, { bytesPointer in
            return bytesPointer.baseAddress?.load(as: UInt32.self)
        })
    }
```
There is now even a `.loadUnaligned(fromByteOffset:,as:)` that will come in super handy for parsing data protocols in which the data may not be (aligned)[https://developer.ibm.com/articles/pa-dalign/]. 

```swift
    public func processUnalignedData<T>(data:Data, as type:T.Type, offsetBy offset:Int = 0) -> T {
        let result = data.withUnsafeBytes { buffer -> T in
            return buffer.loadUnaligned(fromByteOffset: offset, as: T.self)
        }
        print(result)
        return result
    }
```

### Use const in C function definitions

A `const` in the C function definition makes a difference to the Swift `Unsafe` pointer type. If a pointer is marked as `const`, then Swift only requires an `UnsafePointer`, which can be made from variables defined with `let`. If no const in the function parameter definition, Swift will require a `var` to create `UnsafeMutablePointer`.

To be honest, I went a little overboard and const'd the values as well. I have since confirmed that swift does NOT need that to pass in let values after all. I left them in b/c working code works. Modern C compilers are probably smart enough to write code that doesn't copy-on pass but on change, but historically some compilers did not make a new copy of a variable for functions that promised to be safe in their declarations. I have to look into this more if I ever decide to try to compile Swift for something tiny. 

[More about const and its usage (C++ discussion)](https://isocpp.org/wiki/faq/const-correctness#overview-const)

#### Examples
 
 `baseInt` and `cappingAt` don't need to have temporary vars made for them.

```swift
    public func addRandom(to baseInt:CInt, cappingAt:CInt = CInt.max) -> CInt {
        withUnsafePointer(to: baseInt) { (min_ptr) -> CInt in
            withUnsafePointer(to: cappingAt) { (max_ptr) -> CInt in
                //C:-- int random_number_in_range(const int* min, const int* max);
                return random_number_in_range(min_ptr, max_ptr);
            }
        }
    }
```

`baseArray` does need a copy made since it is not passed in as an `inout` variable. Strictly speaking this is safer, but depending on the buffer size may not be the desired behavior. Note the super swank temporary implicit `UnsafeMutableBufferPointer` created. So so nice. 

```swift
   public func addRandomWithCap(_ baseArray:[UInt32], newValueCap:UInt32) -> [UInt32] {
        var arrayCopy = baseArray
        //C:-- void add_random_to_all_capped(unsigned int* array, const size_t n, unsigned int cap);
        add_random_to_all_capped(&arrayCopy, arrayCopy.count, newValueCap)
        return arrayCopy
        
    }
```

### Don't for get about byte direction

Mac OS and many other systems are little endian, but "The Network" and many protocols are not. A well written API will not rely on the endianness of the system, but not all APIs are well written. 

For example, in my code I wrote a union that would let me enter #RRGGBBAA encode color information. It is NOT actually compliant with the OpenGL and PNG format RGBA32, because that data specification assumes the numbers are encoded 
with RED at byte[0], not byte[4]. Little endian systems will load the UInt32  #FFCC9966 into memory as [66, 99, CC, FF]

Little Endian systems should implement #AABBGGRR style numbers but that is the opposite of how I'm used to writing hex colors, so I did not for this code. 

To check a given system, try one of the following:

- `lscpu | grep Endian` 
- `echo -n I | od -to2 | awk 'FNR==1{ print substr($2,6,1)}'`  (return will be 1 for little endian, 0 for big)
- `python3 -c "import sys;print(sys.byteorder)"`



## Swift Unsafe API names

### Typed Pointers
- [`UnsafePointer`](https://developer.apple.com/documentation/swift/unsafepointer)
- [`UnsafeMutablePointer`](https://developer.apple.com/documentation/swift/unsafemutablepointer)

- [`UnsafeBufferPointer<Element>`](https://developer.apple.com/documentation/swift/unsafebufferpointer)
- [`UnsafeMutableBufferPointer<Element>`](https://developer.apple.com/documentation/swift/unsafemutablepointer)

### Raw Pointers
- [Unmanaged]

- [`UnsafeRawPointer`](https://developer.apple.com/documentation/swift/unsaferawpointer)
- [`UnsafeMutableRawPointer`](https://developer.apple.com/documentation/swift/unsafemutablerawpointer)
    - https://developer.apple.com/documentation/swift/unsafemutablerawpointer/storebytes(of:tobyteoffset:as:)
    - The type T to be stored must be a trivial type. The memory must also be uninitialized, initialized to T, or initialized to another trivial type that is layout compatible with T.


- [`UnsafeRawBufferPointer`](https://developer.apple.com/documentation/swift/unsaferawbufferpointer)
- [`UnsafeMutableRawBufferPointer`](https://developer.apple.com/documentation/swift/unsafemutablerawbufferpointer)

- [`Sequence.withContiguousStorageIfAvailable(_:)`](https://developer.apple.com/documentation/swift/array/withcontiguousstorageifavailable(_:)-1wj7c)
- [`MutableCollection.withContiguousMutableStorageIfAvailable(_:)`](https://developer.apple.com/documentation/swift/slice/withcontiguousmutablestorageifavailable(_:)-2ader)

### Misc other functions

- [`String.withCString(_:)`](https://developer.apple.com/documentation/swift/string/withcstring(_:)
- [`String.withUTF8(_:)`](https://developer.apple.com/documentation/swift/string/utf8cstring)

- [`Array.withUnsafeBytes(_:)`](https://developer.apple.com/documentation/swift/array/withunsafebytes(_:))
- [`Array.withUnsafeBufferPointer(_:)`](https://developer.apple.com/documentation/swift/array/withunsafebufferpointer(_:))
- [`Array.withUnsafeMutableBytes(_:)`](https://developer.apple.com/documentation/swift/array/withunsafemutablebytes(_:))
- [`Array.withUnsafeMutableBufferPointer(_:)`](https://developer.apple.com/documentation/swift/array/withunsafemutablebufferpointer(_:))

- [`withUnsafePointer(to:_:)`](https://developer.apple.com/documentation/swift/withunsafepointer(to:_:)-1wfum)
- [`withUnsafeMutablePointer(to:_:)`](https://developer.apple.com/documentation/swift/withunsafemutablepointer(to:_:))
- [`withUnsafeBytes(of:_:)`](https://developer.apple.com/documentation/swift/withunsafebytes(of:_:)-9p5df)
- [`withUnsafeMutableBytes(of:_:)`](https://developer.apple.com/documentation/swift/withunsafemutablebytes(of:_:))

### Try to Avoid

These rebind memory types. Better to do non-rebinding casting withUnsafeBytes or rawPointer.load(as)
Since working with C anyway, pass the pointer into a `void*` and do what you need to do. YOLO. 

(See UnsafeBufferView for the better way.)

- [assumingMemoryBound(to:)](https://developer.apple.com/documentation/swift/unsafemutablerawpointer/assumingmemorybound(to:))
- [bindMemory(to:capacity)](https://developer.apple.com/documentation/swift/unsafemutablerawpointer/bindmemory(to:capacity:))
- [withMemoryRebound(to:capacity:)](https://developer.apple.com/documentation/swift/unsafemutablerawpointer/withmemoryrebound(to:capacity:_:))

## TODO:
- //init(bitPattern pointer: OpaquePointer?)
- //init(bitPattern objectID: ObjectIdentifier)
