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
    
    @IBOutlet weak var imgView: UIImageView!
    
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
            print("can't access camera")
            return
        }
        
        imageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
        
        if captureSession.canAddOutput(imageOutput) {
            captureSession.addOutput(imageOutput)
        }
        
        //self.view.layer.addSublayer(self.previewLayer)
        
        let videoOutput = AVCaptureVideoDataOutput()
        
        videoOutput.setSampleBufferDelegate(self, queue: dispatch_queue_create("samplebufferdelegate", DISPATCH_QUEUE_SERIAL))
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.imgView.layer.addSublayer(self.previewLayer)
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect
        let rootLayer = self.imgView.layer
        rootLayer.masksToBounds = true
        self.previewLayer.frame = self.view.bounds
        rootLayer.addSublayer(self.previewLayer)
        
        captureSession.startRunning()
        
        self.hatImgView.contentMode = .ScaleToFill
        self.imgView.addSubview(self.hatImgView)
        
        self.beardImgView.contentMode = .ScaleToFill
        self.imgView.addSubview(self.beardImgView)
        
        self.mustacheImgView.contentMode = .ScaleToFill
        self.imgView.addSubview(self.mustacheImgView)
        
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
            //self.imgView.image = UIImage(CIImage: cameraImage, scale: 1.0, orientation: .Right)
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
            
            let hat_width = CGFloat(290.0)
            let hat_height = CGFloat(360.0)
            let head_start_y = CGFloat(150.0)
            let head_start_x = CGFloat(78.0)
            
            var width = faceRect.size.width * (hat_width / (hat_width - head_start_x))
            var height = width * hat_height/hat_width
            var y = faceRect.origin.y - (height * head_start_y) / hat_height
            var x = faceRect.origin.x - (head_start_x * width / hat_width)
            self.hatImgView.frame = CGRectMake(x, y, width, height)
            
            let beard_width = CGFloat(192.0)
            let beard_height = CGFloat(171.0)
            width = faceRect.size.width * 0.6
            height = width * beard_height/beard_width
            y = faceRect.origin.y + faceRect.size.height - (85 * height/beard_height)
            x = faceRect.origin.x + (faceRect.size.width - width) / 2
            self.beardImgView.frame = CGRectMake(x, y, width, height)
            
            let mustache_width = CGFloat(212.0)
            let mustache_height = CGFloat(58.0)
            width = faceRect.size.width * 0.9
            height = width * mustache_height/mustache_width
            y = y - height + 5
            x = faceRect.origin.x + (faceRect.size.width - width)/2
            self.mustacheImgView.frame = CGRectMake(x, y, width, height)
        }
        
        let elapsedTime = NSDate().timeIntervalSinceDate(self.lastPictureTime)
        let seconds = Int(elapsedTime)
        if seconds < 2 { return }
        
        self.lastPictureTime = NSDate.init()
        audioPlayer.play()
        //UIImageWriteToSavedPhotosAlbum(imageFromView(self.imgView), nil, nil, nil)
        saveToCameraRoll()
    }
    
    /* 
        Ideally this should not exist because it violates the main thread.
        In a production app, capture image with AVCaptureStillImageOutput
        using captureStillImageAsynchronouslyFromConnection:

    func imageFromView(view: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, true, 0)
        view.drawViewHierarchyInRect(view.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    */

    func saveToCameraRoll() {
        if let videoConnection = imageOutput.connectionWithMediaType(AVMediaTypeVideo) {
            imageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection) {
                (imageDataSampleBuffer, error) -> Void in
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                let image = UIImage(data: imageData)

                UIGraphicsBeginImageContextWithOptions((image?.size)!, true, 0)
                image?.drawInRect(CGRectMake(0, 0, (image?.size.width)!, (image?.size.height)!))
                
                let cameraImage = CIImage(image: image!)
                let features = self.faceDetector.featuresInImage(cameraImage!, options: [ CIDetectorImageOrientation : self.exifOrientation])
                
                let fdesc = CMSampleBufferGetFormatDescription(imageDataSampleBuffer)
                let cleanAperture = CMVideoFormatDescriptionGetCleanAperture(fdesc!, false)
                
                features.forEach { (ff:CIFeature) -> () in
                    var faceRect = ff.bounds
                    
                    let previewBox = self.videoUtil.previewBoxWithGravity(self.previewLayer.videoGravity, frameSize: (image?.size)!, apertureSize: cleanAperture.size)
                    
                    faceRect = self.videoUtil.convertFrame(faceRect, previewBox: previewBox, videoBox: cleanAperture, isMirrored: false)
                    
                    let hat_width = CGFloat(260.0)
                    let hat_height = CGFloat(360.0)
                    
                    let head_start_y = CGFloat(150.0)
                    let head_start_x = CGFloat(78.0)
                    
                    var width = faceRect.size.width * (hat_width / (hat_width - head_start_x))
                    var height = width * hat_height/hat_width
                    var y = faceRect.origin.y - (height * head_start_y) / hat_height
                    var x = faceRect.origin.x - (head_start_x * width / hat_width)
                    self.hatImgView.image?.drawInRect(CGRectMake(x, y, width, height))
                    
                    let beard_width = CGFloat(192.0)
                    let beard_height = CGFloat(171.0)
                    width = faceRect.size.width * 0.6
                    height = width * beard_height/beard_width
                    y = faceRect.origin.y + faceRect.size.height - (85 * height/beard_height)
                    x = faceRect.origin.x + (faceRect.size.width - width) / 2
                    self.beardImgView.image?.drawInRect(CGRectMake(x, y, width, height))
                    
                    let mustache_width = CGFloat(212.0)
                    let mustache_height = CGFloat(58.0)
                    width = faceRect.size.width * 0.9
                    height = width * mustache_height/mustache_width
                    y = y - height + 5
                    x = faceRect.origin.x + (faceRect.size.width - width)/2
                    self.mustacheImgView.image?.drawInRect(CGRectMake(x, y, width, height))
                }
                
                let outImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                UIImageWriteToSavedPhotosAlbum(outImage, nil, nil, nil)
            }
        }
    }
}

