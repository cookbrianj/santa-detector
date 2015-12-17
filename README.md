# santa-detector

Just a quick little iPad app for overlaying some holiday cheer onto an image from the front camera.

Using Swift, UIKit, AVFoundation, and Core Image to detect a face and draw a few images on a live preview.  Capture happens no more than every x seconds when a face is detected and the output image is processed and saved on a separate thread using captureStillImageAsynchronouslyFromConnection.
