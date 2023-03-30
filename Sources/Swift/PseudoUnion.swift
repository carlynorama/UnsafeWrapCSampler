//
//  PseodoUnion.swift
//  
//
//  Created by Carlyn Maw on 3/30/23.
//

//TODO: bitPattern initializers??

import Foundation

//What CColorRGB looks like to the Swift

//When using a union as a TypeDef there was only one initializer for the opaque type made available - init(bitPattern:)
//init(bitPattern pointer: OpaquePointer?)
//init(bitPattern objectID: ObjectIdentifier)


public struct PseudoUnion {
    var full: UInt32
    
    public init(full: UInt32) {
        self.full = full
    }
    
    public init(bytes:[UInt8]) {
        var tmp = UInt32(bytes[0])
        tmp += UInt32(bytes[1] << 8)
        tmp += UInt32(bytes[2] << 16)
        tmp += UInt32(bytes[3] << 24)
        self.full = tmp
    }

    //layout: 0xRRGGBBAA input leads to [0]AA, [1]BB, [2]GG, [3]RR
    
    let red_shift = 24
    let green_shift = 16
    let blue_shift = 8
    let alpha_shift = 0
    
    public var bytes:[UInt8] {
        get {
            var bytes:[UInt8] = []
            bytes.append(UInt8(full & 0xFF)) //alpha
            bytes.append(UInt8((full >> blue_shift) & 0xFF))
            bytes.append(UInt8((full >> green_shift) & 0xFF))
            bytes.append(UInt8((full >> red_shift) & 0xFF))
            return bytes
        }
        set {
            //Works.
//            var tmp = UInt32(newValue[0]) //alpha
//            tmp += UInt32(newValue[1]) << blue_shift
//            tmp += UInt32(newValue[2]) << green_shift
//            tmp += UInt32(newValue[3]) << red_shift
//            full = tmp
            //TODO: Is there a way to hijack the subscript?
            full = newValue.withUnsafeBytes { (bytes) -> UInt32 in
                bytes.load(as: UInt32.self)
            }
        }
    }
    
    public var red:UInt8 {
        
        get {
            UInt8((full >> red_shift) & 0xFF)
        }
        set {
            let mask:UInt32 = ~(0xFF << red_shift)
            let tmp = full & mask
            //print("red update")
            //print(String(format: "0x%08x", tmp))
            //print(String(format: "0x%08x", UInt32(newValue) << red_shift))
            full = (UInt32(newValue) << red_shift) | tmp
        }
    }
    
    public var green:UInt8 {
        get {
            UInt8((full >> green_shift) & 0xFF)
        }
        set {
            let mask:UInt32 = ~(0xFF << green_shift)
            let tmp = full & mask
            full = (UInt32(newValue) << green_shift) | tmp
        }
    }
    
    public var blue:UInt8 {
        get {
            UInt8((full >> blue_shift) & 0xFF)
        }
        set {
            let mask:UInt32 = ~(0xFF << blue_shift)
            let tmp = full & mask
            full = (UInt32(newValue) << blue_shift) | tmp
        }
    }
    
    
    public var alpha:UInt8 {
        get {
            UInt8((full >> alpha_shift) & 0xFF)
        }
        set {
            let mask:UInt32 = ~(0xFF << alpha_shift)
            let tmp = full & mask
            full = (UInt32(newValue) << alpha_shift) | tmp
        }
    }
    
    public func testPrint() {
        print("red: \(red), green: \(green), blue: \(blue), alpha: \(alpha)")
        print(bytes)
        print(String(format: "0x%08x", full))
    }
    
    
}
