//
//  ViewController.swift
//  Mandelbrot
//
//  Created by Manuel Broncano on 9/2/17.
//  Copyright © 2017 Manuel Broncano. All rights reserved.
//

import UIKit
import CoreGraphics

class TileView: UIView {
    let sideLength = 256
    let maxScale = 2 << 16

    override class var layerClass: AnyClass {
        return MandelLayer.self
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let layer = self.layer as! MandelLayer
        layer.tileSize = CGSize(width: sideLength, height: sideLength)
        layer.levelsOfDetail = maxScale
        layer.levelsOfDetailBias = maxScale
    }
}

class ViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var tileView: TileView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet var gestureRecognizer: UITapGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.maximumZoomScale = CGFloat(self.tileView.maxScale)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.tileView
    }

    @IBAction func handleTapGesture(recognizer: UITapGestureRecognizer) {
        let size = scrollView.convert(scrollView.bounds, to: tileView).size
        let point = recognizer.location(in: tileView)
        let rect = CGRect(x: point.x - size.width/4, y: point.y - size.height/4, width: size.width/2, height: size.height/2)
        scrollView.zoom(to: rect, animated: true)
    }

}



