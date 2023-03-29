# UnsafeWrapCSampler

Practice for using UnsafeAPIs to wrap C library.

- https://developer.apple.com/documentation/Swift/manual-memory-management
- Unsafe Swift https://developer.apple.com/videos/play/wwdc2020/10648/
- Safely manage pointers in Swift https://developer.apple.com/videos/play/wwdc2020/10167/



TODO: Sanitizer

## Useful API names

UnsafePointer
UnsafeMutablePointer
UnsafeRawPointer
UnsafeRawMutablePointer
    - https://developer.apple.com/documentation/swift/unsafemutablerawpointer/storebytes(of:tobyteoffset:as:)
    - The type T to be stored must be a trivial type. The memory must also be uninitialized, initialized to T, or initialized to another trivial type that is layout compatible with T.


Unmanaged

UnsafeBufferPointer<Element>
UnsafeMutableBufferPointer<Element>

UnsafeRawBufferPointer
UnsafeMutableRawBufferPointer

Sequence.withContiguousStorageIfAvailable(_:)
MutableCollection.withContiguousMutableStorageIfAvailable(_:)

String.withCString(_:)
String.withUTF8(_:)

Array.withUnsafeBytes(_:)
Array.withUnsafeBufferPointer(_:)
Array.withUnsafeMutableBytes(_:)
Array.withUnsafeMutableBufferPointer(_:)

withUnsafePointer(to:_:)
withUnsafeMutablePointer(to:_:)
withUnsafeBytes(of:_:)
withUnsafeMutableBytes(of:_:)

## Try to Avoid

If using these, do it in the C. (these are `void*` interfaces) 

- assumingMemoryBound(to:)
- bindMemory(to:capacity)
- withMemoryRebound(to:capacity:)
