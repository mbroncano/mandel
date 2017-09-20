//
//  ViewController.swift
//  Mandelbrot
//
//  Created by Manuel Broncano on 9/2/17.
//  Copyright © 2017 Manuel Broncano. All rights reserved.
//

import UIKit
import CoreGraphics
import simd

class TileView: UIView {
    let sideLength = 256
    let maxscale = 16 // this is 2 << 16
    var min = Complex(-2.5, -1.5)
    var max = Complex(1.5, 1.5)
    var zoom = 1.0

    override class var layerClass: AnyClass { return CATiledLayer.self }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func reset(min: Complex, max: Complex) {
        let layer = self.layer as! CATiledLayer
        layer.tileSize = CGSize(width: sideLength, height: sideLength)
        layer.levelsOfDetail = 2 << maxscale
        layer.levelsOfDetailBias = 2 << maxscale
        layer.delegate = self

        self.min = min
        self.max = max

        // reset the layer
        self.layer.contents = nil;
        self.setNeedsDisplay()
    }

    func rectToComplex(_ rect: CGRect, _ bounds: CGSize) -> (Complex, Complex) {

        let orig = Complex(rect.origin) / Complex(bounds)
        let size = Complex(rect.size) / Complex(bounds)

        let a = mix(min, max, t: orig)
        let b = mix(min, max, t: orig + size)

        return (a, b)
    }

    override func draw(_ layer: CALayer, in ctx: CGContext) {
        let layer = layer as! CATiledLayer

        // min and max to compute
        let rect = ctx.convertToUserSpace(CGRect(origin: CGPoint.zero, size: layer.tileSize))
        let (a, b) = rectToComplex(rect, layer.bounds.size)

        // tile size in pixels (as opposed to points)
        let tilesize = CGSize(width: layer.tileSize.width / layer.contentsScale, height: layer.tileSize.height / layer.contentsScale)

        // back of the envelope max iter computation
        let d = recip(length(b-a))
        let maxiter = 48 * Int(abs(log2(d))+1)

        if let image = mandelbrot(min: a, max: b, size: tilesize, maxiter: maxiter) {
            ctx.draw(image, in: rect)
        }
    }

}

class ViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var label: UILabel!
//    @IBOutlet weak var tileView: TileView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var gestureRecognizer: UITapGestureRecognizer!
    var tileView: TileView!

    override func viewDidLoad() {
        super.viewDidLoad()

        tileView = TileView()
        tileView.translatesAutoresizingMaskIntoConstraints = false
        tileView.frame = scrollView.frame
        scrollView.addSubview(tileView)
        tileView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        tileView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        tileView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor).isActive = true
        tileView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true

        resetZoom()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .landscape }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.tileView
    }

    func updateLabel() {
        let rect = scrollView.convert(scrollView.bounds, to: tileView)
        let (a, b) = tileView.rectToComplex(rect, tileView.bounds.size)
        let s = "\(a), \(b),\(scrollView.zoomScale), \(scrollView.contentOffset), \(tileView.frame)"
        label.text = s
        print(s)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateLabel()
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateLabel()
    }

    func resetZoom(scale: Int = 8) {

        // current rect for the view, scale the size
        let rect = scrollView.convert(scrollView.bounds, to: tileView)
        let bounds = Complex(tileView.layer.bounds.size)

        // scale the rect to the bounds
        let orig = Complex(rect.origin) / bounds
        let size = Complex(rect.size) * Double(1 << scale) / bounds

        // compute the new min max rect
        let origin = orig - size / 4
        let destin = orig - size / 4  + size

        // scale the rect to the view current space
        let min = tileView.min
        let max = tileView.max
        let a = mix(min, max, t: origin)
        let b = mix(min, max, t: destin)

        // set new zoom
        tileView.reset(min: a, max: b)

        // reset scroll view
        scrollView.zoomScale = CGFloat(1 << scale)
        scrollView.contentOffset = CGPoint(x: scrollView.contentSize.width/4, y: scrollView.contentSize.height/4)
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {

        // reset zoom to the middle scale
        let scale = log2(scrollView.zoomScale)
        if scale <= 2 || scale >= 14 {
            resetZoom(scale: 8)
        }
    }

    @IBAction func handleTapGesture(recognizer: UITapGestureRecognizer) {
        let size = scrollView.convert(scrollView.bounds, to: tileView).size
        let point = recognizer.location(in: tileView)
        let rect = CGRect(x: point.x - size.width/4, y: point.y - size.height/4, width: size.width/2, height: size.height/2)
        scrollView.zoom(to: rect, animated: true)
    }

}



