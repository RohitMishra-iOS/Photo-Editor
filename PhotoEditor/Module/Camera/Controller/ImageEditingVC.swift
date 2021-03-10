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
    var appName = Bundle.main.infoDictionary?["CFBundleName"] as? String
    ///
    var captureImage: UIImage? = nil
    ///
    weak var delegate: ImageEditingDelegate?
    /// set selected color
    var colors: String = "ffffff"
    ///
    var isDrawEnable: Bool = false
    ///
    var editingView = ImageEditingView()
    /// set color value
    var colorValue = Int()
    ///
    var dataSource: ColourCollectionDataSource?
    ///
    var pinchGesture: UIPinchGestureRecognizer!
    ///
    var brushWidthView = UIView()
    ///
    var lineWidth: CGFloat = 5.0
    
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
        undoButton.isHidden = false
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
        editingView.delegate = self
        editingView.frame = view.frame
        editingView.backgroundColor = .clear
        view.addSubview(brushWidthView)
        brushWidthView.isHidden = true
    }

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
            editingView.lineWidth = lineWidth
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
        var tempImage: UIImage?
        if editingView.snapshotImage != nil {
            UIGraphicsBeginImageContext(self.capturedImageView.frame.size)
            self.capturedImageView.image?.draw(in: CGRect(x: 0, y: 0, width: self.capturedImageView.frame.size.width, height: self.capturedImageView.frame.size.height), blendMode: .normal, alpha: 1.0)
            self.editingView.snapshotImage?.draw(in: CGRect(x: 0, y: 0, width: self.capturedImageView.frame.size.width, height: self.capturedImageView.frame.size.height), blendMode: .normal, alpha: 1.0)
            self.capturedImageView.image = UIGraphicsGetImageFromCurrentImageContext()
            self.editingView.isHidden = true
            UIGraphicsEndImageContext()
            tempImage = self.capturedImageView.takeScreenshot()
            self.capturedImageView.image = captureImage
            self.editingView.isHidden = false
        }
        if tempImage == nil {
            tempImage = captureImage
        }
        let activityVC = UIActivityViewController(activityItems: [tempImage!], applicationActivities: nil)
        present(activityVC, animated: true, completion: nil)
        if let popOver = activityVC.popoverPresentationController {
            popOver.sourceView = self.view
        }
    }
    /// Save image in photo gallery
    @IBAction func onSaveTapped(_ sender: Any) {
        if editingView.snapshotImage == nil {
            UIImageWriteToSavedPhotosAlbum(captureImage!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        } else {
            UIGraphicsBeginImageContext(self.capturedImageView.frame.size)
            self.capturedImageView.image?.draw(in: CGRect(x: 0, y: 0, width: self.capturedImageView.frame.size.width, height: self.capturedImageView.frame.size.height), blendMode: .normal, alpha: 1.0)
            self.editingView.snapshotImage?.draw(in: CGRect(x: 0, y: 0, width: self.capturedImageView.frame.size.width, height: self.capturedImageView.frame.size.height), blendMode: .normal, alpha: 1.0)
            self.capturedImageView.image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            self.editingView.isHidden = true
            self.editingView.snapshotImage = nil
            self.editingView.removeFromSuperview()
            if let image = self.capturedImageView.image {
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
            }
        }
    }
    /// Help to drawing layer on image
    @IBAction func onDrawTapped(_ sender: Any) {
        isDrawEnable = !isDrawEnable
        editingView.isUserInteractionEnabled = true
        self.view.addSubview(editingView)
        self.pinchGesture = UIPinchGestureRecognizer(target: self, action:#selector(scalePiece(_:)))
        view.addGestureRecognizer(pinchGesture)
        closeView.isHidden = true
        drawView.isHidden = false
        saveShareView.isHidden = true
        colorCollectionView.reloadData()
        colourBaseView.isHidden = false
        view.bringSubviewToFront(topStackView)
        view.bringSubviewToFront(bottomStackView)
    }
    ///
    @IBAction func onSaveDrawingTapped(_ sender: Any) {
        isDrawEnable = !isDrawEnable
        editingView.isUserInteractionEnabled = false
        view.removeGestureRecognizer(pinchGesture)
        closeView.isHidden = false
        drawView.isHidden = true
        saveShareView.isHidden = false
        colourBaseView.isHidden = true
    }
    ///
    @IBAction func onBrushTapped(_ sender: Any) {
        colorValue = 0
        editingView.colourValue = colorValue
        view.addGestureRecognizer(pinchGesture)
        brushButton.layer.borderWidth = 2
        brushButton.layer.borderColor = UIColor.black.cgColor
    }
    /// Help to reset drawing layer from image
    @IBAction func onUndoTapped(_ sender: Any) {
        editingView.clearLast()
    }
    
    /// Handle the save image completion
    /// - Parameters:
    ///   - image: object of UIImage
    ///   - error: objaect of Error
    ///   - contextInfo: objet of UnsafeRawPointer
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let errorAlert = UIAlertController(title: appName, message: error.localizedDescription, preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
            present(errorAlert, animated: true)
        } else {
            let message = "Captured/Selected image has been saved to your photo gallary."
            let successAlert = UIAlertController(title: appName, message: message, preferredStyle: .alert)
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
        editingView.colourValue = colorValue
        editingView.strokeColor = .clear//UIColor(patternImage: captureImage!)
        brushButton.layer.borderWidth = 0
    }
    ///
    func onColorTapped(_ color: String) {
        colorValue = 0
        editingView.colourValue = colorValue
        brushButton.layer.borderWidth = 2
        brushButton.layer.borderColor = UIColor.black.cgColor
        brushWidthView.backgroundColor = UIColor(hex: color)
        colors = color
        editingView.strokeColor = UIColor(hex: color)
    }
}

// MARK: - ImageEditingVC extension to manage the SmoothCurvedLinesView Delegate callbacks
extension ImageEditingVC: ImageEditingViewDelegate {
    // MARK: ImageEditingVC extension to manage the SmoothCurvedLinesView Delegate callback method
    ///
    func allPathRemoved() {
        colorValue = 0
        editingView.colourValue = colorValue
        brushButton.layer.borderWidth = 2
        brushButton.layer.borderColor = UIColor.black.cgColor
        brushWidthView.backgroundColor = .white
        editingView.strokeColor = .white
    }
}
