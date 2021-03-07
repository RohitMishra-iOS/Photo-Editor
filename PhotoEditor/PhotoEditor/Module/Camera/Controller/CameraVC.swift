//
//  CameraVC.swift
//  PhotoEditor
//
//  Created by RoH!T on 04/03/21.
//

import UIKit
import AVFoundation
import Photos

/// Manage the camara action view
class CameraVC: UIViewController {
    
    // MARK: - Outlets
    /// Managed all option related to camera
    @IBOutlet weak var cameraOptionMainView: UIView!
    /// Capture transparent circle view
    @IBOutlet weak var captureBaseView: UIView!
    /// Capture white field circle view
    @IBOutlet weak var captureFielddView: UIView!
    /// Rotet camera front and back side
    @IBOutlet weak var cameraRotetButton: UIButton!
    /// Set flash light while capturing photo
    @IBOutlet weak var flashButton: UIButton!
    /// Help to open gallary view
    @IBOutlet weak var selectImageButton: UIButton!
    ///
    @IBOutlet weak var selectImageView: UIImageView!
    
    // MARK: - Variables
    ///
    var captureSession : AVCaptureSession?
    ///
    var stillImageOutput: AVCapturePhotoOutput?
    ///
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    ///
    var isFronCamera: Bool = false
    ///
    var isFlashOn: Bool = false
    ///
    var images: [UIImage] = []
    ///
    var imagePicker = UIImagePickerController()
    
    // MARK: - Controller life-cycle
    ///
    override func viewDidLoad() {
        super.viewDidLoad()
        checkCamera()
    }
    ///
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.captureSession?.stopRunning()
    }
    
    // MARK: - Helper methods
    /// Help to check user authorized camera permision or not
    func checkCamera() {
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            setupCameraUI()
            checkPhotoLibraryPermission()
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                if granted {
                    DispatchQueue.main.async {
                        self.setupCameraUI()
                        self.checkPhotoLibraryPermission()
                    }
                } else {
                    self.alertPromptToAllowCameraPhotoAccessViaSetting("Camera access required for capturing photos!", true)
                }
            })
        }
    }
    /// shows alert if user denied camera/photo permission
    func alertPromptToAllowCameraPhotoAccessViaSetting(_ message: String, _ isFromCamera: Bool = false) {
        let alert = UIAlertController(title: "IMPORTANT", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(okAction)
        let settingsAction = UIAlertAction(title: "Settings", style: .default, handler: { _ in
            // Take the user to Settings app to possibly change permission.
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        if isFromCamera {
                            self.checkCamera()
                        } else {
                            self.checkPhotoLibraryPermission()
                        }
                    })
                } else {
                    UIApplication.shared.openURL(settingsUrl)
                }
            }
        })
        alert.addAction(settingsAction)
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    /// Check user give photo library access or not
    func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            DispatchQueue.main.async {
                self.fetchPhotos()
            }
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                switch status {
                case .authorized:
                    DispatchQueue.main.async {
                        self.fetchPhotos()
                    }
                default:
                    self.alertPromptToAllowCameraPhotoAccessViaSetting("Photo access required for edit your selected photos!")
                }
            }
        default:
            alertPromptToAllowCameraPhotoAccessViaSetting("Photo access required for edit your selected photos!")
        }
    }
    /// Setup camera priview UI
    func setupCameraUI(_ cameraPosition: AVCaptureDevice.Position = .back) {
        self.view.backgroundColor = .black
        self.cameraRotetButton.addShadow()
        self.flashButton.addShadow()
        self.selectImageButton.addShadow()
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = AVCaptureSession.Preset.photo
        isFronCamera = cameraPosition == .front ? true : false
        guard let cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition) else {
            print("Unable to access back camera!")
            return
        }
        var error: NSError?
        var input: AVCaptureDeviceInput!
        do {
            try cameraDevice.lockForConfiguration()
            input = try AVCaptureDeviceInput(device: cameraDevice)
            stillImageOutput = AVCapturePhotoOutput()
            if captureSession!.canAddInput(input) && ((captureSession?.canAddOutput(stillImageOutput ?? AVCapturePhotoOutput())) != nil) {
                captureSession?.addInput(input)
                captureSession?.addOutput(stillImageOutput ?? AVCapturePhotoOutput())
                setupLivePreview()
            }
        } catch let error1 as NSError {
            error = error1
            input = nil
            print(error!.localizedDescription)
        }
    }
    
    /// Setup camera preview Using AVFoundation
    func setupLivePreview() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession ?? AVCaptureSession())
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        videoPreviewLayer?.connection?.videoOrientation = .portrait
        videoPreviewLayer?.name = "CameraLayer"
        view.layer.insertSublayer(videoPreviewLayer ?? AVCaptureVideoPreviewLayer(), at: 0)
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.startRunning()
            DispatchQueue.main.async {
                self.videoPreviewLayer?.frame = self.view.layer.frame
            }
        }
    }
    
    /// Help to present Image editing view
    /// - Parameter selectedImage: captured or selected image
    func presentImageEditingView(_ selectedImage: UIImage) {
        let imageEditingVC = self.storyboard?.instantiateViewController(identifier: "ImageEditingVC") as! ImageEditingVC
        imageEditingVC.delegate = self
        imageEditingVC.modalPresentationStyle = .currentContext
        imageEditingVC.captureImage = selectedImage
        self.present(imageEditingVC, animated: false, completion: nil)
    }
    
    // MARK: - Actions
    /// Handle the photo capture event
    @IBAction func onPhotoCaptureTapped(_ sender: Any) {
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        settings.flashMode = isFlashOn ? .on : .off
        stillImageOutput?.capturePhoto(with: settings, delegate: self)
    }
    ///
    @IBAction func onCameraRotetTapped(_ sender: Any) {
        videoPreviewLayer?.removeFromSuperlayer()
        setupCameraUI(isFronCamera ? .back : .front)
    }
    ///
    @IBAction func onFlashTapped(_ sender: UIButton) {
        isFlashOn = !isFlashOn
        let flashImage: UIImage = isFlashOn ? UIImage.init(named: "ic_flash_on")! : UIImage.init(named: "ic_flash_off")!
        sender.setImage(flashImage, for: .normal)
    }
    ///
    @IBAction func onOpenGalleryTapped(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            print("Button capture")
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = false
            present(imagePicker, animated: true, completion: nil)
        }
    }
}

