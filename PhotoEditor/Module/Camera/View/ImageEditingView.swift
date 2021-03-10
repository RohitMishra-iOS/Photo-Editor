//
//  DrawView.swift
//  PhotoEditor
//
//  Created by RoH!T on 10/03/21.
//

import UIKit

/// Helpo handle the view action with controller class
@objc public protocol ImageEditingViewDelegate {
    /// Triggered when user removed his/her drawing
    @objc optional func allPathRemoved()
}

/// Help to draw smooth line on view
class ImageEditingView: UIView {
    // MARK: - Variables
    ///
    var strokeColor = UIColor.white
    ///
    var lineWidth: CGFloat = 5
    ///
    var snapshotImage: UIImage?
    ///
    var colourValue = 0
    ///
    private var path: UIBezierPath?
    ///
    private var temporaryPath: UIBezierPath?
    ///
    private var points = [CGPoint]()
    ///
    open var delegate : ImageEditingViewDelegate?
    ///
    var rectValue = CGRect()
    /// Stores all ımages to get back to last - 1 image. Becase erase last needs this :)
    fileprivate var allImages = Array<UIImage>()

    // MARK: - View draw method
    override func draw(_ rect: CGRect) {
        rectValue = rect
        snapshotImage?.draw(in: rect)
        strokeColor.setStroke()
        path?.stroke(with: colourValue == 1 ? .clear : .normal, alpha: 1.0)
        temporaryPath?.stroke(with: colourValue == 1 ? .clear : .normal, alpha: 1.0)
    }

    // MARK: - touches methods
    ///
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            points = [touch.location(in: self)]
        }
    }
    ///
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)

        points.append(point)

        updatePaths()

        setNeedsDisplay()
    }
    ///
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        finishPath()
    }
    ///
    override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        finishPath()
    }
    
    // MARK: - Helper methods
    
    /// Help to update drawing path
    private func updatePaths() {
        // update main path
        while points.count > 4 {
            points[3] = CGPoint(x: (points[2].x + points[4].x)/2.0, y: (points[2].y + points[4].y)/2.0)

            if path == nil {
                path = createStartingPath(at: points[0])
            }

            path?.addCurve(to: points[3], controlPoint1: points[1], controlPoint2: points[2])

            points.removeFirst(3)

            temporaryPath = nil
        }

        // build temporary path up to last touch point

        if points.count == 2 {
            temporaryPath = createStartingPath(at: points[0])
            temporaryPath?.addLine(to: points[1])
        } else if points.count == 3 {
            temporaryPath = createStartingPath(at: points[0])
            temporaryPath?.addQuadCurve(to: points[2], controlPoint: points[1])
        } else if points.count == 4 {
            temporaryPath = createStartingPath(at: points[0])
            temporaryPath?.addCurve(to: points[3], controlPoint1: points[1], controlPoint2: points[2])
        }
    }
    /// Handle the touchesEnded event
    private func finishPath() {
        constructIncrementalImage()
        path = nil
        allImages.append(snapshotImage!)
        setNeedsDisplay()
    }
    
    /// Help to create starting path of drawing
    /// - Parameter point: object of CGPoint
    /// - Returns: object of UIBezierPath
    private func createStartingPath(at point: CGPoint) -> UIBezierPath {
        let localPath = UIBezierPath()
        localPath.move(to: point)
        localPath.lineWidth = lineWidth
        localPath.lineCapStyle = .round
        localPath.lineJoinStyle = .round
        return localPath
    }

    /// Take a snapshot of draw image
    private func constructIncrementalImage() {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        strokeColor.setStroke()
        snapshotImage?.draw(at: .zero)
        path?.stroke(with: colourValue == 1 ? .clear : .normal, alpha: 1.0)
        temporaryPath?.stroke(with: colourValue == 1 ? .clear : .normal, alpha: 1.0)
        snapshotImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    // MARK: - Help to undo path
    /// Help to creat path at the time of undo
    fileprivate func createPath() {
        path = nil
        path = UIBezierPath()
        path!.lineWidth = lineWidth
    }
    
    /// Erases Last Path
    open func clearLast() {
        if allImages.count == 0 {
            return
        }
        path = nil
        allImages.removeLast()
        if allImages.count == 0 {
            snapshotImage = nil
            colourValue = 0
            strokeColor = .white
            delegate?.allPathRemoved!()
        } else {
            snapshotImage = allImages.last
        }
        createPath()
        setNeedsDisplay()
        path?.removeAllPoints()
        path = nil
        temporaryPath = nil
        setNeedsDisplay()
    }
}
