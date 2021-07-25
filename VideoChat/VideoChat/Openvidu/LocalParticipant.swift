//
//  LocalParticipant.swift
//  WebRTCapp
//
//  Created by Dinesh on 5/30/21.
//

import Foundation
import WebRTC
import ReplayKit

protocol LocalParticipantDelegate: class {
    func localPeerConnectionIceCandidate(_ iceCandidate: RTCIceCandidate, connectionId: String)
}

class LocalParticipant: NSObject, Participant {
    var name: String?
    var connectionId: String?
    var audioTrack: RTCAudioTrack?
    var videoTrack: RTCVideoTrack?
    var screenShareTrack: RTCVideoTrack?
    var mediaStream: RTCMediaStream?
    var peerConnection: RTCPeerConnection?
    var videoCapturer: RTCVideoCapturer?
    var iceCandidates: [RTCIceCandidate]
    var sessionDescription: RTCSessionDescription?
    var videoView: RTCEAGLVideoView?
    var webRTCClient: WebRTCClient?
    let streamId = "device-stream-id"
    let screenShareStreamId = "device-screen-stream-id"
    var remoteVideoTrack: RTCVideoTrack?
    weak var delegate: LocalParticipantDelegate?
    var screenShare: RPScreenRecorder!
    var localVideoSource: RTCVideoSource!
    var viewFrameCapturer: ScreenCapture!
    
    override init() {
        self.iceCandidates = []
        self.screenShare = RPScreenRecorder.shared()
    }
    
    public func setPeerConnection(_ connection: RTCPeerConnection) {
        self.peerConnection = connection
        self.peerConnection?.delegate = self
        createLocalAudioStream()
        createLocalVideoStream()
        self.viewFrameCapturer = ScreenCapture.init(view: OpenViduManager.shared.testView, capture: self.videoCapturer!, videoSource: self.localVideoSource!)
    }
    
    private func createLocalAudioTrack() -> RTCAudioTrack {
        let peerConnectionFactory = webRTCClient!.peerConnectionFactory!
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = peerConnectionFactory.audioSource(with: audioConstrains)
        return peerConnectionFactory.audioTrack(with: audioSource, trackId: "audio-101")
    }
    
    private func createLocalVideoTrack() -> RTCVideoTrack {
        let peerConnectionFactory = webRTCClient!.peerConnectionFactory!
        localVideoSource = peerConnectionFactory.videoSource()
        localVideoSource.adaptOutputFormat(toWidth: 300, height: 300, fps: 30)
        self.videoCapturer = RTCCameraVideoCapturer(delegate: localVideoSource)
        return peerConnectionFactory.videoTrack(with: localVideoSource, trackId: "video-101")
    }
    
    private func createLocalAudioStream() {
        self.audioTrack = createLocalAudioTrack()
        if let audioTrack = self.audioTrack {
            self.peerConnection?.add(audioTrack, streamIds: [streamId])
            let audioTracks = peerConnection?.transceivers.compactMap {$0.sender.track as? RTCAudioTrack }
            audioTracks?.forEach { $0.isEnabled = true }
        }
    }
    
    private func createLocalVideoStream() {
        self.videoTrack = createLocalVideoTrack()
        if let videoTrack = self.videoTrack {
            peerConnection?.add(videoTrack, streamIds: [streamId])
            //remote track code
            if let transceivers = peerConnection?.transceivers {
                remoteVideoTrack = transceivers.first { $0.mediaType == .video }?.receiver.track as? RTCVideoTrack
            }
            videoTrack.add(videoView!)
        }
    }
    
    public func flipCamera(_ isFlip: Bool) {
        startCamera(isFlip)
    }
    
    public func recordScreen(_ isRecord: Bool) {
        if isRecord {
            guard let screenCapturer = videoCapturer as? RTCCameraVideoCapturer else {
                return
            }
            screenCapturer.stopCapture {
                //self.startReplayKitScreenShare()
                //self.startScreenShareByCoreGraphics()
                ReplayKitScreenShare.start(fromVideoSource: self.localVideoSource, capturer: screenCapturer)
            }
        } else {
            //stopScreenShareByCoreGraphics()
            ReplayKitScreenShare.stop()
            startCamera(false)
        }
    }
    
