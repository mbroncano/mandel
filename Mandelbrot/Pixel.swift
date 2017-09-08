//
//  Pixel.swift
//  Mandelbrot
//
//  Created by Manuel Broncano on 9/2/17.
//  Copyright © 2017 Manuel Broncano. All rights reserved.
//

import Foundation
import CoreGraphics
import simd

struct Pixel {
    let a, r, g, b: UInt8

    static var black = Pixel(double3())

    init() {
        self = Pixel(double3())
    }

    init(_ c: double3) {
        a = 255
        r = UInt8(c.x)
        g = UInt8(c.y)
        b = UInt8(c.z)
    }

    init(_ c: [Double]) {
        self.init(clamp(double3(c), min: Double(UInt8.min), max: Double(UInt8.max)))
    }
}

extension Array {

    func cgImage(size: CGSize) -> CGImage? {
        let width = Int(size.width)
        let height = Int(size.height)

        guard width > 0, height > 0 else { return nil }
        let pixelSize = MemoryLayout<Element>.size
        guard pixelSize == 4 else { return nil }
        guard self.count == Int(width * height) else { return nil }

        let data: Data = self.withUnsafeBufferPointer { (pointer) -> Data in
            return Data(buffer: pointer)
        }

        let cfdata = NSData(data: data) as CFData
        guard let provider = CGDataProvider(data: cfdata) else { return nil }

        guard let cgimage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * pixelSize,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
            ) else { return nil }

        return cgimage
    }
}


