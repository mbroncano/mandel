//
//  Complex.swift
//  Mandelbrot
//
//  Created by Manuel Broncano on 9/2/17.
//  Copyright © 2017 Manuel Broncano. All rights reserved.
//

import Foundation
import simd
import CoreGraphics

public let 𝒊 = Complex(0, 1)

public typealias Complex = double2

extension Complex {
    init(_ s: CGSize) {
        self = Complex(Double(s.width), Double(s.height))
    }

    var radius: Double {
//        return sqrt(x * x + y * y)
        return length(self)
    }

    var radiusSquare: Double {
//        return x * x + y * y
        return length_squared(self)
    }

    var square: Complex {
        return Complex(x * x - y * y, x * y + y * x)
    }

    public func lerp(min: Complex, max: Complex) -> Complex {
//        return self * (max - min) + min
//        return Complex(x * (max.x - min.x) + min.x, y * (max.y - min.y) + min.y)
        return mix(min, max, t: self)
    }
}
