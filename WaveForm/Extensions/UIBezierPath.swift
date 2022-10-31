//
//  UIBezierPath.swift
//  WaveForm
//
//  Created by David Kyslenko on 31.10.2022.
//

import UIKit

extension UIBezierPath {
    static func curvedPaths(points: [CGPoint], in bounds: CGRect) -> UIBezierPath {
        let bezierPath = UIBezierPath()
        let config = BezierConfiguration()
        let controlPoints = config.configureControlPoints(data: points)
        for i in 0..<points.count {
            let point = points[i]
            if i == 0 {
                bezierPath.move(to: point)
            } else {
                let segment = controlPoints[i - 1]
                bezierPath.addCurve(to: point, controlPoint1: segment.firstControlPoint, controlPoint2: segment.secondControlPoint)
            }
        }

        return bezierPath
    }

    static func linearPaths(points: [CGPoint]) -> UIBezierPath {
        let bezierPath = UIBezierPath()
        for i in 0..<points.count {
            let point = points[i]
            if i == 0 {
                bezierPath.move(to: point)
            } else {
                bezierPath.addLine(to: point)
            }
        }
        bezierPath.close()
        return bezierPath
    }

    func generateSmoothPoints(capacity: Int = 1000) -> [CGPoint] {
        let points = cgPath.points()
        var lookupTable = [CGPoint]()
        var previousPoint: CGPoint?
        let piecesCount = points.count
        guard piecesCount > 0 else {
            return []
        }
        let capacityPerPiece = capacity / piecesCount
        for command in points {
            let endPoint = command.point
            guard let startPoint = previousPoint else {
                previousPoint = endPoint
                continue
            }
            switch command.type {
            case .addLineToPoint:
                // Line
                for i in 0...capacityPerPiece {
                    let t = CGFloat(i) / CGFloat(capacityPerPiece)
                    let point = calculateLinear(t: t, p1: startPoint, p2: endPoint)
                    lookupTable.append(point)
                }
            case .addQuadCurveToPoint:
                // Quad curve
                for i in 0...capacityPerPiece {
                    let t = CGFloat(i) / CGFloat(capacityPerPiece)
                    let point = calculateQuad(t: t, p1: startPoint, p2: command.controlPoints[0], p3: endPoint)
                    lookupTable.append(point)
                }
            case .addCurveToPoint:
                // Cube curve
                for i in 0...capacityPerPiece {
                    let t = CGFloat(i) / CGFloat(capacityPerPiece)
                    let point = calculateCube(t: t, p1: startPoint, p2: command.controlPoints[0], p3: command.controlPoints[1], p4: endPoint)
                    lookupTable.append(point)
                }
            default:
                break
            }
            previousPoint = endPoint
        }
        return lookupTable
    }

    /// Calculates a point at given t value, where t in 0.0...1.0
    private func calculateLinear(t: CGFloat, p1: CGPoint, p2: CGPoint) -> CGPoint {
        let mt = 1 - t
        let x = mt * p1.x + t * p2.x
        let y = mt * p1.y + t * p2.y
        return CGPoint(x: x, y: y)
    }

    /// Calculates a point at given t value, where t in 0.0...1.0
    private func calculateCube(t: CGFloat, p1: CGPoint, p2: CGPoint, p3: CGPoint, p4: CGPoint) -> CGPoint {
        let mt = 1 - t
        let mt2 = mt * mt
        let t2 = t * t

        let a = mt2 * mt
        let b = mt2 * t * 3
        let c = mt * t2 * 3
        let d = t * t2

        let x = a * p1.x + b * p2.x + c * p3.x + d * p4.x
        let y = a * p1.y + b * p2.y + c * p3.y + d * p4.y
        return CGPoint(x: x, y: y)
    }

    /// Calculates a point at given t value, where t in 0.0...1.0
    private func calculateQuad(t: CGFloat, p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGPoint {
        let mt = 1 - t
        let mt2 = mt * mt
        let t2 = t * t

        let a = mt2
        let b = mt * t * 2
        let c = t2

        let x = a * p1.x + b * p2.x + c * p3.x
        let y = a * p1.y + b * p2.y + c * p3.y
        return CGPoint(x: x, y: y)
    }

    /// Finds the closest `t` value on path for a given point.
    ///
    /// - Parameter fromPoint: A given point
    /// - Returns: The closest point on the path within the lookup table.
    func findClosestPointOnPath(fromPoint: CGPoint, in lookupPoints: [CGPoint], maxDistance: CGFloat = 100) -> CGPoint? {
        let end = lookupPoints.count
        var dd = distance(fromPoint: fromPoint, toPoint: lookupPoints.first!)
        var d: CGFloat = 0
        var f = 0
        for i in 1..<end {
            d = distance(fromPoint: fromPoint, toPoint: lookupPoints[i])
            if d < dd {
                f = i
                dd = d
            }
        }

        let lookedupPoint = lookupPoints[f]

        let distance = distance(fromPoint: fromPoint, toPoint: lookedupPoint)

        guard distance < maxDistance else { return nil }

        return lookedupPoint
    }

    // MARK: - Calculations

    /// Calculates distance between two values.
    private func distance(fromPoint: CGPoint, toPoint: CGPoint) -> CGFloat {
        let xDist = Float(fromPoint.x - toPoint.x)
        let yDist = Float(fromPoint.y - toPoint.y)
        return CGFloat(hypotf(xDist, yDist))
    }
}
