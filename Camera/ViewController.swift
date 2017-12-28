//
//  ViewController.swift
//  Camera
//
//  Created by Khuất Hằng on 12/1/17.
//  Copyright © 2017 Tribal Media House. All rights reserved.
//

import UIKit
import AVFoundation
import CoreImage
import SwiftyJSON
import Alamofire

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var whisker: UIImageView!
    @IBOutlet weak var menu: UIView!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var previewCam: UIImageView!
    @IBOutlet weak var detectButton: UIBarButtonItem!
    
    //create AVCaptureSession
    let captureSession = AVCaptureSession()
    
    //if we find a device we 'll store it here for later use
    var captureDevice: AVCaptureDevice?
    
    let stillImageOutput = AVCaptureStillImageOutput()
    
    var preview : AVCaptureVideoPreviewLayer?
    
    var faceLayer: CALayer = CALayer()
    
    var textFace: CATextLayer = CATextLayer()
    
    var isHasFace: Bool = false
    
    var whiskerLayer1 : CALayer = CALayer()
    var whiskerLayer2 : CALayer = CALayer()
    var whiskerLayer3 : CALayer = CALayer()
    var whiskerLayer4 : CALayer = CALayer()
    var whiskerLayer5 : CALayer = CALayer()
    
    let whiskerImage: UIImage? = UIImage(named: "whisker")
    let a: UIImageView = UIImageView()
    
    
    var ciiImage = CIImage()
    var cgImage :CGImage?
    
    var faceID : Int = 0
    
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue")
    
    var menuShowing = false
    var whiskerShowing = false
    var isDetect = false
    
    var account: AccountModel = AccountModel()
    
    @IBAction func Detect(_ sender: Any) {
        if detectButton.title == "Detect" {
            isDetect = true
        }
        
        if (isDetect && faceLayer.frame != CGRect() ) {
            captureSession.stopRunning()
            detectButton.title = "Loading..."
            let frame1 = faceLayer.frame
            
            print(frame1)

            let new = CGRect(x: (frame1.origin.x)*2.25, y: (frame1.origin.y)*2.25, width: frame1.width*3, height: frame1.height*3)
            print("new ",new)
            let context = CIContext(options: nil)
            let cgImage = context.createCGImage(ciiImage, from: ciiImage.extent)
            let uiImage = UIImage.init(cgImage: cgImage!)


//                    let crop2 = cropImage(imageToCrop: uiImage, toRect: new)
            if let imgData = UIImageJPEGRepresentation(uiImage,1) {
                self.apiDetect(options: imgData, success: { (account) in
                    print("hang1 ", account)
                    if self.isHasFace {
                        self.account = account
                        self.textFace.string = account.name
                        self.textFace.frame = CGRect(x: frame1.origin.x, y: frame1.origin.y - 50, width: 200, height: 50)
                        self.detectButton.title = "Detect"
                        self.isDetect = false
                        
                        sleep(3)
                        
                        self.captureSession.startRunning()
//                        self.restart()
                    }
                    
                }) { (err) in
                    // Ignore err
                    print(err)
                }
            }
        } else {
            
        }
        
        
    }
    @IBAction func openMenu(_ sender: Any) {
        if (menuShowing) {
            leadingConstraint.constant = -70
            
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            })
        } else {
            leadingConstraint.constant = 0
            self.view.bringSubview(toFront: self.menu)
            
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            })
            
        }
        menuShowing = !menuShowing
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        //cat
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.addWhisker))
        whisker.isUserInteractionEnabled = true
        whisker.addGestureRecognizer(tapGestureRecognizer)
        
        //menu
        menu.layer.shadowOpacity = 1
        menu.layer.shadowRadius = 4
        
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        //        captureSession.sessionPreset = AVCaptureSessionPreset640x480
        
        let devices = AVCaptureDevice.devices()
        
        //Loop through all the capture devices on this phone
        for device in devices! {
            //make sure this particular device supports video
            if ((device as AnyObject).hasMediaType(AVMediaTypeVideo)) {
                //finally check the position and confirm we are got the back camera
                if (device as AnyObject).position == AVCaptureDevicePosition.front {
                    captureDevice = device as? AVCaptureDevice
                    if captureDevice != nil {
                        beginSession()
                    }
                }
            }
        }
    }
    
    @objc func addWhisker() {
        whiskerShowing = !whiskerShowing
        
//        print(isHasFace1)
//        if (isHasFace1) {
//            whiskerLayer?.frame = faceLayer1.frame
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.restart()
    }
    
    func restart() {
        captureSession.startRunning()
        
        isHasFace = false
        
        self.resetLayer(layer: faceLayer)
        
        self.resetTextLayer(layer: textFace)
        
        
        self.resetLayer(layer: whiskerLayer1)
        self.resetLayer(layer: whiskerLayer2)
        self.resetLayer(layer: whiskerLayer3)
        self.resetLayer(layer: whiskerLayer4)
        self.resetLayer(layer: whiskerLayer5)
    }
    
    func beginSession() {
        configDevice()
        do {
            try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice!))
        } catch let err {
            print(err)
        }
        
        self.preview = AVCaptureVideoPreviewLayer(session: captureSession)
        preview?.frame = self.cameraView.layer.bounds
        preview?.position = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        preview?.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        // Initialize Face Layer
        self.setUpLayer(layer: faceLayer)
        
        self.setUpTextLayer(label: textFace)
        
        
        self.setUpCat(whiskerLayer: whiskerLayer1)
        self.setUpCat(whiskerLayer: whiskerLayer2)
        self.setUpCat(whiskerLayer: whiskerLayer3)
        self.setUpCat(whiskerLayer: whiskerLayer4)
        self.setUpCat(whiskerLayer: whiskerLayer5)
        
        cameraView.layer.addSublayer(preview!)
        
        
        
        stillImageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
        if captureSession.canAddOutput(stillImageOutput) {
            captureSession.addOutput(stillImageOutput)
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
                metadataOutput.setMetadataObjectsDelegate(self, queue: self.dispatchQueue)
                if captureSession.canAddOutput(metadataOutput) {
                    captureSession.addOutput(metadataOutput)
                }
        metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeFace]
        captureSession.startRunning()
        
        let videoDeviceOutput = AVCaptureVideoDataOutput()
        videoDeviceOutput.setSampleBufferDelegate(self, queue: self.dispatchQueue)
        if captureSession.canAddOutput(videoDeviceOutput) {
            captureSession.addOutput(videoDeviceOutput)
        }
        
        captureSession.startRunning()
        
    }
    
    func setUpLayer(layer: CALayer) {
        layer.borderColor =  UIColor.green.cgColor
        layer.borderWidth = 2

        preview?.addSublayer(layer)
    }
    
    func setUpCat(whiskerLayer: CALayer) {
        whiskerLayer.contents = self.whiskerImage?.cgImage
        preview?.addSublayer(whiskerLayer)
    }
    
    func setUpTextLayer(label: CATextLayer) {
        label.font = "Helvetica-Bold" as CFTypeRef
        label.fontSize = 20
//        label.frame = CGRect(x: 0, y: 0, width: 200, height: 21)
//        label.string = "Hello"
        label.alignmentMode = kCAAlignmentCenter
        label.foregroundColor = UIColor.black.cgColor
        
        preview?.addSublayer(label)
    }
    
    func resetLayer(layer: CALayer) {
        layer.frame = CGRect()
    }
    
    
    func resetTextLayer(layer: CATextLayer) {
        layer.string = ""
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
//        print(connection.videoOrientation)
        if (connection.isVideoOrientationSupported) {
            connection.videoOrientation = AVCaptureVideoOrientation.portrait
        }
        getImage(sampleBuffer: sampleBuffer)

    }
    
    func getImage(sampleBuffer: CMSampleBuffer) {
        let pixelBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let sourceImageColor: CIImage = CIImage(cvPixelBuffer: pixelBuffer)
        ciiImage = sourceImageColor

        
        if (isHasFace) {
            
//            let crop = sourceImageColor.cropping(to: faceLayer1.frame)
            
//            var image = UIImage.init(ciImage: crop)
//            let context = CIContext(options: nil)
//            let cgImage = context.createCGImage(crop, from: crop.extent)
//            let uiImage = UIImage.init(cgImage: cgImage!)

        }
        
    }
    func cropImage(imageToCrop:UIImage, toRect rect:CGRect) -> UIImage{
        
        if let imageRef:CGImage = imageToCrop.cgImage!.cropping(to: rect) {
            let cropped:UIImage = UIImage(cgImage:imageRef)
//            CGImageRelease(imageRef)
            return cropped
        }
        return UIImage()
    }

    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {

        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)

        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects == nil || metadataObjects.count == 0 {
            DispatchQueue.main.sync {
                isHasFace = false
                
                self.account = AccountModel()
                
                self.resetLayer(layer: faceLayer)
                
                self.resetTextLayer(layer: textFace)
                
                self.resetLayer(layer: whiskerLayer1)
                self.resetLayer(layer: whiskerLayer2)
                self.resetLayer(layer: whiskerLayer3)
                self.resetLayer(layer: whiskerLayer4)
                self.resetLayer(layer: whiskerLayer5)
                
                self.detectButton.title = "Detect"
                self.isDetect = false
                
                
                print("No face is detected")
                CATransaction.commit()
                return
            }

        }
        
        var faces = [CGRect]()
        var i = 1
        for metadataObject in metadataObjects as! [AVMetadataFaceObject] {
//            print(metadataObject)
            if metadataObject.type == AVMetadataObjectTypeFace {
                let transformedMetadataObject = preview?.transformedMetadataObject(for: metadataObject)
                let face = (transformedMetadataObject?.bounds)!.integral
                faces.append(face)
                
//                DispatchQueue.main.sync {
                    switch i {
                    case 1 :
                        if (whiskerShowing) {
                            whiskerLayer1.frame = CGRect(x: face.origin.x+face.width/3-(face.width/8), y: face.origin.y+face.height/3, width: 0.6*face.width, height: 0.4*face.height)
                        } else {
                            self.resetLayer(layer: whiskerLayer1)
                        }
                        break
                    case 2 :
                        if (whiskerShowing) {
                            whiskerLayer2.frame = CGRect(x: face.origin.x+face.width/3-(face.width/8), y: face.origin.y+face.height/3, width: 0.6*face.width, height: 0.4*face.height)
                        } else {
                            self.resetLayer(layer: whiskerLayer2)
                        }
                        break
                    case 3 :
                        if (whiskerShowing) {
                            whiskerLayer3.frame = CGRect(x: face.origin.x+face.width/3-(face.width/8), y: face.origin.y+face.height/3, width: 0.6*face.width, height: 0.4*face.height)
                        } else {
                            self.resetLayer(layer: whiskerLayer3)
                        }
                        break
                    case 4 :
                        if (whiskerShowing) {
                            whiskerLayer4.frame = CGRect(x: face.origin.x+face.width/3-(face.width/8), y: face.origin.y+face.height/3, width: 0.6*face.width, height: 0.4*face.height)
                        } else {
                            self.resetLayer(layer: whiskerLayer4)
                        }
                        break
                    case 5 :
                        if (whiskerShowing) {
                            whiskerLayer5.frame = CGRect(x: face.origin.x+face.width/3-(face.width/8), y: face.origin.y+face.height/3, width: 0.6*face.width, height: 0.4*face.height)
                        } else {
                            self.resetLayer(layer: whiskerLayer5)
                        }
                        break
                    default : break
                    }
//                }
            }
            i = i + 1
        }
        
