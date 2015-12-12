//
//  VideoTools.swift
//  SantaDetector
//
//  Created by Brian Cook on 12/11/15.
//  Copyright © 2015 Brian Cook. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import CoreImage
import CoreMedia

class VideoTools: NSObject {
    func previewBoxWithGravity(gravity: NSString, frameSize: CGSize, apertureSize: CGSize) -> CGRect {
        let apertureRatio = apertureSize.height / apertureSize.width
        let viewRatio = frameSize.width / frameSize.height
        
        var size = CGSizeZero
        if (gravity.isEqualToString(AVLayerVideoGravityResizeAspectFill)) {
            if (viewRatio > apertureRatio) {
                size.width = frameSize.width
                size.height = apertureSize.width * (frameSize.width / apertureSize.height)
            } else {
                size.width = apertureSize.height * (frameSize.height / apertureSize.width)
                size.height = frameSize.height
            }
        } else if (gravity.isEqualToString(AVLayerVideoGravityResizeAspect)) {
            if (viewRatio > apertureRatio) {
                size.width = apertureSize.height * (frameSize.height / apertureSize.width)
                size.height = frameSize.height
            } else {
                size.width = frameSize.width
                size.height = apertureSize.width * (frameSize.width / apertureSize.height)
            }
        } else {
            size.width = frameSize.width
            size.height = frameSize.height
        }
        
        var vidBox = CGRectZero
        vidBox.size = size
        if (size.width < frameSize.width) {
            vidBox.origin.x = (frameSize.width - size.width) / 2
        } else {
            vidBox.origin.x = (size.width - frameSize.width) / 2
        }
        
        if (size.height < frameSize.height) {
            vidBox.origin.y = (frameSize.height - size.height) / 2
        } else {
            vidBox.origin.y = (size.height - frameSize.height) / 2
        }
        
        return vidBox
    }
    
    func convertFrame(var originalFrame: CGRect, previewBox: CGRect, videoBox: CGRect, isMirrored: Bool) -> CGRect {
        var temp = originalFrame.size.width
        originalFrame.size.width = originalFrame.size.height
        originalFrame.size.height = temp
        temp = originalFrame.origin.x
        originalFrame.origin.x = originalFrame.origin.y
        originalFrame.origin.y = temp
        
        let widthScaleAmount = previewBox.size.width / videoBox.size.height
        let heightScaleAmount = previewBox.size.height / videoBox.size.width
        
        originalFrame.size.width = originalFrame.size.width * widthScaleAmount
        originalFrame.size.height = originalFrame.size.height * heightScaleAmount
        originalFrame.origin.x = originalFrame.origin.x * widthScaleAmount
        originalFrame.origin.y = originalFrame.origin.y * heightScaleAmount
        
        switch isMirrored {
        case true:
            originalFrame = CGRectOffset(originalFrame, previewBox.origin.x + previewBox.size.width - originalFrame.size.width - (originalFrame.origin.x * 2), previewBox.origin.y)
        default:
            originalFrame = CGRectOffset(originalFrame, previewBox.origin.x, previewBox.origin.y)
        }
        
        return originalFrame
    }
}
