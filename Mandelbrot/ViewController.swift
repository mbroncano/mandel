//
//  ViewController.swift
//  Mandelbrot
//
//  Created by Manuel Broncano on 9/2/17.
//  Copyright © 2017 Manuel Broncano. All rights reserved.
//

import UIKit
import CoreGraphics

let MAX_SCALE = 2 << 16
let sideLength = CGFloat(256.0)

let palette: [Pixel] = {
    let control = [(0.0,    [0,   7,   100]),
                   (0.16,   [32,  107, 203]),
                   (0.42,   [237, 255, 255]),
                   (0.6425, [255, 170, 0]),
                   (0.8575, [0,   2,   0])]

    let xs = control.map { $0.0 }
    let cs = control.map { $0.1.map { Double($0) } }
    let interpol = createInterpolant2(xs: xs, ys: cs)

    let pal_size = 512
    return (0..<pal_size).map { i -> Pixel in
        let hue = Double(i) / Double(pal_size-1)
        let c = interpol(hue)
        return Pixel(c)
    }
}()

func mandelbrot(min a: Complex, max b: Complex, size: CGSize, maxiter: Int) -> [Double] {
    let width = Int(size.width)
    let height = Int(size.height)
    let count = width * height
    var result = [Double](repeating: 0, count: count)

    let inside: (Complex) -> Double = { c in
        var z = Complex()
        var iter = 0
        while z.radiusSquare < 4, iter < maxiter {
            z = z^2 + c
            iter += 1
        }

        guard iter < maxiter else { return 1.0 }

        // smooth only when outside
        let smooth = (Double(iter) - (log(log(z.radius) / log(Double(maxiter))) / log(2))) / Double(maxiter)

        return max(0.0, min(smooth, 1.0))
    }

//    for i in 0..<count {
    DispatchQueue.concurrentPerform(iterations: count) { i in
        let (x, y) = (i % width, height - (i / width)) // draw it flipped
        let (u, v) = (Double(x) / Double(width), Double(y) / Double(height))
        let c = Complex(u, v).lerp(min: a, max: b)
        result[i] = inside(c)
    }

    return result
}


class MandelLayer: CATiledLayer {
    override func draw(in ctx: CGContext) {
        super.draw(in: ctx)
        print(ctx.ctm)

        let bounds = self.bounds.size
        let rect = ctx.convertToUserSpace(CGRect(origin: CGPoint.zero, size: self.tileSize))
        print(rect, bounds, ctx.ctm, rect.applying(ctx.ctm), bounds.applying(ctx.ctm))

        let min = Complex(-2.5, -1.5)
        let max = Complex(1.5, 1.5)
        let u = Double(rect.origin.x) / Double(bounds.width)
        let v = Double(rect.origin.y) / Double(bounds.height)
        let i = Double(rect.size.width) / Double(bounds.width)
        let j = Double(rect.size.height) / Double(bounds.height)

        let a = Complex(u, v).lerp(min: min, max: max)
        let b = Complex(u + i, v + j).lerp(min: min, max: max)

        let scale = ctx.ctm.a
        let density = self.contentsScale
        let tilescale = scale / density
        let tilesize = self.tileSize / density

        let maxiter = 64 * Int(log(tilescale) / log(2))

        let result = mandelbrot(min: a, max: b, size: tilesize, maxiter: maxiter)
        let array = result.map { palette[Int(Double(palette.count-1) * $0)] }

        guard let image = array.cgImage(size: tilesize) else { return  }
        ctx.draw(image, in: rect)
    }
}

class TileView: UIView {
    let sideLength = CGFloat(256.0)

    override class var layerClass: AnyClass {
        return MandelLayer.self
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let layer = self.layer as! MandelLayer
        layer.tileSize = CGSize(width: sideLength, height: sideLength)
        layer.levelsOfDetail = MAX_SCALE
        layer.levelsOfDetailBias = MAX_SCALE
    }
}

class ViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var tileView: TileView!
    @IBOutlet weak var scrollView: UIScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.maximumZoomScale = CGFloat(MAX_SCALE * 2)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.tileView
    }
}



