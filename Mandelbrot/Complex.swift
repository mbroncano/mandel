//
//  Complex.swift
//  Mandelbrot
//
//  Created by Manuel Broncano on 9/2/17.
//  Copyright © 2017 Manuel Broncano. All rights reserved.
//

import simd
import CoreGraphics

public typealias Complex = double2

extension Complex {

    init(_ size: CGSize) {
        self.init(x: Double(size.width), y: Double(size.height))
    }

    init(_ point: CGPoint) {
        self.init(x: Double(point.x), y: Double(point.y))
    }

    //! sqrt(x * x + y * y)
    var radius: Double { return length(self) }

    //! x * x + y * y
    var radiusSquare: Double { return length_squared(self) }

    //! self * self
    // (a+bi)(c+di) = ac+ad*i+bc*i+bd*i^2 [i^2=-1,a=c,b=d], a^2-b^2+2ab*i
    var square: Complex { return Complex(x * x - y * y, 2 * x * y) }

    //! self * (max - min) + min
    public func lerp(min: Complex, max: Complex) -> Complex {
        return mix(min, max, t: self)
    }
}
