//
//  ImageEditingVC.swift
//  PhotoEditor
//
//  Created by RoH!T on 05/03/21.
//

import UIKit

/// Manae the action event on supper class through delegate
protocol ImageEditingDelegate: class {
    /// Handel dismiss event
    func removeView()
}

/// Manage image for editing
class ImageEditingVC: UIViewController, UIImagePickerControllerDelegate {

    // MARK: - Outlet
    ///
    @IBOutlet weak var capturedImageView: UIImageView!
    ///
    @IBOutlet weak var closeView: UIView!
    ///
    @IBOutlet weak var drawView: UIView!
    ///
    @IBOutlet weak var saveShareView: UIView!
    ///
    @IBOutlet weak var imageBaseView: UIView!
    ///
    @IBOutlet weak var brushButton: UIButton!
    ///
    @IBOutlet weak var colourBaseView: UIView!
    ///
    @IBOutlet weak var colorCollectionView: UICollectionView!
    ///
    @IBOutlet weak var topStackView: UIStackView!
    ///
    @IBOutlet weak var bottomStackView: UIStackView!
    ///
    @IBOutlet weak var undoButton: UIButton!
    
    // MARK: - Variables
    ///
    var captureImage: UIImage? = nil
    ///
    weak var delegate: ImageEditingDelegate?
    /// set selected color
    var colors: String = "ffffff"
    ///
    var isDrawEnable: Bool = false
    /// tempImage
    var tempImageView = UIImageView()
    /// set last point
    var lastPoint = CGPoint.zero
    /// set color value
    var colorValue = Int()
    /// set swiped or not
    var swiped: Bool = false
    ///
    var dataSource: ColourCollectionDataSource?
    ///
    var pinchGesture: UIPinchGestureRecognizer!
    ///
    var brushWidthView = UIView()
    ///
    var lineWidth: CGFloat = 5.0
    ///
    var linePoints: [CGPoint] = []
    ///
    var allPoints: [[CGPoint]] = []
    ///
    var lineColor: [String] = []
    ///
    var lineWidths: [CGFloat] = []
    ///
    var colorValues: [Int] = []
    
    // MARK: - Controller life-cycel
    ///
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    ///
    deinit {
        dataSource = nil
    }
    
    // MARK: - Helper methods
    /// Help to set the view
    func setupUI() {
        undoButton.isHidden = true
        brushWidthView.frame = CGRect(x: 0, y: 0, width: 5, height: 5)
        brushWidthView.backgroundColor = .white
        brushWidthView.layer.cornerRadius = brushWidthView.frame.height / 2
        dataSource = ColourCollectionDataSource.init(withCollectionView: colorCollectionView)
        dataSource?.delegate = self
        closeView.isHidden = false
        drawView.isHidden = true
        saveShareView.isHidden = false
        colourBaseView.isHidden = true
        guard let image = captureImage else { return }
        capturedImageView.image = image
        tempImageView.frame = view.frame
        self.view.addSubview(tempImageView)
        view.addSubview(brushWidthView)
        brushWidthView.isHidden = true
        view.bringSubviewToFront(topStackView)
        view.bringSubviewToFront(bottomStackView)
    }
    
