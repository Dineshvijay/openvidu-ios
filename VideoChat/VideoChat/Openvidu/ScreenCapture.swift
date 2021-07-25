//
//  ScreenCapture.swift
//  VideoChat
//
//  Created by Dinesh on 5/30/21.
//

import UIKit
import WebRTC

class ScreenCapture {

    /**
     *  By default sending frames in screen sharing is using BiPlanarFullRange pixel format type.
     *  You can also send them using ARGB by setting this constant to NO.
     */
    let useBiPlanarFormatTypeForShare = true

    public var view: UIView?
    var displayLink: CADisplayLink!
    var screenShareCapture: RTCVideoCapturer!
    var videoSource: RTCVideoSource!

    private lazy var sharedGPUContext: CIContext = {
        CIContext(options: [CIContextOption.priorityRequestLow : true])
    }()

    // MARK: Construction

    init(view: UIView, capture: RTCVideoCapturer, videoSource: RTCVideoSource) {
        self.view = view
        self.screenShareCapture = capture
        self.videoSource = videoSource
    }

    // MARK: Enter BG / FG notifications

    @objc func willEnterForeground(notification: NSNotification!) {
        self.displayLink.isPaused = false
    }

    @objc func didEnterBackground(notification: NSNotification!) {
        self.displayLink.isPaused = true
    }

    // MARK: Functions
    func screenshot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.view!.frame.size, true, 1)
        self.view?.drawHierarchy(in: self.view!.bounds, afterScreenUpdates: false)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }

    @objc func sendPixelBuffer(sender: CADisplayLink) {
        DispatchQueue.main.async {
          autoreleasepool{

                let image = self.screenshot()

                let renderWidth = image.size.width
                let renderHeight = image.size.height

                var buffer: CVPixelBuffer? = nil

                var pixelFormatType: OSType?
                var pixelBufferAttributes: CFDictionary? = nil

                if self.useBiPlanarFormatTypeForShare {
                    pixelFormatType = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
                    pixelBufferAttributes = [
                        String(kCVPixelBufferIOSurfacePropertiesKey) : [:]
                        ] as CFDictionary
                }
                else {
                    pixelFormatType = kCVPixelFormatType_32ARGB
                    pixelBufferAttributes = [
                        String(kCVPixelBufferCGImageCompatibilityKey) : false,
                        String(kCVPixelBufferCGBitmapContextCompatibilityKey) : false
                        ] as CFDictionary
                }

                let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(renderWidth), Int(renderHeight), pixelFormatType!, pixelBufferAttributes, &buffer)

                if status == kCVReturnSuccess && buffer != nil {

                    CVPixelBufferLockBaseAddress(buffer!, CVPixelBufferLockFlags(rawValue: 0))

                    if self.useBiPlanarFormatTypeForShare {

                        let rImage = CIImage(image: image)
                        self.sharedGPUContext.render(rImage!, to: buffer!)
                    }
                    else {

                        let pxdata = CVPixelBufferGetBaseAddress(buffer!)
                        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()

                        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
                            .union(.byteOrder32Little)

                        let context = CGContext(data: pxdata, width: Int(renderWidth), height: Int(renderHeight), bitsPerComponent: 8, bytesPerRow: Int(renderWidth * 4), space: rgbColorSpace, bitmapInfo: bitmapInfo.rawValue)

                        context?.draw(image.cgImage!, in: CGRect(x: 0.0, y: 0.0, width: renderWidth, height: renderHeight))
                    }

                    CVPixelBufferUnlockBaseAddress(buffer!, CVPixelBufferLockFlags(rawValue: 0))
                    let rtcpixelBuffer = RTCCVPixelBuffer(pixelBuffer: buffer!)
                    let timestamp = NSDate().timeIntervalSince1970 * 1000
                    let videoFrame = RTCVideoFrame.init(buffer: rtcpixelBuffer, rotation: RTCVideoRotation._0, timeStampNs: Int64(timestamp))
                    self.videoSource.adaptOutputFormat(toWidth: videoFrame.width, height: videoFrame.height, fps: 30)
                    self.videoSource.capturer(self.screenShareCapture, didCapture: videoFrame)
                }
            }
        }
    }

    // MARK: VideoCapture
    func startCapturer() {
        self.displayLink = CADisplayLink(target: self, selector: #selector(sendPixelBuffer(sender:)))
        self.displayLink.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
        self.displayLink.preferredFramesPerSecond = 12 //5 fps
       NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground(notification:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    func stopCapturer() {
        self.displayLink.isPaused = true
        self.displayLink.remove(from: RunLoop.main, forMode: RunLoop.Mode.common)
        self.displayLink = nil
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
}

