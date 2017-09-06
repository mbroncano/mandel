//
//  Pixel.swift
//  Mandelbrot
//
//  Created by Manuel Broncano on 9/2/17.
//  Copyright © 2017 Manuel Broncano. All rights reserved.
//

import Foundation
import CoreGraphics

func clamp(_ c: Double) -> UInt8 {
    return UInt8(min(Double(UInt8.max), max(c, Double(UInt8.min))))
}

struct Pixel {
    let a, r, g, b: UInt8

    static var black = Pixel([0, 0, 0])

    init(_ c: [Double]) {
         a = 255
         r = clamp(c[0])
         g = clamp(c[1])
         b = clamp(c[2])
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