    // MARK: - Touch events
    /// set start point
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawEnable else { return }
        if undoButton.isHidden {
            undoButton.isHidden = false
        }
        swiped = false
        if let touch = touches.first {
            lastPoint = touch.location(in: self.view)
        }
    }
    /// draw on moving area
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawEnable else { return }
        swiped = true
        if let touch = touches.first {
            let currentPoint = touch.location(in: view)
            linePoints.append(currentPoint)
            drawLineFrom(fromPoint: lastPoint, toPoint: currentPoint)
            lastPoint = currentPoint
        }
    }
    /// set end points
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawEnable else { return }
        if !swiped {
            drawLineFrom(fromPoint: lastPoint, toPoint: lastPoint)
            linePoints.append(lastPoint)
        }
        lineColor.append(colors)
        lineWidths.append(lineWidth)
        colorValues.append(colorValue)
        allPoints.append(linePoints)
        linePoints = []
    }
    
    // MARK: - Draw on image
    /// Draw Colour Line on image
    func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint, _ lines: [CGPoint] = []) {
        UIGraphicsBeginImageContext(view.frame.size)
        let context = UIGraphicsGetCurrentContext()
        tempImageView.image?.draw(in: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height))
        context?.move(to: fromPoint)
        context?.addCurve(to: toPoint, control1: toPoint, control2: fromPoint)
        context?.setLineCap(.round)
        context?.setLineWidth(lineWidth)
        if colorValue == 0 {
            context?.setStrokeColor(UIColor(hex: colors).cgColor)
            context?.setBlendMode(.normal)
        } else {
            context?.setBlendMode(.clear)
        }
        context?.strokePath()
        tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        tempImageView.alpha = 1.0
        UIGraphicsEndImageContext()
    }
    
    // MARK: - Pinch gesture action
    
    /// Set the line size view on center of pinch gesture
    /// - Parameter gestureRecognizer: object of UIGestureRecognizer
    func adjustAnchorPoint(for gestureRecognizer: UIGestureRecognizer?) {
        if gestureRecognizer?.state == .began {
            let piece = gestureRecognizer?.view
            let locationInView = gestureRecognizer?.location(in: piece)
            let locationInSuperview = gestureRecognizer?.location(in: piece?.superview)

            piece?.layer.anchorPoint = CGPoint(x: (locationInView?.x ?? 0.0) / (piece?.bounds.size.width ?? 0.0), y: (locationInView?.y ?? 0.0) / (piece?.bounds.size.height ?? 0.0))
            piece?.center = locationInSuperview ?? CGPoint.zero
            brushWidthView.center = piece!.center
        }
    }
    
    /// Help to increase the drawing line width
    /// - Parameter gestureRecognizer: object of UIPinchGestureRecognizer
    @objc func scalePiece(_ gestureRecognizer : UIPinchGestureRecognizer) {
        guard gestureRecognizer.view != nil else { return }
        adjustAnchorPoint(for: gestureRecognizer)
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            brushWidthView.transform = self.brushWidthView.transform.scaledBy(x: gestureRecognizer.scale, y: gestureRecognizer.scale)
            lineWidth = brushWidthView.frame.height
            brushWidthView.isHidden = false
            isDrawEnable = false
            gestureRecognizer.scale = 1.0
        } else if gestureRecognizer.state == .ended {
            brushWidthView.isHidden = true
            isDrawEnable = true
        }
    }
    
    // MARK: - Actions
    
    /// Dismiss self on click of close button
    @IBAction func onCloseTapped(_ sender: Any) {
        delegate?.removeView()
        dismiss(animated: false, completion: nil)
    }
    /// Share image to social platform
    @IBAction func onShareTapped(_ sender: Any) {
        if tempImageView.image != nil {
            topStackView.isHidden = true
            bottomStackView.isHidden = true
            closeView.isHidden = true
            saveShareView.isHidden = true
            let image = imageBaseView.takeScreenshot()
            topStackView.isHidden = false
            bottomStackView.isHidden = false
            closeView.isHidden = false
            saveShareView.isHidden = false
            captureImage = image
        }
        let activityVC = UIActivityViewController(activityItems: [captureImage!], applicationActivities: nil)
        present(activityVC, animated: true, completion: nil)
        if let popOver = activityVC.popoverPresentationController {
            popOver.sourceView = self.view
        }
    }
    /// Save image in photo gallery
    @IBAction func onSaveTapped(_ sender: Any) {
        if tempImageView.image == nil {
            UIImageWriteToSavedPhotosAlbum(captureImage!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        } else {
            UIGraphicsBeginImageContext(self.capturedImageView.frame.size)
            self.capturedImageView.image?.draw(in: CGRect(x: 0, y: 0, width: self.capturedImageView.frame.size.width, height: self.capturedImageView.frame.size.height), blendMode: .normal, alpha: 1.0)
            self.tempImageView.image?.draw(in: CGRect(x: 0, y: 0, width: self.capturedImageView.frame.size.width, height: self.capturedImageView.frame.size.height), blendMode: .normal, alpha: 1.0)
            self.capturedImageView.image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            self.tempImageView.image = nil
            if let image = self.capturedImageView.image {
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
            }
        }
    }
    /// Help to drawing layer on image
    @IBAction func onDrawTapped(_ sender: Any) {
        isDrawEnable = !isDrawEnable
        self.pinchGesture = UIPinchGestureRecognizer(target: self, action:#selector(scalePiece(_:)))
        view.addGestureRecognizer(pinchGesture)
        closeView.isHidden = true
        drawView.isHidden = false
        saveShareView.isHidden = true
        colorCollectionView.reloadData()
        colourBaseView.isHidden = false
    }
    ///
    @IBAction func onSaveDrawingTapped(_ sender: Any) {
        isDrawEnable = !isDrawEnable
        view.removeGestureRecognizer(pinchGesture)
        closeView.isHidden = false
        drawView.isHidden = true
        saveShareView.isHidden = false
        colourBaseView.isHidden = true
    }
    ///
    @IBAction func onBrushTapped(_ sender: Any) {
        colorValue = 0
        view.addGestureRecognizer(pinchGesture)
        brushButton.layer.borderWidth = 2
        brushButton.layer.borderColor = UIColor.black.cgColor
    }
    /// Help to reset drawing layer from image
    @IBAction func onUndoTapped(_ sender: Any) {
        if allPoints.count > 0 {
            allPoints.removeLast()
            lineColor.removeLast()
            lineWidths.removeLast()
            colorValues.removeLast()
            self.tempImageView.image = nil
            var currentIndex = 0
            for lines in allPoints {
                colors = lineColor[currentIndex]
                lineWidth = lineWidths[currentIndex]
                colorValue = colorValues[currentIndex]
                brushWidthView.backgroundColor = UIColor(hex: colors)
                var previousPoint = CGPoint()
                currentIndex += 1
                for index in 0...lines.count - 1 {
                    if index == 0 {
                        previousPoint = lines[index]
                        if lines.count == 1 {
                            drawLineFrom(fromPoint: previousPoint, toPoint: previousPoint)
                        }
                    } else {
                        drawLineFrom(fromPoint: previousPoint, toPoint: lines[index])
                        previousPoint = lines[index]
                    }
                }
            }
            undoButton.isHidden = allPoints.count > 0 ? false : true
        } else {
            self.tempImageView.image = nil
            colorValue = 0
            brushButton.layer.borderWidth = 2
            brushButton.layer.borderColor = UIColor.black.cgColor
        }
    }
    
    /// Handle the save image completion
    /// - Parameters:
    ///   - image: object of UIImage
    ///   - error: objaect of Error
    ///   - contextInfo: objet of UnsafeRawPointer
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let errorAlert = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
            present(errorAlert, animated: true)
        } else {
            var message = "Edited image has been saved to your photo gallary."
            if tempImageView.image == nil {
                message = "Captured/Selected image has been saved to your photo gallary."
            }
            let successAlert = UIAlertController(title: "", message: message, preferredStyle: .alert)
            let okayAction = UIAlertAction(title: "Ok", style: .default) { (_) in
                self.delegate?.removeView()
                self.dismiss(animated: false, completion: nil)
            }
            successAlert.addAction(okayAction)
            present(successAlert, animated: true)
        }
    }
}

// MARK: - ImageEditingVC extension to manage the colour selection callbacks
extension ImageEditingVC: ColorDelegate {
    // MARK: ImageEditingVC extension to manage the colour selection callback methods
    ///
    func onEraserTapped() {
        colorValue = 1
        brushButton.layer.borderWidth = 0
    }
    ///
    func onColorTapped(_ color: String) {
        colorValue = 0
        brushButton.layer.borderWidth = 2
        brushButton.layer.borderColor = UIColor.black.cgColor
        brushWidthView.backgroundColor = UIColor(hex: color)
        colors = color
    }
}
