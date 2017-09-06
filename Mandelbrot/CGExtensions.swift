//
//  CGExtensions.swift
//  Mandelbrot
//
//  Created by Manuel Broncano on 9/6/17.
//  Copyright © 2017 Manuel Broncano. All rights reserved.
//

import CoreGraphics

extension CGPoint: Hashable {
    public var hashValue: Int {
        return x.hashValue << 32 ^ y.hashValue
    }
}

extension CGSize: Hashable {
    public var hashValue: Int {
        return width.hashValue << 32 ^ height.hashValue
    }

    static func *(lhs: CGSize, rhs: CGFloat) -> CGSize {
        return CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }

    static func /(lhs: CGSize, rhs: CGFloat) -> CGSize {
        return CGSize(width: lhs.width / rhs, height: lhs.height / rhs)
    }
}

extension CGRect: Hashable {
    public var hashValue: Int {
        return origin.hashValue << 32 ^ size.hashValue
    }
}

class CacheKey<T> where T: Equatable {
    let value: CGRect

    init(_ value: CGRect) {
        self.value = value
    }

    var hashValue: Int {
        return value.hashValue
    }

    static func ==(lhs: CacheKey<T>, rhs: CacheKey<T>) -> Bool {
        return lhs.value == rhs.value
    }
}
