//
//  Participant.swift
//  VideoChat
//
//  Created by Dinesh on 5/30/21.
//

import Foundation
import WebRTC

protocol Participant {
    var name: String? { get set }
    var connectionId: String? { get set }
    var audioTrack: RTCAudioTrack? { get set }
    var videoTrack: RTCVideoTrack? { get set }
    var mediaStream: RTCMediaStream? { get set }
    var peerConnection: RTCPeerConnection? { get set }
    var videoCapturer: RTCVideoCapturer? { get set }
    var iceCandidates: [RTCIceCandidate] { get set }
    var sessionDescription: RTCSessionDescription? { get set }
    var videoView: RTCEAGLVideoView? { get set }
    var webRTCClient: WebRTCClient? { get set }
}