//        print("FACE",faces)

        if faces.count > 0 {
            self.faceLayer.isHidden = false
            DispatchQueue.main.sync {
                let faceMax = self.findMaxFaceRect(faces: faces)
                
                isHasFace = true
                if self.compareRect(frame: faceMax, frameCompare: faceLayer.frame){
//                    isHasFace = false
                    print("hang")
                } else {
//                    isHasFace = true
                    
                    self.account = AccountModel()

                    self.resetTextLayer(layer: textFace)
                    
                    faceLayer.frame = faceMax
                    
                }
                
                
            }
        }
        
        if (whiskerShowing) {
            self.faceLayer.isHidden = true
        }
        
        CATransaction.commit()

    }
    
    func scaleAndCropImage(image:UIImage, toSize size: CGSize) -> UIImage {
        // Sanity check; make sure the image isn't already sized.
        if image.size.equalTo(size) {
            return image
        }
        
        let widthFactor = size.width / image.size.width
        let heightFactor = size.height / image.size.height
        var scaleFactor: CGFloat = 0.0
        
        scaleFactor = heightFactor
        
        if widthFactor > heightFactor {
            scaleFactor = widthFactor
        }
        
        var thumbnailOrigin = CGPoint()
        let scaledWidth  = image.size.width * scaleFactor
        let scaledHeight = image.size.height * scaleFactor
        
        if widthFactor > heightFactor {
            thumbnailOrigin.y = (size.height - scaledHeight) / 2.0
        }
            
        else if widthFactor < heightFactor {
            thumbnailOrigin.x = (size.width - scaledWidth) / 2.0
        }
        
        var thumbnailRect = CGRect()
        thumbnailRect.origin = thumbnailOrigin
        thumbnailRect.size.width  = scaledWidth
        thumbnailRect.size.height = scaledHeight
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        image.draw(in: thumbnailRect)
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    private func cropToPreviewLayer(originalImage: UIImage) -> UIImage {
        let outputRect = preview?.metadataOutputRectOfInterest(for: (preview?.bounds)!)
        var cgImage = originalImage.cgImage!
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let cropRect = CGRect(x: (outputRect?.origin.x)! * width, y: (outputRect?.origin.y)! * height, width: (outputRect?.size.width)! * width, height: (outputRect?.size.height)! * height)
        
        cgImage = cgImage.cropping(to: cropRect)!
        let croppedUIImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: originalImage.imageOrientation)
        
        return croppedUIImage
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let p: CGPoint? = touch.location(in: cameraView)
            if (faceLayer.contains(cameraView.layer.convert(p ?? CGPoint.zero, to: faceLayer)) && account.id != "") {
                print("nhi")
                
                captureSession.stopRunning()
                let detailController = self.storyboard?.instantiateViewController(withIdentifier: "DetailController") as! DetailController
                detailController.account = self.account
                self.navigationController?.pushViewController(detailController, animated: true)


            }
        }
        super.touchesBegan(touches, with: event)
        
        
