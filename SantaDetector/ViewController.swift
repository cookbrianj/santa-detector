//
//  ViewController.swift
//  SantaDetector
//
//  Copyright © 2015 Brian Cook. All rights reserved.
//

import UIKit
import AVFoundation
import CoreImage
import CoreMedia

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var santaSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("hohoho", ofType: "wav")!)
    var audioPlayer: AVAudioPlayer!
    
    var lastPictureTime = NSDate.init()
    
    var previewLayer = AVCaptureVideoPreviewLayer()
    var imageOutput = AVCaptureStillImageOutput()
    var faceDetector = CIDetector()
    
    var hatImgView = UIImageView(image: UIImage(named: "christmas_hat.png"))
    var beardImgView = UIImageView(image: UIImage(named: "beard.png"))
    var mustacheImgView = UIImageView(image: UIImage(named: "mustache.png"))
    
    let videoUtil = VideoTools()
    let exifOrientation = 6
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOfURL: santaSound)
        } catch {
            print("sound failed to laod")
        }
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSessionPreset640x480
        
        var frontCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        for d in devices {
            if d.position == .Front {
                frontCamera = d as! AVCaptureDevice
            }
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            captureSession.addInput(input)
        } catch {
            print("can't access camera...bailing...")
            return
        }
        
        imageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
        if captureSession.canAddOutput(imageOutput) {
            captureSession.addOutput(imageOutput)
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        
        videoOutput.setSampleBufferDelegate(self, queue: dispatch_queue_create("samplebufferdelegate", DISPATCH_QUEUE_SERIAL))
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.view.layer.addSublayer(self.previewLayer)
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect
        let rootLayer = self.view.layer
        rootLayer.masksToBounds = true
        self.previewLayer.frame = self.view.bounds
        rootLayer.addSublayer(self.previewLayer)
        
        captureSession.startRunning()
        
        self.hatImgView.contentMode = .ScaleToFill
        self.view.addSubview(self.hatImgView)
        
        self.beardImgView.contentMode = .ScaleToFill
        self.view.addSubview(self.beardImgView)
        
        self.mustacheImgView.contentMode = .ScaleToFill
        self.view.addSubview(self.mustacheImgView)
        
        startDetection()
    }
    
    func startDetection() {
        self.faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [ CIDetectorAccuracy : CIDetectorAccuracyLow ])
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let attachments : NSDictionary = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate)!
        let cameraImage = CIImage(CVPixelBuffer: pixelBuffer!, options: (attachments as! [String : AnyObject]))
        
        let features = self.faceDetector.featuresInImage(cameraImage, options: [ CIDetectorImageOrientation : exifOrientation])
        
        let fdesc = CMSampleBufferGetFormatDescription(sampleBuffer)
        let cleanAperture = CMVideoFormatDescriptionGetCleanAperture(fdesc!, false)
        
        dispatch_async(dispatch_get_main_queue()) {
            let parentFrameSize = self.view.frame.size
            let gravity = self.previewLayer.videoGravity
            
            let previewBox = self.videoUtil.previewBoxWithGravity(gravity, frameSize: parentFrameSize, apertureSize: cleanAperture.size)
            self.detectedFace(features, clap: cleanAperture, previewBox: previewBox)
        }
    }
    
    func detectedFace(features: Array<CIFeature>, clap: CGRect, previewBox:CGRect) {
        if features.count < 1 {
            self.hatImgView.hidden = true
            self.beardImgView.hidden = true
            self.mustacheImgView.hidden = true
            return
        } else {
            self.hatImgView.hidden = false
            self.beardImgView.hidden = false
            self.mustacheImgView.hidden = false
        }
        
        features.forEach { (ff:CIFeature) -> () in
            var faceRect = ff.bounds
            
            faceRect = self.videoUtil.convertFrame(faceRect, previewBox: previewBox, videoBox: clap, isMirrored: true)
            
            let hatRect = hatDestRect(290.0, hat_height: 360.0, faceRect: faceRect)
            self.hatImgView.frame = hatRect
            let beardRect = beardDestRect(192.0, beard_height: 171.0, faceRect: faceRect)
            self.beardImgView.frame = beardRect
            self.mustacheImgView.frame = mustacheDestRect(212.0, mustache_height: 58.0, x: beardRect.origin.x, y: beardRect.origin.y, faceRect: faceRect)
        }
        
        let elapsedTime = NSDate().timeIntervalSinceDate(self.lastPictureTime)
        let seconds = Int(elapsedTime)
        if seconds < 2 { return }
        
        self.lastPictureTime = NSDate.init()
        audioPlayer.play()

        saveToCameraRoll()
    }
    
    func hatDestRect(hat_width: CGFloat, hat_height: CGFloat, faceRect: CGRect) -> CGRect {
        let head_start_y = CGFloat(150.0)
        let head_start_x = CGFloat(78.0)
        
        let width = faceRect.size.width * (hat_width / (hat_width - head_start_x))
        let height = width * hat_height/hat_width
        let y = faceRect.origin.y - (height * head_start_y) / hat_height
        let x = faceRect.origin.x - (head_start_x * width / hat_width)
        
        return CGRectMake(x, y, width, height)
    }
    
    func beardDestRect(beard_width: CGFloat, beard_height: CGFloat, faceRect: CGRect) -> CGRect {
        let width = faceRect.size.width * 0.6
        let height = width * beard_height/beard_width
        let y = faceRect.origin.y + faceRect.size.height - (85 * height/beard_height)
        let x = faceRect.origin.x + (faceRect.size.width - width) / 2
        
        return CGRectMake(x, y, width, height)
    }
    
    func mustacheDestRect(mustache_width: CGFloat, mustache_height: CGFloat, x: CGFloat, y: CGFloat, faceRect: CGRect) -> CGRect {
        let width = faceRect.size.width * 0.9
        let height = width * mustache_height/mustache_width
        let y = y - height + 5
        let x = faceRect.origin.x + (faceRect.size.width - width)/2
        
        return CGRectMake(x, y, width, height)
    }
    
    func saveToCameraRoll() {
        guard let videoConnection = imageOutput.connectionWithMediaType(AVMediaTypeVideo) else { return }
        
        imageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection) {
            (imageDataSampleBuffer, error) -> Void in
            let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
            guard let image = UIImage(data: imageData) else { return }
            
            UIGraphicsBeginImageContextWithOptions(image.size, true, 0)
            image.drawInRect(CGRectMake(0, 0, image.size.width, image.size.height))
            
            let cameraImage = CIImage(image: image)
            let features = self.faceDetector.featuresInImage(cameraImage!, options: [ CIDetectorImageOrientation : self.exifOrientation])
            
            let fdesc = CMSampleBufferGetFormatDescription(imageDataSampleBuffer)
            let cleanAperture = CMVideoFormatDescriptionGetCleanAperture(fdesc!, false)
            
            features.forEach { (ff:CIFeature) -> () in
                var faceRect = ff.bounds
                    
                let previewBox = self.videoUtil.previewBoxWithGravity(self.previewLayer.videoGravity, frameSize: image.size, apertureSize: cleanAperture.size)
                
                faceRect = self.videoUtil.convertFrame(faceRect, previewBox: previewBox, videoBox: cleanAperture, isMirrored: false)
                
                let hatRect = self.hatDestRect(260.0, hat_height: 360.0, faceRect: faceRect)
                self.hatImgView.image?.drawInRect(hatRect)
                let beardRect = self.beardDestRect(192.0, beard_height: 171.0, faceRect: faceRect)
                self.beardImgView.image?.drawInRect(beardRect)
                self.mustacheImgView.image?.drawInRect(self.mustacheDestRect(212.0, mustache_height: 58.0, x: beardRect.origin.x, y: beardRect.origin.y, faceRect: faceRect))
            }
            
            let outImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            UIImageWriteToSavedPhotosAlbum(outImage, nil, nil, nil)
            }
        }
}


