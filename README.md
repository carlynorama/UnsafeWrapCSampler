# UnsafeWrapCSampler

Practice for using the Unsafe APIs to wrap C library.

The basis of the package is a C library for working with random numbers. The C functions were written to test the Swift code, not to demonstrate best practices in C. For example, `rand()` is not a great source for random numbers, there is very little error checking, some fairly sloppy typing (`int` when should be `uint` or `size_t`, unnecessary `void*`), lots of pointers where you wouldn't necessarily use one, etc. 


## References
- https://developer.apple.com/documentation/Swift/manual-memory-management
- Unsafe Swift https://developer.apple.com/videos/play/wwdc2020/10648/
- Safely manage pointers in Swift https://developer.apple.com/videos/play/wwdc2020/10167/
- https://developer.apple.com/documentation/swift/using-imported-c-structs-and-unions-in-swift

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

- [assumingMemoryBound(to:)](https://developer.apple.com/documentation/swift/unsafemutablerawpointer/assumingmemorybound(to:))
- [bindMemory(to:capacity)](https://developer.apple.com/documentation/swift/unsafemutablerawpointer/bindmemory(to:capacity:))
- [withMemoryRebound(to:capacity:)](https://developer.apple.com/documentation/swift/unsafemutablerawpointer/withmemoryrebound(to:capacity:_:))

