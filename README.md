# Masking the user face in real time.

The app is capable of masking different facial landmarks of a face in real time. With using the Vision API of the user face is detected and the using the object tracking request of Vision API the object is tracked in a sequence of image frames.


![Sample 1](https://lh3.googleusercontent.com/IuyYnUT8KEBrsHhC78GmdWSLLNB8CD5HrytBeR6dwG_Ho8nJ-43zeqOdL84CMSNapXoPZtNdXV31VsodcoLw_WmONw0tQv-eJ1El6LKis0dD24ow5Pxs5fioG-J7MNc7-hYGkQ6_oG9W6HGaWxaRWqDJ3fvmHblgkBUlyfhQwdYXMJl4GRXyBuGOk3Gb2VTAQzI6-RJEIaMss0ViiYB3HeWXyCRAKXfBfIsEpC0aa3vWT3Z6qwqsM2ncRRx5flANfLLgT2LrzdZhDxQjfvDhoUoBG_RmO-eNP-vYVnEEkO4wiq8Op-ok92Tyg1DGQzNzP3VW7-TKdqK_HGWFEChmB8ovakRM4uIdcg7uvktlptzp4KJyo_iOwi1JJM0fqMnFH59QNoURzqXi-1o9FjyMejUnJb6XwYmPlojJmPZmAKJxlakKFM67Q5hIpMAw9PmPLHKdRtjxzk-oIYHFsepMJKs8uUvktcQojCEnYf2wAJVdgM_F7tZY4rXRTQ1gZxcpEgObGb3PrlDmHecE1Sr4htKzaJb9stuUazGiJSm8alJnnrH2tH-v5ABuHL1aRaJLGemlJplOAeD1JfHJ9UZJX5AaLFcTDZUJi3EbpnU=w600-h200)

![Sample 2](https://lh4.googleusercontent.com/JqPYlUr26EDCeos4d0hmblzA3wdkxOx8JGDnPipJzbt7Wcx5-q7dYlHnz4ViQYrJ1gPf12Z5rMLL1ylJ0TGM=w600-h200-rw)


![Sample 3](https://lh5.googleusercontent.com/3Yl0demEgQD0HIR9f8VeZMDe_Z9qRFsH0-yYtsTHm-sLYF8qOVgEDM2WY7WZAxK3G9iaBMpJLNrqAM9JqgQ6=w600-h200-rw)


The basic components app are:

1. Camera Integration
2. Face Detection
3. Object Tracking the detected face
4. Landmark segregation of face
5. Masking different landmarks with custom images
6. Dynamic Size adjustment for the mask to size and position according to the real-time landmark size.

The ARKit can distinguish between different facial feature very well using the power of true depth camera available with iPhone X and later models. Joining that with SceneKit makes the job of masking faces has become really easy and a sample project for that can easily be found at [Raywenderlich](https://www.raywenderlich.com/5491-ar-face-tracking-tutorial-for-ios-getting-started). The only drawback is that is only available to the phone with true depth camera hardware. The second solution in the row is Vision [Vision](https://developer.apple.com/documentation/vision) framework which can detect and track rectangles, faces, and other salient objects across a sequence of images. Integrating that with AVCapture Session can get us the results close enough to the ARkit solution but this solution is available for devices with camera available.

The Capture library off the box provides two very critical feature required for our application. The one is face detection and the other is object tracking. The details on how their combination can help us real-time track face are discussed in the last section, here we will start by assuming that we have the normalized (0...1) location points of all the face landmarks (nose, lips, eyes, etc) in an array format. The presence of normalized points helped us scaled the location to the screen of any size.

Now here we have another consideration to make, which is the framework decision for rendering masks. Core Graphics vs Core Animation. The CA uses GPU to render views and is designed for animation and translation related stuff. and we need real-time response in the screen so it is best to take advantage of GPU. instead of relying on core graphics which is CPU based. Once graphics library decision is out of the way was selected now we can start rendering the mask.


The first problem is the coordinate system origin unification. the AVFoundation consider the lower left corner as the origin point on the other hand Vision considers the upper left corner as the origin point. We need some sort of adaptor to translate the systems for this problem the image was flipped. and also as the points are normalized, they were scaled to the capture window size.


``` swift
    class func renderMaskInNormailzed(sublayer: CALayer, maskPosition: CGPoint ,faceBounds :CGRect){
        
        let radians = 180 * Double.pi / 180
        let affineTransform = CGAffineTransform(translationX: faceBounds.origin.x, y: faceBounds.origin.y).rotated(by: CGFloat(radians))
        
        sublayer.setAffineTransform(affineTransform)
        
        sublayer.position = VNImagePointForNormalizedPoint(maskPosition, Int(faceBounds.size.width), Int(faceBounds.size.height))

    }
```

The second problem is the position and size of the masking doodle itself. The positions of landmarks are the irregular point they are not frames where one might be able to render a picture so somehow their centre point was to be found to place the image at that point. The next problem was the size fo doodle for that we took the difference of further points. as the points are normalized they were scaled to the screen size.



``` swift

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

```
The adjustment factor is significant because if eyes are little bigger it better overall but if the nose is too high the same can't be said so there had to have some feature specific adjustment method.

The last part was to all customizability of the mask. To enable that configuration. we have two arrays to accept data just add any new image the correct array and the image is part of the application

``` swift
    static let noses : [CGImage] = [#imageLiteral(resourceName: "nose2").cgImage!, #imageLiteral(resourceName: "nose1").cgImage!]
    static let eyes : [CGImage] = [#imageLiteral(resourceName: "eye2").cgImage!, #imageLiteral(resourceName: "eye3").cgImage!]
    static let lips : [CGImage] = [#imageLiteral(resourceName: "lips1").cgImage!]
    
    static let beard : [CGImage] = [#imageLiteral(resourceName: "beard-clipart-picsart-5").cgImage!]
    static let browLeft : [CGImage] = []
    static let browRight : [CGImage] = []
```

To include/exclude the mask of some specific feature following dictionary is altered.

``` swift
        masks = [MaskType:CALayer]()
        
        masks?[.nose] = CALayer()
        masks?[.lips] = CALayer()
        masks?[.eyeLeft] = CALayer()
        masks?[.eyeRight] = CALayer()
//        masks?[.beard] = CALayer()
```

``` swift
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
```

Obviously, both these configurations can be added in the sperate file for scalability purposes. I would also like to change the masks on taps and swipes but I have avoided that for now just to save time. I am randomly sending the masks on each app load.


The first four points are discussed in apple sample code [here] (https://developer.apple.com/documentation/vision/tracking_the_user_s_face_in_real_time) this project has provided the bases for this application. The first four points are catered on this link please check that out.
