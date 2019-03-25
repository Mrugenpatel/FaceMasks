//
//  masksViewModel.swift
//  VisionFaceTrack
//
//  Created by Muhammad Hunble Dhillon on 3/25/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import Foundation
import UIKit
import Vision

enum MaskType {
    case nose
    case eyeLeft
    case eyeRight
    case lips
    case eyeBrowLeft
    case eyeBrowRight
    case beard
    
    
    func getImage() -> CGImage{
        switch self {
        case .nose:
            return MasksUtil.noses.count > 0 ? MasksUtil.noses[Int.random(in: 0 ..< MasksUtil.noses.count)] : #imageLiteral(resourceName: "Default").cgImage!
        case .lips:
            return MasksUtil.lips.count > 0 ? MasksUtil.lips[Int.random(in: 0 ..< MasksUtil.lips.count)] : #imageLiteral(resourceName: "Default").cgImage!
        case .eyeLeft, .eyeRight:
            return MasksUtil.eyes.count > 0 ? MasksUtil.eyes[Int.random(in: 0 ..< MasksUtil.eyes.count)] : #imageLiteral(resourceName: "Default").cgImage!
        case .eyeBrowLeft:
            return MasksUtil.browLeft.count > 0 ? MasksUtil.browLeft[Int.random(in: 0 ..< MasksUtil.browLeft.count)] : #imageLiteral(resourceName: "Default").cgImage!
        case .eyeBrowRight:
            return MasksUtil.browRight.count > 0 ? MasksUtil.browRight[Int.random(in: 0 ..< MasksUtil.browRight.count)] : #imageLiteral(resourceName: "Default").cgImage!
        case .beard:
            return MasksUtil.beard.count > 0 ? MasksUtil.beard[Int.random(in: 0 ..< MasksUtil.beard.count)] : #imageLiteral(resourceName: "Default").cgImage!
        }
    }
}


class MasksUtil{
    
    static var HEIGHT_ADJUSTMENT_FACTOR : CGFloat = 1
    static var WIDTH_ADJUSTMENT_FACTOR : CGFloat = 1
    
    static let noses : [CGImage] = [#imageLiteral(resourceName: "nose2").cgImage!, #imageLiteral(resourceName: "nose1").cgImage!]
    static let eyes : [CGImage] = [#imageLiteral(resourceName: "eye2").cgImage!, #imageLiteral(resourceName: "eye3").cgImage!]
    static let lips : [CGImage] = [#imageLiteral(resourceName: "lips1").cgImage!]
    
    static let beard : [CGImage] = [#imageLiteral(resourceName: "beard-clipart-picsart-5").cgImage!]
    static let browLeft : [CGImage] = []
    static let browRight : [CGImage] = []
    

    class func getLandmarkPositionAndSizeNormalized( normalizedPoints: [CGPoint], faceBounds: CGRect, MaskType : MaskType) -> CGRect? {
                
        guard let min_y = normalizedPoints.min(by: { $0.y > $1.y }),
            let max_y = normalizedPoints.max(by: { $0.y > $1.y })
            else { return nil }
        
        guard let min_x = normalizedPoints.min(by: { $0.x > $1.x }),
            let max_x = normalizedPoints.max(by: { $0.x > $1.x })
            else { return nil }
        
        var y = ( min_y.y + max_y.y ) / 2
        let x = ( min_x.x + max_x.x ) / 2
        
        switch MaskType {
        case .eyeLeft, .eyeRight:
            HEIGHT_ADJUSTMENT_FACTOR = 2.3
            WIDTH_ADJUSTMENT_FACTOR = 1.3
        case .lips:
            HEIGHT_ADJUSTMENT_FACTOR = 1.5
            WIDTH_ADJUSTMENT_FACTOR = 1.2
        case .beard:
            HEIGHT_ADJUSTMENT_FACTOR = 1.4
            WIDTH_ADJUSTMENT_FACTOR = 1.1
            
            y = y - (y*0.5)
        default:
            HEIGHT_ADJUSTMENT_FACTOR = 1
            WIDTH_ADJUSTMENT_FACTOR = 1
        }
        
        let ratio_x = abs( max_x.x - min_x.x) * faceBounds.width * WIDTH_ADJUSTMENT_FACTOR
        let ratio_y = (abs( max_y.y - min_y.y) * faceBounds.height) * HEIGHT_ADJUSTMENT_FACTOR
        
        return CGRect(x: x, y: y, width: ratio_x, height: ratio_y)
    }
    
    class func renderMaskInNormailzed(sublayer: CALayer, maskPosition: CGPoint ,faceBounds :CGRect){
        
        let radians = 180 * Double.pi / 180
        let affineTransform = CGAffineTransform(translationX: faceBounds.origin.x, y: faceBounds.origin.y).rotated(by: CGFloat(radians))
        
        sublayer.setAffineTransform(affineTransform)
        
        sublayer.position = VNImagePointForNormalizedPoint(maskPosition, Int(faceBounds.size.width), Int(faceBounds.size.height))

    }
    
    
    
}
