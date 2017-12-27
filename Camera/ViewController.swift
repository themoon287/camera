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
    var faceLayer1: CALayer = CALayer()
    var faceLayer2: CALayer = CALayer()
    var faceLayer3: CALayer = CALayer()
    var faceLayer4: CALayer = CALayer()
    var faceLayer5: CALayer = CALayer()
    
    var textFace1: CATextLayer = CATextLayer()
    var textFace2: CATextLayer = CATextLayer()
    var textFace3: CATextLayer = CATextLayer()
    var textFace4: CATextLayer = CATextLayer()
    var textFace5: CATextLayer = CATextLayer()
    
    var isHasFace1: Bool = false
    var isHasFace2: Bool = false
    var isHasFace3: Bool = false
    var isHasFace4: Bool = false
    var isHasFace5: Bool = false
    
    var whiskerLayer : CALayer?
    let whiskerImage: UIImage? = UIImage(named: "whisker")
    
    
    var ciiImage = CIImage()
    var cgImage :CGImage?
    
    var faceID : Int = 0
    
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue")
    
    var menuShowing = false
    var whiskerShowing = false
    var isDetect = false
    
    var account: AccountModel = AccountModel()
    
    @IBAction func Detect(_ sender: Any) {
        isDetect = !isDetect
        if (isDetect && faceLayer1.frame != CGRect() ) {
            detectButton.title = "Loading..."
            let frame1 = faceLayer1.frame

            let new = CGRect(x: (frame1.origin.x+frame1.width/2)*2.25+frame1.width*0.25, y: (frame1.origin.y+frame1.height/2)*2.25+frame1.height*1.5, width: frame1.width*6, height: frame1.height*8)
            print("new ",new)
            let context = CIContext(options: nil)
            let cgImage = context.createCGImage(ciiImage, from: ciiImage.extent)
            let uiImage = UIImage.init(cgImage: cgImage!)
            print(uiImage.size)


//                    let crop2 = cropImage(imageToCrop: uiImage, toRect: new)
            if let imgData = UIImageJPEGRepresentation(uiImage,1) {
                self.apiDetect(options: imgData, success: { (account) in
                    print("hang1 ", account)
                    self.account = account
                    self.textFace1.string = account.name
                    self.textFace1.frame = CGRect(x: frame1.origin.x, y: frame1.origin.y - 50, width: 200, height: 50)
                    self.detectButton.title = "Detect"
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
        captureSession.startRunning()
        
        isHasFace1 = false
        isHasFace2 = false
        isHasFace3 = false
        isHasFace4 = false
        isHasFace5 = false
        
        self.resetLayer(layer: faceLayer)
        self.resetLayer(layer: faceLayer1)
        self.resetLayer(layer: faceLayer2)
        self.resetLayer(layer: faceLayer3)
        self.resetLayer(layer: faceLayer4)
        self.resetLayer(layer: faceLayer5)
        
        self.resetTextLayer(layer: textFace1)
        self.resetTextLayer(layer: textFace2)
        self.resetTextLayer(layer: textFace3)
        self.resetTextLayer(layer: textFace4)
        self.resetTextLayer(layer: textFace5)
        
        whiskerLayer?.frame = CGRect()
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
        self.setUpLayer(layer: faceLayer1)
        self.setUpLayer(layer: faceLayer2)
        self.setUpLayer(layer: faceLayer3)
        self.setUpLayer(layer: faceLayer4)
        self.setUpLayer(layer: faceLayer5)
        
        self.setUpTextLayer(label: textFace1)
        self.setUpTextLayer(label: textFace2)
        self.setUpTextLayer(label: textFace3)
        self.setUpTextLayer(label: textFace4)
        self.setUpTextLayer(label: textFace5)
        
        
        whiskerLayer = CALayer()
        whiskerLayer?.contents = self.whiskerImage?.cgImage
        preview?.addSublayer(whiskerLayer!)
        
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

        
        if (isHasFace1) {
            
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
                isHasFace1 = false
                isHasFace2 = false
                isHasFace3 = false
                isHasFace4 = false
                isHasFace5 = false
                
                self.account = AccountModel()
                
                self.resetLayer(layer: faceLayer)
                self.resetLayer(layer: faceLayer1)
                self.resetLayer(layer: faceLayer2)
                self.resetLayer(layer: faceLayer3)
                self.resetLayer(layer: faceLayer4)
                self.resetLayer(layer: faceLayer5)
                
                self.resetTextLayer(layer: textFace1)
                self.resetTextLayer(layer: textFace2)
                self.resetTextLayer(layer: textFace3)
                self.resetTextLayer(layer: textFace4)
                self.resetTextLayer(layer: textFace5)
                
                whiskerLayer?.frame = CGRect()
                
                
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
                let face = transformedMetadataObject?.bounds
                faces.append(face!)
                
                DispatchQueue.main.sync {
//                    switch i {
//                    case 1 :
//                        let frame1 = (transformedMetadataObject?.bounds)!.integral
//
//                        if (whiskerShowing) {
//                            print(frame1)
//                            whiskerLayer?.frame = CGRect(x: frame1.origin.x+frame1.width/3-(frame1.width/8), y: frame1.origin.y+frame1.height/3, width: 0.6*frame1.width, height: 0.4*frame1.height)
//
//                            self.resetLayer(layer: faceLayer1)
//                            self.resetTextLayer(layer: textFace1)
//
//                        } else {
//                            self.resetLayer(layer: whiskerLayer!)
//
//
//
//                            if self.compareRect(frame: frame1, frameCompare: faceLayer1.frame){
//                                isHasFace1 = false
//                                print("hang")
//                            } else {
//                                isHasFace1 = true
//
//                                self.account = AccountModel()
//
//                                self.resetTextLayer(layer: textFace1)
//
//                                faceLayer1.frame = frame1
//
//                            }
//                        }
//                        break
//                    case 2 :
//                        let frame2 = (transformedMetadataObject?.bounds)!.integral
//                        if self.compareRect(frame: frame2, frameCompare: faceLayer2.frame) {
//                            isHasFace2 = false
//                        } else {
//                            isHasFace2 = true
//                            faceLayer2.frame = frame2
//                            print("hang2 ",frame2)
//                        }
//                        break
//                    case 3 :
//                        let frame3 = (transformedMetadataObject?.bounds)!.integral
//                        if self.compareRect(frame: frame3, frameCompare: faceLayer3.frame) {
//                            isHasFace3 = false
//                        } else {
//                            isHasFace3 = true
//                            faceLayer3.frame = frame3
//                            print("hang3 ",frame3)
//                        }
//                        break
//                    case 4 :
//                        let frame4 = (transformedMetadataObject?.bounds)!.integral
//                        if self.compareRect(frame: frame4, frameCompare: faceLayer4.frame) {
//                            isHasFace4 = false
//                        } else {
//                            isHasFace4 = true
//                            faceLayer4.frame = frame4
//                            print("hang4 ",frame4)
//                        }
//                        break
//                    case 5 :
//                        let frame5 = (transformedMetadataObject?.bounds)!.integral
//                        if self.compareRect(frame: frame5, frameCompare: faceLayer5.frame) {
//                            isHasFace5 = false
//                        } else {
//                            isHasFace5 = true
//                            faceLayer5.frame = frame5
//                            print("hang5",frame5)
//                        }
//                        break
//                    default : break
//                    }
                }
            }
            i = i + 1
        }
        
//        print("FACE",faces)

        if faces.count > 0 {
            self.faceLayer.isHidden = false
            DispatchQueue.main.sync {
                self.faceLayer.frame = self.findMaxFaceRect(faces: faces)

            }
        } else {
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
            if (faceLayer1.contains(cameraView.layer.convert(p ?? CGPoint.zero, to: faceLayer1))) {
                print("nhi")
                
                
                
//                captureSession.stopRunning()
//                let detailController = self.storyboard?.instantiateViewController(withIdentifier: "DetailController") as! DetailController
//                detailController.account = self.account
//                self.navigationController?.pushViewController(detailController, animated: true)


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
        
        let numC : CGFloat = 50
        
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
//                                device.focusMode = .locked
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                }
//
                device.unlockForConfiguration()
//                if device.isFocusModeSupported(.continuousAutoFocus) {
//                    try! device.lockForConfiguration()
//                    device.focusMode = .continuousAutoFocus
//                    device.unlockForConfiguration()
//                }
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
//                    print("Upload Progress: \(Progress.fractionCompleted)")
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
//            if self.isHasFace1 {
                account.id = resonse["id"].string ?? ""
                account.name = resonse["name"].string ?? ""
                account.avatar = resonse["picture"].string ?? ""
                account.email = resonse["email"].string ?? ""
                account.birth = resonse["birthday"].string ?? ""
//            }
//            print(account)
            success(account)
            
        }) { (err) in
            error(err)
        }
    }

}