    //Videosource 1: Camera
    public func startCamera(_ isFlip: Bool) {
        let mode: AVCaptureDevice.Position = isFlip ? .back : .front
        let camera = getCamera(mode)
        guard let device = camera.frontCamera,
            let format = camera.format,
            let fps = camera.fps,
            let capturer = videoCapturer as? RTCCameraVideoCapturer else {
            return
        }
        capturer.startCapture(with: device, format: format, fps: Int(fps.maxFrameRate))
    }
    
    private func getCamera( _ position: AVCaptureDevice.Position) -> ( frontCamera: AVCaptureDevice?, format: AVCaptureDevice.Format?, fps: AVFrameRateRange?) {
        guard
            let frontCamera = (RTCCameraVideoCapturer.captureDevices().first { $0.position == position }),
            // choose highest res
            let format = (RTCCameraVideoCapturer.supportedFormats(for: frontCamera).sorted { (f1, f2) -> Bool in
                let width1 = CMVideoFormatDescriptionGetDimensions(f1.formatDescription).width
                let width2 = CMVideoFormatDescriptionGetDimensions(f2.formatDescription).width
                return width1 < width2
            }).last,
            // choose highest fps
            let fps = (format.videoSupportedFrameRateRanges.sorted { return $0.maxFrameRate < $1.maxFrameRate }.last) else {
                 return (nil, nil, nil)
        }
        return (frontCamera, format, fps)
    }
    
    //Videosource 2: Replaykit
    private func startReplayKitScreenShare() {
         self.screenShare.startCapture(handler: { (sampleBuffer, bufferType, error) in
           if error != nil {
                print("Capture error: ", error as Any)
                return
            }
            switch bufferType {
            case .video:
                self.shareDeviceScreen(sampleBuffer)
                break
            default:
                break
            }
        }) { (error) in
            let errroMsg = error != nil ? "\("Screen capture error: \(error as Any)")" : "Screen capture started."
            print(errroMsg)
        }
    }
    
    private func shareDeviceScreen(_ cmSampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(cmSampleBuffer),
              let screenCapturer = videoCapturer else {
              return
        }
        let rtcpixelBuffer = RTCCVPixelBuffer(pixelBuffer: pixelBuffer)
        var videoFrame:RTCVideoFrame?;
        let timestamp = NSDate().timeIntervalSince1970 * 1000
        videoFrame = RTCVideoFrame.init(buffer: rtcpixelBuffer, rotation: RTCVideoRotation._0, timeStampNs: Int64(timestamp))
        self.localVideoSource.adaptOutputFormat(toWidth: videoFrame!.width, height: videoFrame!.height, fps: 30)
        self.localVideoSource.capturer(screenCapturer, didCapture: videoFrame!)
        print("shareDeviceScreen \(videoFrame!.width) x \(videoFrame!.height)")
    }
    
    //Videosource 3:
    func startScreenShareByCoreGraphics() {
        self.viewFrameCapturer.startCapturer()
    }
    func stopScreenShareByCoreGraphics() {
        self.viewFrameCapturer.stopCapturer()
    }

    private func updateMediaStreamTrack() {
        guard let connection = self.peerConnection else {
            return
        }
        connection.addTransceiver(with: self.videoTrack!)
        connection.addTransceiver(with: self.audioTrack!)
        for transceiver in connection.transceivers {
            transceiver.setDirection(.sendOnly, error: nil)
            print("transceiver.direction Send only")
        }
    }
    
    public func storeIceCandiates(_ iceCandidate: RTCIceCandidate) {
        self.iceCandidates.append(iceCandidate)
    }
    
    public func storeSessionDescription(_ sessionDescription: RTCSessionDescription) {
        self.sessionDescription = sessionDescription
    }
    
    public func getLocalIceCandiates() -> [RTCIceCandidate]? {
        return self.iceCandidates
    }
    
    public func getLocalSessionDescription() -> RTCSessionDescription? {
        return self.sessionDescription
    }
}

extension LocalParticipant: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("Local peerConnection new signaling state: \(stateChanged)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("Local peerConnection did add stream")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("Local  peerConnection did remote stream")
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("Local peerConnection should negotiate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("Local  peerConnection new connection state: \(newState.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("Local peerConnection new gathering state: \(newState.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        print("local peerConnection ice candidate: \(connectionId ?? "")")
        if let id = connectionId {
            self.delegate?.localPeerConnectionIceCandidate(candidate, connectionId: id)
        } else {
            storeIceCandiates(candidate)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print("Local peerConnection didRemove candidates")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("Local peerConnection did open data channel")
    }
}
