//
//  Interpol.swift
//  Mandelbrot
//
//  Created by Manuel Broncano on 9/3/17.
//  Copyright © 2017 Manuel Broncano. All rights reserved.
//

import Foundation

func createInterpolant(xs: [Double], ys: [Double]) -> (Double) -> Double {
    let length = xs.count

    // deal with length issues
    guard length == ys.count, length > 0 else { return { _ in 0 } }
    guard length > 1 else { return { _ in ys[0] } }

    // rearrange xs and ys so that xs is sorted
    let sorted = zip(xs, ys).sorted { a, b in a.0 < b.0 }
    let xs = sorted.map { $0.0 }
    let ys = sorted.map { $0.1 }

    // get consecutive differences and slopes
    let dys = zip(ys.dropFirst(), ys.dropLast()).map(-)
    let dxs = zip(xs.dropFirst(), xs.dropLast()).map(-)
    let ms = zip(dys, dxs).map(/)

    // get degree-1 coefficients
    let aux1 = zip(ms.dropFirst(), ms.dropLast())
    let aux2 = zip(dxs.dropFirst(), dxs.dropLast())
    let aux3 = zip(aux1, aux2).map { p -> Double in
        let ((mi, mi1), (di, di1)) = p
        if (mi * mi1 <= 0) {
            return 0
        } else {
            let c = di + di1
            return 3 * c / ((c + di1) / mi + (c + di) / mi1)
        }
    }
    let c1s = [ms.first!] + aux3 + [ms.last!]

    // get degree-2 and degree-3 coefficients
    let aux4 = zip(c1s.dropFirst(), c1s.dropLast())
    let aux5 = zip(dxs, ms)
    let aux6 = zip(aux4, aux5).map { p -> (Double, Double) in
        let ((ci1, ci), (di, mi)) = p
        let invDx = 1.0 / di;
        let common = ci + ci1 - mi - mi;
        return ((mi - ci - common) * invDx, common * invDx * invDx)
    }
    let c2s = aux6.map { $0.0 }
    let c3s = aux6.map { $0.1 }

    // Return interpolant function
    return { x in
        // The rightmost point in the dataset should give an exact result
        let len = xs.count - 1;
        guard x != xs[len] else { return ys[len] }

        // Search for the interval x is in, returning the corresponding y if x is one of the original xs
        let ofs = xs.binarySearch { $0 <= x }
        let i = min(ofs, len) - 1

        // Interpolate
        let diff = x - xs[i]
        let diffSq = diff*diff
        return ys[i] + c1s[i]*diff + c2s[i]*diffSq + c3s[i]*diff*diffSq
    }
}

func createInterpolant2(xs: [Double], ys: [[Double]]) -> (Double) -> [Double] {
    let length = xs.count

    // deal with length issues
    guard length == ys.count, length > 0 else { return { _ in [] } }
    guard length > 1 else { return { _ in ys[0] } }

    // rearrange xs and ys so that xs is sorted
    let sorted = zip(xs, ys).sorted { a, b in a.0 < b.0 }
    let xs = sorted.map { $0.0 }
    let ys = sorted.map { $0.1 }

    // get consecutive differences and slopes
    let dys = zip(ys.dropFirst(), ys.dropLast()).map { zip($0.0, $0.1).map(-) }
    let dxs = zip(xs.dropFirst(), xs.dropLast()).map(-)
    let ms = zip(dys, dxs).map({ p -> [Double] in
        let (dy, dx) = p
        return dy.map{ $0 / dx }
    })

    // get degree-1 coefficients
    let aux1 = zip(ms.dropFirst(), ms.dropLast())
    let aux2 = zip(dxs.dropFirst(), dxs.dropLast())
    let aux3 = zip(aux1, aux2).map { p -> [Double] in
        let ((mi, mi1), (di, di1)) = p
        return zip(mi, mi1).map { q -> Double in
            let (mi, mi1) = q
            if (mi * mi1 <= 0) {
                return 0
            } else {
                let c = di + di1
                return 3 * c / ((c + di1) / mi + (c + di) / mi1)
            }
        }
    }
    let c1s = [ms.first!] + aux3 + [ms.last!]

    // get degree-2 and degree-3 coefficients
    let aux4 = zip(c1s.dropFirst(), c1s.dropLast())
    let aux5 = zip(dxs, ms)
    let aux6 = zip(aux4, aux5).map { p -> [(Double, Double)] in
        let ((ci1, ci), (di, mi)) = p
        let invDx = 1.0 / di;
        return zip(ci1, ci, mi).map { q -> (Double, Double) in
            let (ci1, ci, mi) = q
            let common = ci + ci1 - mi - mi;
            return ((mi - ci - common) * invDx, common * invDx * invDx)
        }
    }
    let c2s = aux6.map { $0.map { $0.0 } }
    let c3s = aux6.map { $0.map { $0.1 } }

    let zips = c3s.enumerated().map { p -> IteratorSequence<Zip4Generator<IndexingIterator<Array<Double>>, IndexingIterator<Array<Double>>, IndexingIterator<Array<Double>>, IndexingIterator<Array<Double>>>> in
        let (i, _) = p
        return zip(ys[i], c1s[i], c2s[i], c3s[i])
    }

    // Return interpolant function
    return { x in
        // The rightmost point in the dataset should give an exact result
        let len = xs.count - 1;
        guard x != xs[len] else { return ys[len] }

        // Search for the interval x is in, returning the corresponding y if x is one of the original xs
        let ofs = xs.binarySearch { $0 <= x }
        let i = min(ofs, len) - 1

        // Interpolate
        let diff = x - xs[i]
        let diffSq = diff*diff
        return zips[i].map { p in
            let (ys, c1s, c2s, c3s) = p
            return ys + c1s*diff + c2s*diffSq + c3s*diff*diffSq
        }
    }
}

