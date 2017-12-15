//
//  FaceDetector.swift
//  Camera
//
//  Created by Khuất Hằng on 12/5/17.
//  Copyright © 2017 Tribal Media House. All rights reserved.
//

import Foundation
import CoreImage

private let _sharedCIDetector = CIDetector(
    ofType: CIDetectorTypeFace,
    context: nil,
    options: [
        CIDetectorAccuracy: CIDetectorAccuracyLow,
        CIDetectorTracking: false,
        CIDetectorMinFeatureSize: NSNumber(value: 0.1)
    ])

class FaceDetector {
    
    class var sharedCIDetector: CIDetector {
        return _sharedCIDetector!
    }
    
    class func detectFaces(inImage image: CIImage) -> [CIFaceFeature] {
        let detector = FaceDetector.sharedCIDetector
        let features = detector.features(
            in: image,
            options: [
                CIDetectorImageOrientation: 1,
                CIDetectorEyeBlink: false,
                CIDetectorSmile: false
            ])
        
        return features as! [CIFaceFeature]
    }
}
