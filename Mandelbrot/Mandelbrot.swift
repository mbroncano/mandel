//
//  Mandelbrot.swift
//  Mandelbrot
//
//  Created by Manuel Broncano on 9/12/17.
//  Copyright © 2017 Manuel Broncano. All rights reserved.
//

import CoreGraphics
import simd

let palette: [Pixel] = {
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

func mandelbrot(min a: Complex, max b: Complex, size: CGSize, maxiter: Int) -> CGImage? {
    let width = Int(size.width)
    let height = Int(size.height)
    let count = width * height
    let escape = 256.0 // adjusted for smoothness
    var result = [Double](repeating: 1.0, count: count)

    // it doesn't make a difference when running in the device
    DispatchQueue.concurrentPerform(iterations: count) { i in
        //        for i in 0..<count {
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
