//
//  ViewController.swift
//  Mandelbrot
//
//  Created by Manuel Broncano on 9/2/17.
//  Copyright © 2017 Manuel Broncano. All rights reserved.
//

import UIKit
import CoreGraphics

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    var interpol: ((Double) -> [Double])?
    var minc, maxc: Complex?
    var size: CGSize?
    var maxiter: Int?
    var palette: [Pixel]?

    override func viewDidLoad() {
        super.viewDidLoad()

        let control = [(0.0,    [0,   7,   100]),
                       (0.16,   [32,  107, 203]),
                       (0.42,   [237, 255, 255]),
                       (0.6425, [255, 170, 0]),
                       (0.8575, [0,   2,   0])]

        let xs = control.map { $0.0 }
        let cs = control.map { $0.1.map { Double($0) } }
        self.interpol = createInterpolant2(xs: xs, ys: cs)
        self.minc = Complex(-2.5, -1.5)
        self.maxc = Complex(1.5, 1.5)

        let scale = UIScreen.main.scale
        let width = self.imageView.frame.size.width * scale
        let height = self.imageView.frame.size.height * scale
        self.size = CGSize(width: width, height: height)
        self.maxiter = 64
        DispatchQueue.global(qos: .background).async {
            self.mandelbrot(minc: self.minc!, maxc: self.maxc!, size: self.size!)
        }
    }

    func mandelset(minc: Complex, maxc: Complex, size: CGSize) -> [Double] {
        let width = Int(size.width)
        let height = Int(size.height)
        let count = width * height
        var result = [Double](repeating: 0, count: count)

        let inside: (Complex) -> Double = { c in
            var z = Complex()
            var iter = 0
            while z.radiusSquare < 4, iter < self.maxiter! {
                z = z^2 + c
                iter += 1
            }

            guard iter < self.maxiter! else { return 1.0 }

            // smooth only when outside
            let smooth = (Double(iter) - (log(log(z.radius) / log(Double(self.maxiter!))) / log(2))) / Double(self.maxiter!)

            return max(0.0, min(smooth, 1.0))
        }

        DispatchQueue.concurrentPerform(iterations: count) { i in
            let (x, y) = (i % width, i / width)
            let (u, v) = (Double(x) / Double(width), Double(y) / Double(height))
            let c = Complex(u, v).lerp(min: minc, max: maxc)
            result[i] = inside(c)
        }

        return result
    }

    func mandelbrot(minc: Complex, maxc: Complex, size: CGSize) {
        let buffer = mandelset(minc: minc, maxc: maxc, size: size)

        if self.palette == nil {
            let pal_size = 512
            let pal = (0..<pal_size).map { i -> Pixel in
                let hue = Double(i) / Double(pal_size-1)
                let c = self.interpol!(hue)
                return Pixel(c)
            }
            self.palette = pal
        }

        let array = buffer.map { self.palette![Int(Double(self.palette!.count-1) * $0)] }

        guard let image = array.cgImage(size: size) else { return }
        DispatchQueue.main.async {
            self.imageView.image = UIImage(cgImage: image)
        }
    }
}



