//
//  MandelLayer.swift
//  Mandelbrot
//
//  Created by Manuel Broncano on 9/7/17.
//  Copyright © 2017 Manuel Broncano. All rights reserved.
//

import UIKit
import simd


/// A layer that displays the mandelbrot fractal on multiple zoom levels
class MandelLayer: CATiledLayer {
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

    let min = Complex(-2.5, -1.5)
    let max = Complex(1.5, 1.5)

    override func draw(in ctx: CGContext) {
        super.draw(in: ctx)

        let bounds = self.bounds.size
        let rect = ctx.convertToUserSpace(CGRect(origin: CGPoint.zero, size: self.tileSize))
//        print(rect, bounds, ctx.ctm, rect.applying(ctx.ctm), bounds.applying(ctx.ctm))

        let u = Double(rect.origin.x) / Double(bounds.width)
        let v = Double(rect.origin.y) / Double(bounds.height)
        let i = Double(rect.size.width) / Double(bounds.width)
        let j = Double(rect.size.height) / Double(bounds.height)

        // convert aspect ration to bounds aspect ratio
        let inc: Complex
        let rb = Double(bounds.width) / Double(bounds.height)
        let sc = self.max - self.min
        let rc = sc.x / sc.y
        if rb < rc {
            inc = Complex(0, ((1.0 / rb) * sc.x - sc.y) / 2.0)
        } else {
            inc = Complex((rb * sc.y - sc.x) / 2.0, 0)
        }
        let min = self.min - inc
        let max = self.max + inc
//        let sm = max - min
//        let rm = sm.x / sm.y
//        print(rb, rc, rm, inc, min, max)

        let a = mix(min, max, t: Complex(u, v))
        let b = mix(min, max, t: Complex(u, v) + Complex(i, j))

        let tilesize = CGSize(width: self.tileSize.width / self.contentsScale, height: self.tileSize.height / self.contentsScale)

        let scale = ctx.ctm.a
        let zoom = scale / self.contentsScale
        let maxiter = 48 * Int(log2(zoom))

        let result = mandelbrot(min: a, max: b, size: tilesize, maxiter: maxiter)
        let array = result.map { palette[Int(Double(palette.count-1) * $0)] }

        guard let image = array.cgImage(size: tilesize) else { return  }
        ctx.draw(image, in: rect)
    }

    func mandelbrot(min a: Complex, max b: Complex, size: CGSize, maxiter: Int) -> [Double] {
        let width = Int(size.width)
        let height = Int(size.height)
        let count = width * height
        let escape = 256.0 // adjusted for smoothness
        var result = [Double](repeating: 1.0, count: count)

        // it doesn't make a difference when running in the device
        DispatchQueue.concurrentPerform(iterations: count) { i in
//        for i in 0..<count {
            let (x, y) = (i % width, height - (i / width)) // draw it flipped
            let (u, v) = (Double(x) / Double(width), Double(y) / Double(height))
            let c = Complex(u, v).lerp(min: a, max: b)

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

        return result
    }
}
