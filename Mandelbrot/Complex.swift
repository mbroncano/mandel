//
//  Complex.swift
//  Mandelbrot
//
//  Created by Manuel Broncano on 9/2/17.
//  Copyright © 2017 Manuel Broncano. All rights reserved.
//

import Foundation

public let 𝒊 = Complex(0, 1)

public struct Complex: Equatable, Hashable, CustomStringConvertible, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral, Comparable {
    public static func <(lhs: Complex, rhs: Complex) -> Bool {
        return lhs.x == rhs.x ? (lhs.y < rhs.y) : lhs.x < rhs.x
    }


    /// The real part of the complex number.
    public var x: Double = 0

    /// The imaginary part of the complex number.
    public var y: Double = 0

    public init() {}

}

extension Complex {

    public var real: Double { get { return x } set { x = newValue } }
    public var imaginary: Double { get { return y } set { y = newValue } }

    public init (_ real: Double, _ imagine: Double) {
        self.x = real
        self.y = imagine
    }

    public init (real: Double) {
        self.init(real, 0)
    }

    public init(integerLiteral value: Int) {
        self.init(real: Double(value))
    }

    public init(floatLiteral value: Double) {
        self.init(real: value)
    }

    public init (imagine: Double) {
        self.init(0, imagine)
    }

    public subscript(index: Int) -> Double {
        switch index {
        case 0: return x
        case 1: return y
        default: fatalError("only 0 and 1 are allowed")
        }
    }

    public var radiusSquare: Double { return x * x + y * y }
    public var radius: Double { return sqrt(radiusSquare) }
    public var arg: Double { return atan2(y, x) }

    public var hashValue: Int {
        return x.hashValue &+ y.hashValue
    }

    public var description: String {
        if x != 0 {
            if y > 0 {
                return "\(x)+\(y)𝒊"
            } else if y < 0 {
                return "\(x)-\(-y)𝒊"
            } else {
                return "\(x)"
            }
        } else {
            if y == 0 {
                return "0"
            } else {
                return "\(y)𝒊"
            }
        }
    }

}

public func ==(c1: Complex, c2: Complex) -> Bool {
    return c1.x == c2.x && c1.y == c2.y
}

public extension Complex {


    public func conjugate() -> Complex {
        return Complex(x, -y)
    }


    public func add(_ n: Complex) -> Complex {
        return Complex(x + n.x, y + n.y)
    }


    public func subtract(_ n: Complex) -> Complex {
        return Complex(x - n.x, y - n.y)
    }


    public func multiply(_ n: Double) -> Complex {
        return Complex(x * n, y * n)
    }


    public func multiply(_ n: Complex) -> Complex {
        return Complex(x * n.x - y * n.y, x * n.y + y * n.x)
    }


    public func divide(_ n: Complex) -> Complex {
        return self.multiply((n.conjugate().divide(n.radiusSquare)))
    }


    public func divide(_ n: Double) -> Complex {
        return Complex(x / n, y / n)
    }


    public func power(_ n: Double) -> Complex {
        return pow(radiusSquare, n / 2) * Complex(cos(n * arg), sin(n * arg))
    }


    public func power(_ n: Int) -> Complex {
        switch n {
        case 0: return 1
        case 1: return self
        case -1: return Complex(real: 1).divide(self)
        case 2: return self.multiply(self)
        case -2: return Complex(real: 1).divide(self.multiply(self))
        default: return power(Double(n))
        }
    }

    public mutating func conjugateInPlace() {
        y = -y
    }

    public mutating func addInPlace(_ n: Complex) {
        x += n.x
        y += n.y
    }

    public mutating func subtractInPlace(_ n: Complex) {
        x -= n.x
        y -= n.y
    }

    public mutating func multiplyInPlace(_ n: Double) {
        x *= n
        y *= n
    }

    public mutating func multiplyInPlace(_ n: Complex) {
        self = self.multiply(n)
    }

    public mutating func divideInPlace(_ n: Complex) {
        self = self.divide(n)
    }

    public mutating func divideInPlace(_ n: Double) {
        x /= n
        y /= n
    }

    public func lerp(min: Complex, max: Complex) -> Complex {
        return Complex(x * (max.x - min.x) + min.x, y * (max.y - min.y) + min.y)
    }

}

precedencegroup PowerPrecedence {
    higherThan: MultiplicationPrecedence
    associativity: left
    assignment: false
}

infix operator ^ : PowerPrecedence
infix operator * : MultiplicationPrecedence
infix operator / : MultiplicationPrecedence
infix operator + : AdditionPrecedence
infix operator - : AdditionPrecedence

infix operator += : AssignmentPrecedence
infix operator -= : AssignmentPrecedence
infix operator *= : AssignmentPrecedence
infix operator /= : AssignmentPrecedence

prefix operator ∠
infix operator ∠ : AdditionPrecedence

public func + (c1: Complex, c2: Complex) -> Complex { return c1.add(c2) }
public func + (c1: Double,  c2: Complex) -> Complex { return Complex(real: c1).add(c2) }
public func + (c1: Complex, c2: Double ) -> Complex { return c1.add(Complex(real: c2)) }

public func - (c1: Complex, c2: Complex) -> Complex { return c1.subtract(c2) }
public func - (c1: Double,  c2: Complex) -> Complex { return Complex(real: c1).subtract(c2) }
public func - (c1: Complex, c2: Double ) -> Complex { return c1.subtract(Complex(real: c2)) }

public func * (c1: Complex, c2: Complex) -> Complex { return c1.multiply(c2) }
public func * (c1: Double,  c2: Complex) -> Complex { return c2.multiply(c1) }
public func * (c1: Complex, c2: Double ) -> Complex { return c1.multiply(c2) }

public func / (c1: Complex, c2: Complex) -> Complex { return c1.divide(c2) }
public func / (c1: Double,  c2: Complex) -> Complex { return Complex(real: c1).divide(c2) }
public func / (c1: Complex, c2: Double ) -> Complex { return c1.divide(c2) }

public func ^ (c1: Complex, n: Double) -> Complex { return c1.power(n) }
public func ^ (c1: Complex, n: Int) -> Complex { return c1.power(n) }

public func += (c1: inout Complex, c2: Complex) { c1.addInPlace(c2) }
public func += (c1: inout Complex, c2: Double) { c1.addInPlace(Complex(real: c2)) }
public func -= (c1: inout Complex, c2: Complex) { c1.subtractInPlace(c2) }
public func -= (c1: inout Complex, c2: Double) { c1.subtractInPlace(Complex(real: c2)) }
public func *= (c1: inout Complex, c2: Complex) { c1.multiplyInPlace(c2) }
public func *= (c1: inout Complex, c2: Double) { c1.multiplyInPlace(c2) }
public func /= (c1: inout Complex, c2: Complex) { c1.divideInPlace(c2) }
public func /= (c1: inout Complex, c2: Double) { c1.divideInPlace(c2) }

public prefix func ∠ (arg: Double) -> Complex { return cos(arg) + sin(arg) * 𝒊 }
public func ∠ (radius: Double, arg: Double) -> Complex { return ∠arg * radius }

