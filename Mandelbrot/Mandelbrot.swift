//
//  Mandelbrot.swift
//  Mandelbrot
//
//  Created by Manuel Broncano on 9/12/17.
//  Copyright © 2017 Manuel Broncano. All rights reserved.
//

import Foundation
import CoreGraphics
import simd

fileprivate struct Pixel {
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

fileprivate let palette: [Pixel] = {
    let control = [(0.0,    [0,   7,   100]),
                   (0.16,   [32,  107, 203]),
                   (0.42,   [237, 255, 255]),
                   (0.6425, [255, 170, 0]),
                   (0.8575, [0,   2,   0])]

    let xs = control.map { $0.0 }
    let cs = control.map { $0.1.map { Double($0) } }
    let interpol = createInterpolant(xs: xs, ys: cs, type: .Cubic)

    let pal_size = 512
    return (0..<pal_size).map { i -> Pixel in
        let hue = Double(i) / Double(pal_size-1)
        let c = interpol(hue)
        return Pixel(c)
    }
}()

typealias Complex = double2

extension Complex {

    init(_ size: CGSize) {
        self.init(x: Double(size.width), y: Double(size.height))
    }

    init(_ point: CGPoint) {
        self.init(x: Double(point.x), y: Double(point.y))
    }

    init(_ x: Int, _ y: Int) {
        self.init(x: Double(x), y: Double(y))
    }

    //! sqrt(x * x + y * y)
    var radius: Double { return length(self) }

    //! x * x + y * y
    var radiusSquare: Double { return length_squared(self) }

    //! self * self
    // (a+bi)(c+di) = ac+ad*i+bc*i+bd*i^2 [i^2=-1,a=c,b=d], a^2-b^2+2ab*i
    var square: Complex { return Complex(x * x - y * y, 2 * x * y) }

    //! self * (max - min) + min
    func lerp(min: Complex, max: Complex) -> Complex {
        return mix(min, max, t: self)
    }
}

func mandelbrot(min a: Complex, max b: Complex, size: CGSize, maxiter: Int) -> CGImage? {
    let width = Int(size.width)
    let height = Int(size.height)
    let count = width * height
    let escape = 256.0 // adjusted for smoothness
    var result = ContiguousArray(repeating: 1.0, count: count)

    // it doesn't make a difference when running in the device
//    DispatchQueue.concurrentPerform(iterations: count) { i in
                for i in 0..<count {
        let (x, y) = (i % width, height - (i / width)) // draw it flipped
        let uv = Complex(x, y) * recip(Complex(size))
        let c = uv.lerp(min: a, max: b)

        var z = Complex()
        for iter in 0..<maxiter {
            z = z.square + c
            guard z.radiusSquare < escape else {
                let smooth = (Double(iter) - log2(log(z.radius))) / Double(maxiter)
                result[i] = simd_clamp(smooth, 0, 1.0)// max(0.0, min(smooth, 1.0))
                break
            }
        }
    }

    return result.map { palette[Int(Double(palette.count-1) * $0)] }.cgImage(size: size)
}

fileprivate extension Array {
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


