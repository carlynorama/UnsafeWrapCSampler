# UnsafeWrapCSampler

Practice for using the Unsafe APIs to wrap C library. For examples on how to use these functions in an actual application see the companion project [UnsafeExplorer](https://github.com/carlynorama/UnsafeExplorer). 

This companion project never imports the C target, so it cannot use the functions directly. It is worth noting that it can recognize (but not create) the more complex C types that are fully defined in the header even without the import. (See [RandomColorsView](), testColorFunctions(), where c_color is allowed to exist as a CColorRGBA, but a new one cannot be created there. )

The package file has a target for the C and the Swift package uses that as a dependency. 

First scan the `random.h` for the types of C function the Swift examples bridge to. The header file is commented with the location of the Swift code that calls it. 




## References
- https://developer.apple.com/documentation/Swift/manual-memory-management
- Unsafe Swift https://developer.apple.com/videos/play/wwdc2020/10648/
- Safely manage pointers in Swift https://developer.apple.com/videos/play/wwdc2020/10167/
- https://developer.apple.com/documentation/swift/using-imported-c-structs-and-unions-in-swift
- https://developer.apple.com/documentation/swift/opaquepointer


## In this repo

### C Code

The basis of the package is a C library for working with random numbers. The C functions were written to test the Swift code, not to demonstrate best practices in C. For example, `rand()` is not a great source for random numbers, there is very little error checking, some fairly sloppy typing (`int` when should be `uint` or `size_t`, unnecessary `void*`), lots of pointers where you wouldn't necessarily use one, etc. 



`random_provider.h` & `random_provider.c` are larger than they should be since ALL of the code is in them. Please s



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
