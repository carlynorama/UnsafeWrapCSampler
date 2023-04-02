//
//  BridgeColor_ColorBridge.swift
//  
//
//  Created by Carlyn Maw on 3/30/23.
//  Example of how to make wrappers to work with OpaquePointers
//  Consequence of incomplete typedef / OpaqueTypes
//  May not work for structs that are more complicated?

// Two styles a struct (BridgeColor) and a class (ColorBridge)

// With the struct, Swift owns the data, and we can use functions
// written in C as long as we a re confident our Swift Struct shares
// the memory layout of the C struct type (or more helper functions.. etc). The opaque pointer shouldn't be passed to C function that will save the pointer.

import Foundation
import UWCSamplerC

public struct BridgeColor {
    public let alpha:UInt8
    public let blue:UInt8
    public let green:UInt8
    public let red:UInt8
    
    public init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

extension BridgeColor {
    
    public func printExpectedInt() {
        print(String(format: "0x%02x%02x%02x%02x", red, green, blue, alpha))
    }
    
    public func asUINT32FromPointerType() -> UInt32 {
        withUnsafeBytes(of: self) { (buffer) -> UInt32 in
            //C:-- int_from_opaque_color(OpaqueColor!)
            let tmp = int_from_opaque_color(OpaquePointer(buffer.baseAddress))
            print(String(format: "%x", tmp))
            return tmp
        }
    }
    
    public func asUINT32FromPointerToConcreteType() -> UInt32 {
        withUnsafeBytes(of: self) { (buffer) -> UInt32 in
            //C:-- int_from_opaque_color(COpaqueColor!) <- CANNOT be used easily
            //C:-- int_from_copaque_color_ptr(OpaquePointer!) <- CAN be used
            let tmp = int_from_copaque_color_ptr(OpaquePointer(buffer.baseAddress))
            print(String(format: "%x", tmp))
            return tmp
        }
    }
    
    
}


// With the class C owns the memory management. C Library must provide
// pointer and a function to free it?
// Note: If writing the C library implement a way to warn the Swift
// if the C frees the pointer itself? If using existing make sure it won't.

public class ColorBridge {
    private var _ptr: OpaquePointer
    
    //Really should force component initialization with init.
    public init() {
        //C:-- CColor* create_pointer_for_ccolor() { //has a malloc// }
        _ptr = create_pointer_for_ccolor()
        //assert(_ptr, "Failed on create_pointer()")
    }
    
    
    public func setColor(red:UInt8, green:UInt8, blue:UInt8, alpha:UInt8) {
        //C:-- void set_color_values(COpaqueColor* c, uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha)
        set_color_values(_ptr, red, green, blue, alpha)
        
    }
    
    deinit {
        //C:-- void delete_pointer_for_ccolor() { //has free// }
        //(see Note above.)
        delete_pointer_for_ccolor(_ptr)
    }
    
    //C:-- uint8_t ccolor_get_red(COpaqueColor* c) { return c->red; }
    //In real implementation would also write setters.
    public var red: UInt8 {
        get { return ccolor_get_red(_ptr) }
    }
    
    public var green: UInt8 {
        get { return ccolor_get_green(_ptr) }
    }
    public var blue: UInt8 {
        get { return ccolor_get_blue(_ptr) }
    }
    public var alpha: UInt8 {
        get { return ccolor_get_alpha(_ptr) }
    }
    
}


//TODO: Go the other way?
//let str0 = "boxcar" as CFString
//let bits = Unmanaged.passUnretained(str0)
//let ptr = bits.toOpaque()