func createInterpolant3(xs: [Double], ys: [[Double]]) -> (Double) -> [Double] {
    return { x in
        // The rightmost point in the dataset should give an exact result
        let len = xs.count - 1;
        guard x != xs[len] else { return ys[len] }

        // Search for the interval x is in, returning the corresponding y if x is one of the original xs
        let ofs = xs.binarySearch { $0 <= x }
        let i = min(ofs, len) - 1

        return zip(ys[i], ys[i+1]).map { a, b in
            x * (b - a) + a
        }
    }
}

extension Collection {
    /// Finds such index N that predicate is true for all elements up to
    /// but not including the index N, and is false for all elements
    /// starting with index N.
    /// Behavior is undefined if there is no such N.
    func binarySearch(predicate: (Iterator.Element) -> Bool) -> Index {
        var low = startIndex
        var high = endIndex
        while low != high {
            let mid = index(low, offsetBy: distance(from: low, to: high)/2)
            if predicate(self[mid]) {
                low = index(after: mid)
            } else {
                high = mid
            }
        }
        return low
    }
}

struct Zip3Generator<A: IteratorProtocol, B: IteratorProtocol, C: IteratorProtocol>: IteratorProtocol {

    private var first: A
    private var second: B
    private var third: C

    private var index = 0

    init(_ first: A, _ second: B, _ third: C) {
        self.first = first
        self.second = second
        self.third = third
    }

    mutating func next() -> (A.Element, B.Element, C.Element)? { // swiftlint:disable:this large_tuple
        if let a = first.next(), let b = second.next(), let c = third.next() {
            return (a, b, c)
        }
        return nil
    }
}

fileprivate func zip<A: Sequence, B: Sequence, C: Sequence>(_ a: A,_ b: B,_ c: C) -> IteratorSequence<Zip3Generator<A.Iterator, B.Iterator, C.Iterator>> {
    return IteratorSequence(Zip3Generator(a.makeIterator(), b.makeIterator(), c.makeIterator()))
}

struct Zip4Generator<A: IteratorProtocol, B: IteratorProtocol, C: IteratorProtocol, D: IteratorProtocol>: IteratorProtocol {

    private var first: A
    private var second: B
    private var third: C
    private var fourth: D

    private var index = 0

    init(_ first: A, _ second: B, _ third: C, _ fourth: D) {
        self.first = first
        self.second = second
        self.third = third
        self.fourth = fourth
    }

    mutating func next() -> (A.Element, B.Element, C.Element, D.Element)? { // swiftlint:disable:this large_tuple
        if let a = first.next(), let b = second.next(), let c = third.next(), let d = fourth.next() {
            return (a, b, c, d)
        }
        return nil
    }
}

fileprivate func zip<A: Sequence, B: Sequence, C: Sequence, D: Sequence>(_ a: A,_ b: B,_ c: C,_ d: D) -> IteratorSequence<Zip4Generator<A.Iterator, B.Iterator, C.Iterator, D.Iterator>> {
    return IteratorSequence(Zip4Generator(a.makeIterator(), b.makeIterator(), c.makeIterator(), d.makeIterator()))
}
