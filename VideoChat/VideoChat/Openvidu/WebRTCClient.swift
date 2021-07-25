//
//  WebRTCClient.swift
//  VideoChat
//
//  Created by Dinesh on 5/30/21.
//

import Foundation
import WebRTC
protocol WebRTCClientDelegate: class {
    func onIceCandidate(_ iceCandidate: RTCIceCandidate, connectionId: String)
    func publishLocalStreamVideo(_ localDescription: String)
    func receiveRemoteVideoStream(_ remoteDescription: String, streamId: String)
}

class WebRTCClient: NSObject {
    weak var delegate: WebRTCClientDelegate?
    var peerConnectionFactory: RTCPeerConnectionFactory?
    var localParticipant: LocalParticipant?
    var remoteParticipant: RemoteParticipant?
    var remotePartcipants: [String: RemoteParticipant]?
    
    override init() {
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        let option = RTCPeerConnectionFactoryOptions()
        peerConnectionFactory = RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
        peerConnectionFactory?.setOptions(option)
    }
    
    private func getMediaConstraints() -> RTCMediaConstraints {
        let mandatoryConstraints = ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "true"]
        let optionalConstraint = ["DtlsSrtpKeyAgreement": "true"]
        return RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: optionalConstraint)
    }
    
    private func getPeerConnection() -> RTCPeerConnection? {
        let config = RTCConfiguration()
        config.tcpCandidatePolicy = .enabled
        config.bundlePolicy = .maxBundle
        config.rtcpMuxPolicy = .negotiate
        config.continualGatheringPolicy = .gatherContinually
        config.keyType = .ECDSA
        config.activeResetSrtpParams = true
        config.sdpSemantics = .unifiedPlan
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        return peerConnectionFactory?.peerConnection(with: config, constraints: getMediaConstraints(), delegate: nil)
    }
    
    func createLocalPeerConnection(_ render: RTCEAGLVideoView, connnectionId: String) {
        let peerConnection = getPeerConnection()
        self.localParticipant = LocalParticipant()
        self.localParticipant?.connectionId = connnectionId
        self.localParticipant?.videoView = render
        self.localParticipant?.webRTCClient = self
        self.localParticipant?.delegate = self
        self.localParticipant?.setPeerConnection(peerConnection!)
        self.localParticipant?.startCamera(false)
        setLocalPeerConnectionOffer()
    }
    
    private func setLocalPeerConnectionOffer() {
        let mandatoryConstraints = ["OfferToReceiveAudio": "true","OfferToReceiveVideo": "true"]
        let sdpConstraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
        self.localParticipant?.peerConnection?.offer(for: sdpConstraints, completionHandler: { (sessionDescription, error) in
            guard let sdpDescription = sessionDescription else {
                print("LocalPeer SDP offer error: \(error?.localizedDescription ?? "")")
                return
            }
            print("LocalPeer SDP offer set")
            self.localParticipant?.peerConnection?.setLocalDescription(sdpDescription,
                                                                       completionHandler: { (error) in
                print("LocalPeer local SDP set: \(error?.localizedDescription ?? "") ")
                self.delegate?.publishLocalStreamVideo(sdpDescription.sdp)
            })
        })
    }
    
    func setLocalPeerConnectAnswer(_ answer: String) {
        let sessionDescription = RTCSessionDescription(type: .answer, sdp: answer)
        self.localParticipant?.peerConnection?.setRemoteDescription(sessionDescription, completionHandler: { (error) in
            print("Local peer remote sdp done")
            guard var iceCandidates = self.localParticipant?.iceCandidates else {
                return
            }
            for candidate in iceCandidates {
                self.localParticipant?.peerConnection?.add(candidate)
            }
            iceCandidates.removeAll()
        })
    }
    
    func createRemotePeerConnection(_ participantName: String, connectionId: String, render: RTCEAGLVideoView, streamId: String? = nil) {
        guard let peerConnection = getPeerConnection() else {
            return
        }
        print("createRemotePeerConnection done")
        let remotePartcipant = RemoteParticipant()
        remotePartcipant.webRTCClient = self
        remotePartcipant.delegate = self
        remotePartcipant.name = participantName
        remotePartcipant.connectionId = connectionId
        remotePartcipant.setPeerConnection(peerConnection)
        remotePartcipant.videoTrack = localParticipant?.remoteVideoTrack
        remotePartcipant.videoView = render
        self.remoteParticipant = remotePartcipant
        if let streamID = streamId {
            createRemotePeerConnectionOffer(streamID)
        }
    }
    
    func createRemotePeerConnectionOffer(_ streamId: String) {
        let mandatoryConstraints = ["OfferToReceiveAudio": "true","OfferToReceiveVideo": "true"]
        let sdpConstraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
        self.remoteParticipant?.peerConnection?.offer(for: sdpConstraints, completionHandler: { (sessionDescription, error) in
            guard let sdpDescription = sessionDescription else {
                print("Remote Peer SDP offer error: \(error?.localizedDescription ?? "")")
                return
            }
            print("Remote Peer SDP offer set")
            self.remoteParticipant?.peerConnection?.setLocalDescription(sdpDescription,
                                                                       completionHandler: { (error) in
                print("Remote Peer local SDP set: \(error?.localizedDescription ?? "") ")
               self.delegate?.receiveRemoteVideoStream(sdpDescription.sdp, streamId: streamId)
            })
        })
    }
    
    func shareLocalPeerScreen(_ isShare: Bool) {
        localParticipant?.recordScreen(isShare)
    }
    
    func flipCamera(_ isFlip: Bool) {
        localParticipant?.flipCamera(isFlip)
    }
    
    func setRemotePeerConnectAnswer(_ answer: String) {
        let sessionDescription = RTCSessionDescription(type: .answer, sdp: answer)
        self.remoteParticipant?.peerConnection?.setRemoteDescription(sessionDescription, completionHandler: { (error) in
            print("Remote peer remote sdp done")
//            guard var iceCandidates = self.remoteParticipant?.iceCandidates else {
//                return
//            }
//            for candidate in iceCandidates {
//                self.remoteParticipant?.peerConnection?.add(candidate)
//            }
//            iceCandidates.removeAll()
            self.remoteParticipant?.updateVideo()
        })
    }
    
    func remoteParticiapntLeft(_ connectionId: String) {
        DispatchQueue.main.async {
             self.remoteParticipant?.removeVideoRender()
             self.remoteParticipant = nil
        }
    }
}