// MARK: - CameraVC extension to manage the AVCapturePhotoCapture Delegate callback
extension CameraVC: AVCapturePhotoCaptureDelegate {
    // MARK: CameraVC extension to manage the AVCapturePhotoCapture Delegate callback method
    ///
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        guard let capturedImage = UIImage(data: imageData) else { return }
        presentImageEditingView(capturedImage)
    }
}

// MARK: - CameraVC extension to manage he UIImagePickerController & UINavigationController Delegate callbacks
extension CameraVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // MARK: CameraVC extension to manage he UIImagePickerController & UINavigationController Delegate callback methods
    ///
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var image = UIImage()
        if let pickedImage = info[UIImagePickerController.InfoKey(rawValue: UIImagePickerController.InfoKey.originalImage.rawValue)] as? UIImage {
            image = pickedImage
        }
        dismiss(animated: true) {
            self.presentImageEditingView(image)
        }
    }
    ///
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion:nil)
    }
}
// MARK: - CameraVC extension to manag the ImageEditing Delegate callback
extension CameraVC: ImageEditingDelegate {
    // MARK: CameraVC extension to manag the ImageEditing Delegate callback method
    ///
    func removeView() {
        fetchPhotos()
        captureSession?.startRunning()
    }
}

// MARK: - Extension of CameraVC to get the lattest photo from photo gallery
extension CameraVC {
    // MARK: Extension of CameraVC to get the lattest photo from photo gallery methods
    
    /// Fetch the photo from gallery using PHFetchOptions
    func fetchPhotos () {
        images.removeAll()
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1
        
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)
        
        if fetchResult.count > 0 {
            let totalImageCountNeeded = 1
            fetchPhotoAtIndex(0, totalImageCountNeeded, fetchResult)
        }
    }
    
    /// Help to fetch photo from given index
    /// - Parameters:
    ///   - index: index of photo
    ///   - totalImageCountNeeded: number of photo you want
    ///   - fetchResult: result of image fetch
    func fetchPhotoAtIndex(_ index:Int, _ totalImageCountNeeded: Int, _ fetchResult: PHFetchResult<PHAsset>) {
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        // Perform the image request
        PHImageManager.default().requestImage(for: fetchResult.object(at: index) as PHAsset, targetSize: CGSize(width: 30, height: 30), contentMode: PHImageContentMode.aspectFill, options: requestOptions, resultHandler: { (image, _) in
            if let image = image {
                self.images += [image]
            }
            if index + 1 < fetchResult.count && self.images.count < totalImageCountNeeded {
                self.fetchPhotoAtIndex(index + 1, totalImageCountNeeded, fetchResult)
            } else {
                self.selectImageView.image = self.images[0]
            }
        })
    }
}
