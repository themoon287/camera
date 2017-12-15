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

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var previewCam: UIImageView!
    
    //create AVCaptureSession
    let captureSession = AVCaptureSession()
    
    //if we find a device we 'll store it here for later use
    var captureDevice: AVCaptureDevice?
    
    let stillImageOutput = AVCaptureStillImageOutput()
    
    var preview : AVCaptureVideoPreviewLayer?
    
    var faceLayer1: CALayer = CALayer()
    var faceLayer2: CALayer = CALayer()
    var faceLayer3: CALayer = CALayer()
    var faceLayer4: CALayer = CALayer()
    var faceLayer5: CALayer = CALayer()
    
    var faceArr : [CALayer]?
    
    var faceID : Int = 0
    
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        //        captureSession.sessionPreset = AVCaptureSessionPreset640x480
        
        let devices = AVCaptureDevice.devices()
        
        //Loop through all the capture devices on this phone
        for device in devices! {
            //make sure this particular device supports video
            if ((device as AnyObject).hasMediaType(AVMediaTypeVideo)) {
                //finally check the position and confirm we are got the back camera
                if (device as AnyObject).position == AVCaptureDevicePosition.back {
                    captureDevice = device as? AVCaptureDevice
                    if captureDevice != nil {
                        beginSession()
                    }
                }
            }
        }
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
        self.setUpLayer(layer: faceLayer1)
        self.setUpLayer(layer: faceLayer2)
        self.setUpLayer(layer: faceLayer3)
        self.setUpLayer(layer: faceLayer4)
        self.setUpLayer(layer: faceLayer5)
        
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
    
    func resetLayer(layer: CALayer) {
        layer.frame = CGRect()
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        if (connection.isVideoOrientationSupported) {
            connection.videoOrientation = AVCaptureVideoOrientation.portrait
        }
        
        updateStickerPosition(sampleBuffer: sampleBuffer)
    }
    
    func updateStickerPosition(sampleBuffer: CMSampleBuffer) {
        let pixelBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let sourceImageColor: CIImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        if (faceLayer1.frame.width != 0 ) {
            let context = CIContext(options: nil)
            let cgImage = context.createCGImage(sourceImageColor, from: sourceImageColor.extent)
            let uiImage = UIImage.init(cgImage: cgImage!)
            
            
            if let imgData = UIImageJPEGRepresentation(uiImage,1) {
                
                Alamofire.upload(multipartFormData: {multipartFormData in
                    multipartFormData.append(imgData, withName: "upload_image",  fileName: "image.jpg", mimeType: "image/jpg")
                }
                    , to: "http://192.168.0.38:8088/hang.php")
                { (result) in
                    switch result {
                    case .success(let upload, _, _):
                        
                        upload.uploadProgress(closure: { (Progress) in
                            print("Upload Progress: \(Progress.fractionCompleted)")
                        })
                        
                        upload.responseJSON { response in
                            
                            
                            DispatchQueue.main.async(execute: {
                                guard let object = response.result.value else {
                                    let alert = UIAlertController(title: "Alert", message: response.result.error?.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                                    self.present(alert, animated: true, completion: nil)
                                    
                                    print(response.result.error!)
                                    return
                                }
                                let json = JSON(object)
                                
                                let alert = UIAlertController(title: "", message: json["result"].string, preferredStyle: UIAlertControllerStyle.alert)
                                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                                
                                
                                
                                let string = json["result"].string
                                //                            let utterance = AVSpeechUtterance(string: string!)
                                //                            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                                //
                                //                            let synth = AVSpeechSynthesizer()
                                //                            synth.speak(utterance)
                                
                                print(json)
                                
                            })
                            
                            
                        }
                        
                    case .failure(let encodingError):
                        //self.delegate?.showFailAlert()
                        print(encodingError)
                    }
                    
                }
                
            }
        }
        
    }
    func cropImage(imageToCrop:UIImage, toRect rect:CGRect) -> UIImage{
        
        let imageRef:CGImage = imageToCrop.cgImage!.cropping(to: rect)!
        let cropped:UIImage = UIImage(cgImage:imageRef)
        return cropped
    }

    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {

        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)

//        var faces = [CGRect]()
//        self.preview?.sublayers?.forEach { $0.removeFromSuperlayer() }
//        self.preview = AVCaptureVideoPreviewLayer(session: captureSession)


        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects == nil || metadataObjects.count == 0 {
            DispatchQueue.main.sync {
//                faceLayer?.frame = CGRect()
                self.resetLayer(layer: faceLayer1)
                self.resetLayer(layer: faceLayer2)
                self.resetLayer(layer: faceLayer3)
                self.resetLayer(layer: faceLayer4)
                self.resetLayer(layer: faceLayer5)
                faceArr = []
                print("No face is detected")
                CATransaction.commit()
                return
            }

        }
        print(metadataObjects)
        var i = 1
        for metadataObject in metadataObjects as! [AVMetadataFaceObject] {
//            print(metadataObject)
            if metadataObject.type == AVMetadataObjectTypeFace {
                let transformedMetadataObject = preview?.transformedMetadataObject(for: metadataObject)
//                if faceID != metadataObject.faceID {
//                    print(faceID)
//                    DispatchQueue.main.sync {
//                    let face = CALayer()
//                    face.borderColor =  UIColor.green.cgColor
//                    face.borderWidth = 2
//
////                    preview?.addSublayer(faceLayer!)
//                    face.frame = (transformedMetadataObject?.bounds)!
////                    faceArr?.append(face)
//                    preview?.addSublayer(face)
//                    }

//                    let face = (transformedMetadataObject?.bounds)!
//                    faces.append(face)
//                     faceID = metadataObject.faceID
//                }

                DispatchQueue.main.sync {
                    switch i {
                    case 1 :
                        faceLayer1.frame = (transformedMetadataObject?.bounds)!
                        break
                    case 2 :
                        faceLayer2.frame = (transformedMetadataObject?.bounds)!
                        break
                    case 3 :
                        faceLayer3.frame = (transformedMetadataObject?.bounds)!
                        break
                    case 4 :
                        faceLayer4.frame = (transformedMetadataObject?.bounds)!
                        break
                    case 5 :
                        faceLayer5.frame = (transformedMetadataObject?.bounds)!
                        break
                    default : break
                    }
                }


                if let videoConnection = self.stillImageOutput.connection(withMediaType: AVMediaTypeVideo) {


//                    DispatchQueue.main.async {
//                        self.stillImageOutput.captureStillImageAsynchronously(from: videoConnection, completionHandler: {(imageDataSampleBuffer, error) -> Void in
//                            if imageDataSampleBuffer != nil {
//
//
//                                if let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer) {
//
//                                    let img : UIImage = UIImage(data: imageData)!
//
//                                    print(img)
//
//                                }
//                            }
//                        } )
//                    }
                }
            }
            i = i + 1
        }
//        print("FACE",faces)
//
//        if faces.count > 0 {
//            self.faceLayer?.isHidden = false
//            DispatchQueue.main.sync {
//                self.faceLayer?.frame = self.findMaxFaceRect(faces: faces)
//
//            }
//        } else {
//            self.faceLayer?.isHidden = true
//        }
//
        CATransaction.commit()

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
                //                device.focusMode = .locked
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                }
                
                device.unlockForConfiguration()
            } catch let err {
                print(err)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