extension WebRTCClient: LocalParticipantDelegate {
    func localPeerConnectionIceCandidate(_ iceCandidate: RTCIceCandidate, connectionId: String) {
        self.delegate?.onIceCandidate(iceCandidate, connectionId: connectionId)
    }
}

extension WebRTCClient: RemoteParticipantDelegate {
    func remotePeerConnectionIceCandidate(_ iceCandidate: RTCIceCandidate, connectionId: String) {
         self.delegate?.onIceCandidate(iceCandidate, connectionId: connectionId)
    }
}

extension WebRTCClient: OpenViduManagerDelegate {
    func addIceCandiate(_ params: [String : Any]) {
        let iceCandidate = RTCIceCandidate(sdp: params["candidate"] as! String, sdpMLineIndex: params["sdpMLineIndex"] as! Int32, sdpMid: params["sdpMid"] as? String)
        let connectionId = params["senderConnectionId"] as? String ?? ""
        let isRemote = self.localParticipant!.connectionId != connectionId ? true : false
        print("let isRemote: \(isRemote)")
        let user = isRemote ? self.remoteParticipant : self.localParticipant
        guard var participant = user as? Participant else {
            print("Participant object undefined")
            return
        }
        let peerConnection = participant.peerConnection
        let isRemoteDescription = peerConnection?.remoteDescription
        if  isRemoteDescription != nil {
            print("remoteParticipant-peerConnection add iceCandidate")
            peerConnection?.add(iceCandidate)
        } else {
            print("localParticipant-iceCandidates append")
            participant.iceCandidates.append(iceCandidate)
        }
    }
    
    func muteLocalAudioTrack(_ volume: Bool) {
        DispatchQueue.main.async {
            print("volume: \(volume)")
            self.localParticipant?.audioTrack?.source.volume = !volume ? 0.0 : 10.0
        }
    }
    
    func isFrontCameraHide(_ isHide: Bool) {
        DispatchQueue.main.async {
            self.localParticipant?.videoTrack?.isEnabled = !isHide
        }
    }
    
    func muteLocalVideoTrack(_ isHide: Bool) {
        DispatchQueue.main.async {
            self.localParticipant?.videoTrack?.isEnabled = !isHide
        }
    }
}
