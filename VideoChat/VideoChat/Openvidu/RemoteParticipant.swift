//
//  RemoteParticipant.swift
//  WebRTCapp
//
//  Created by Dinesh on 5/30/21.
//

import Foundation
import WebRTC
protocol RemoteParticipantDelegate: class {
    func remotePeerConnectionIceCandidate(_ iceCandidate: RTCIceCandidate, connectionId: String)
}
class RemoteParticipant: NSObject, Participant {
   weak var delegate: RemoteParticipantDelegate?
   var name: String?
   var connectionId: String?
   var videoTrack: RTCVideoTrack?
   var peerConnection: RTCPeerConnection?
   var videoCapturer: RTCVideoCapturer?
   var iceCandidates: [RTCIceCandidate]
   var sessionDescription: RTCSessionDescription?
   var videoView: RTCEAGLVideoView?
   var webRTCClient: WebRTCClient?
   var audioTrack: RTCAudioTrack?
   var mediaStream: RTCMediaStream?
    
    override init() {
        self.iceCandidates = []
    }
    
    func removeVideoRender() {
        if let render = videoView {
             self.videoTrack?.isEnabled = false
             self.videoTrack?.remove(render)
        }
    }
    
    public func setPeerConnection(_ connection: RTCPeerConnection) {
        self.peerConnection = connection
        self.peerConnection?.delegate = self
    }
    
    public func setMediaTrack(_ audio: RTCAudioTrack, video: RTCVideoTrack) {
        peerConnection?.add(audio, streamIds: [""])
        peerConnection?.add(video, streamIds: [""])
        guard let transceivers = peerConnection?.transceivers else {
            return
        }
        for transceiver in transceivers {
            transceiver.setDirection(.recvOnly, error: nil)
        }
    }
    
    public func storeIceCandiates(_ iceCandidate: RTCIceCandidate) {
           self.iceCandidates.append(iceCandidate)
    }
    
    func updateVideo()  {
        
    }
}

extension RemoteParticipant: RTCPeerConnectionDelegate {
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("Remote peerConnection new signaling state: \(stateChanged)")
        if stateChanged == .stable {
            for candidate in iceCandidates {
                peerConnection.add(candidate)
            }
            iceCandidates.removeAll()
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("Remote peerConnection did add stream")
        if (stream.audioTracks.count > 1 || stream.videoTracks.count > 1) {
            print("Weird looking stream")
        }
        self.videoTrack = stream.videoTracks.first
        DispatchQueue.main.async {
            self.videoTrack?.add(self.videoView!)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("Remote  peerConnection did remote stream")
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("Remote peerConnection should negotiate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("Remote  peerConnection new connection state: \(newState.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("Remote peerConnection new gathering state: \(newState.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        print("Remote peerConnection ice candidate: \(connectionId ?? "")")
        if let id = connectionId {
            self.delegate?.remotePeerConnectionIceCandidate(candidate, connectionId: id)
        } else {
            storeIceCandiates(candidate)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print("Remote peerConnection didRemove candidates")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("Remote peerConnection did open data channel")
    }
}
