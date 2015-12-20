# santa-detector

Just a quick little iPad app for overlaying some holiday cheer onto an image from the front camera.

Using Swift, UIKit, AVFoundation, and Core Image to detect a face and draw a few images on a live preview.  Capture happens no more than every x seconds when a face is detected and the output image is processed and saved on a separate thread using captureStillImageAsynchronouslyFromConnection.

Running on an iPad mini (1st generation) the asynchronous capture method was a little laggy; the initial code took a screenshot and resulted in true WYSIWYG but the CPU<->GPU rountrip killed performance on this level of device and did not respect the main thread.


For a finishing touch print a 'mat' for it and put it in a picture frame:

<img src="http://glasshinges.us/santa/IMG_4435.jpg" width=200> <img src="http://glasshinges.us/santa/IMG_4436.jpg" width=200>
