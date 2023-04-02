//
//  BridgeColor.swift
//  
//
//  Created by Carlyn Maw on 3/30/23.
//  Example of how to make a wrapper to work with OpaquePointers
//  Consequence of incomplete typedef / OpaqueTypes
//  May not work for structs that are more complicated? 

import Foundation
import UWCSamplerC

public struct BridgeColor {
    let alpha:UInt8
    let blue:UInt8
    let green:UInt8
    let red:UInt8
    
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




//Alternate approach for incomplete struct depending on needs.
//class ColorBridge {
//    private var _ptr: OpaquePointer
//
//    //C:-- CColor* create_pointer_for_ccolor() { //has a malloc// }
//    init() {
//        _ptr = create_pointer_for_ccolor()
//        assert(_ptr, "Failed on create_pointer()")
//    }
//
//    //C:-- CColor* delete_pointer_for_ccolor() { //has free// }
//    deinit {
//        delete_pointer_for_ccolor(_ptr)
//    }
//
//    //C:-- uint8_t ccolor_get_red(COpaqueColor* c) { return c->red; }
//    var red: UInt8 {
//        get { return ccolor_get_red(_ptr)) }
//    }
//
//}
