//: Playground - noun: a place where people can play

import simd

public typealias Complex = double2

extension Complex {

    //! sqrt(x * x + y * y)
    var radius: Double { return length(self) }

    //! x * x + y * y
    var radiusSquare: Double { return length_squared(self) }

    //! self * self
    var square: Complex { return Complex(x * x - y * y, x * y + y * x) }

    //! self * (max - min) + min
    public func lerp(min: Complex, max: Complex) -> Complex {
        return mix(min, max, t: self)
    }
}

var z = Complex()
let c = Complex(-2.5, 0)
let max = 100
var zs = AnyIterator<Complex>{
    z = z.square + c
    return z
    }.prefix(max).enumerated()
print(zs.first { $0.1.radiusSquare >= 256 } ?? (offset: max, element: 1.0))