//        for touch in touches {
//
//            //            let point = touch.location(in: cameraView)
//            let touchPercent = self.touchPercent(touch: touch)
//
//            if let device = captureDevice {
//                do {
//                    try device.lockForConfiguration()
//                    device.focusPointOfInterest = touchPercent
//                    device.focusMode = AVCaptureFocusMode.autoFocus
//                    device.exposurePointOfInterest = touchPercent
//                    device.exposureMode = AVCaptureExposureMode.continuousAutoExposure
//                    device.unlockForConfiguration()
//
//                    //                    device.setFocusModeLockedWithLensPosition(0.5, completionHandler: { (timestamp:CMTime) -> Void in
//                    //                    // timestamp of the first image buffer with the applied lens positio
//                    //                    })
//
//                } catch let err {
//                    print(err)
//                }
//            }
//
//        }
    }
    
    func focusTo(value: Float) {
        if let device = captureDevice {
            do {
                try device.lockForConfiguration()
                device.setFocusModeLockedWithLensPosition(value, completionHandler: { (time) -> Void in
                    //
                })
                device.unlockForConfiguration()
            } catch let err {
                print(err)
            }
        }
    }
    
    func touchPercent(touch : UITouch) -> CGPoint {
        // Get the dimensions of the screen in points
        let screenSize = UIScreen.main.bounds.size
        
        // Create an empty CGPoint object set to 0, 0
        var touchPer = CGPoint()
        
        // Set the x and y values to be the value of the tapped position, divided by the width/height of the screen
        touchPer.x = touch.location(in: self.view).x / screenSize.width
        touchPer.y = touch.location(in: self.view).y / screenSize.height
        
        // Return the populated CGPoint
        return touchPer
    }
    
    func compareRect(frame: CGRect, frameCompare: CGRect) -> Bool {
        let x = frame.origin.x
        let y = frame.origin.y
        let width = frame.width
        let height = frame.height
        
        let xC = frameCompare.origin.x
        let yC = frameCompare.origin.y
        let widthC = frameCompare.width
        let heightC = frameCompare.height
        
        let numC : CGFloat = 30
        
        if (((x - numC) <= xC ) && (xC <= (x + numC))) && (((y - numC) <= yC ) && (yC <= (y + numC))) && (((width - numC) <= widthC ) && (widthC <= (width + numC))) && (((height - numC) <= heightC ) && (heightC <= (height + numC))) {
            return true
        }
        
        return false
    }
    
    func findMaxFaceRect(faces : Array<CGRect>) -> CGRect {
        if (faces.count == 1) {
            return faces[0]
        }
        var maxFace = CGRect.zero
        var maxFace_size = maxFace.size.width + maxFace.size.height
        for face in faces {
            let face_size = face.size.width + face.size.height
            if (face_size > maxFace_size) {
                maxFace = face
                maxFace_size = face_size
            }
        }
        return maxFace
    }
    
    func configDevice() {
        if let device = captureDevice {
            do {
                try device.lockForConfiguration()
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                }
                
                device.unlockForConfiguration()
            } catch let err {
                print(err)
            }
        }
    }
    
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        print("Device was shaken!")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func apiUpload(path: String, options: Data, success : @escaping (_ result: JSON) -> Void, error: @escaping (Error) -> Void) {
        
        Alamofire.upload(multipartFormData: {multipartFormData in
                    multipartFormData.append(options, withName: "upload_image",  fileName: "image.jpg", mimeType: "image/jpg")
                }
            , to: path)
        { (result) in
            
            switch result {
            case .success(let upload, _, _):
                
                upload.uploadProgress(closure: { (Progress) in
                    print("Upload Progress: \(Progress.fractionCompleted)")
                })
                
                upload.responseJSON { response in
                    print(response)
                    
                    guard let object = response.result.value else {
                        error(response.result.error!)
                        return
                    }
                    let json = JSON(object)
                    
                    success(json)
                    
                }
                
            case .failure(let encodingError):
                error(encodingError)
            }
        }
    }
    
    func apiDetect(options: Data, success : @escaping (_ result: AccountModel) -> Void, error: @escaping (Error) -> Void) {
        apiUpload(path: "http://192.168.0.73:8088/hang.php", options: options, success: { (resonse) in
//            success(resonse)
            print(resonse)
            
            
            let account = AccountModel()
                account.id = resonse["id"].string ?? ""
                account.name = resonse["name"].string ?? ""
                account.avatar = resonse["picture"].string ?? ""
                account.email = resonse["email"].string ?? ""
                account.birth = resonse["birthday"].string ?? ""

            success(account)
            
        }) { (err) in
            error(err)
        }
    }

}

