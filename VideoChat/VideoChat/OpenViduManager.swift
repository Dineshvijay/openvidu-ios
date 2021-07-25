//
//  OpenViduManager.swift
//  VideoChat
//
//  Created by Dinesh on 5/30/21.
//

import Foundation
import WebRTC
protocol OpenViduManagerDelegate: class {
    func addIceCandiate(_ params: [String: Any])
    func muteLocalAudioTrack(_ volume: Bool)
    func muteLocalVideoTrack(_ isHide: Bool)
    func isFrontCameraHide(_ isHide: Bool)
}
protocol OpenViduManagerUIDelegate: class {
    func remoteParticipantLeft()
    func remoteParticipantJoined()
}
class OpenViduManager {
    weak var delegate: OpenViduManagerDelegate?
    weak var uidelegate: OpenViduManagerUIDelegate?
    static let shared = OpenViduManager()
    private var socketClient: SocketClient!
    private var webRTCClient: WebRTCClient!
    private var sessionId: String!
    private var tokenId: String!
    private var localVideoRender: RTCEAGLVideoView!
    private var remoteVideoRender: RTCEAGLVideoView!
    public var event: [String: Int] = [:]
    public var testView: UIView!
    
    func connect(urlString: String, sessionId: String, tokenId: String, localView: RTCEAGLVideoView, remoteView: RTCEAGLVideoView) {
        self.sessionId = sessionId
        self.tokenId = tokenId
        self.localVideoRender = localView
        self.remoteVideoRender = remoteView
        webRTCClient = WebRTCClient()
        OpenViduManager.shared.delegate = webRTCClient
        webRTCClient.delegate = self
        socketClient = SocketClient(urlString: urlString)
        socketClient.delegate = self
    }
    
    func disconnect() {
        self.leaveRoom()
    }
    
    private func handleSignalEvents(_ json: [String: Any]) {
        if json[JSONConstants.Params] != nil {
            let method = json[JSONConstants.Method] as! String
            let params = json[JSONConstants.Params] as! Dictionary<String, Any>
            switch method {
                case JSONConstants.IceCandidate:
                    print("handleSignalEvents IceCandidate: \(params)")
                    self.delegate?.addIceCandiate(params)
                case JSONConstants.ParticipantJoined:
                     print("handleSignalEvents ParticipantJoined: \(params)")
                     handleParticipantJoined(json)
                case JSONConstants.ParticipantPublished:
                     print("handleSignalEvents ParticipantPublished: \(params)")
                     handleParticipantPublished(params)
                case JSONConstants.ParticipantLeft:
                     print("handleSignalEvents ParticipantLeft: \(params)")
                     handleParticipantLeft(params)
            default:
                print("Error handleMethod, " + "method '" + method + "' is not implemented")
            }
        }
    }
    
    private func handleSignalResponse(_ json: [String: Any]) {
        let responseId = json[JSONConstants.Id] as! Int
        let result: [String: Any] = json[JSONConstants.Result] as! [String: Any]
        if responseId == event["joinRoom"] {
            guard let connectionId = result[JSONConstants.Id] as? String else {
                return
            }
            print("joinRoom success: \(connectionId)")
            webRTCClient.createLocalPeerConnection(localVideoRender, connnectionId: connectionId)
            handleAlreadyJoinedParticipant(result)
        } else if responseId == event["publishVideo"] {
            if let result = json[JSONConstants.Result] as? [String: Any],
                let answer = result["sdpAnswer"] as? String {
                webRTCClient.setLocalPeerConnectAnswer(answer)
            }
        } else if responseId == event["receiveVideoFrom"] {
            if let result = json[JSONConstants.Result] as? [String: Any],
                let answer = result["sdpAnswer"] as? String {
                webRTCClient.setRemotePeerConnectAnswer(answer)
            }
        }
    }
    
    func handleAlreadyJoinedParticipant(_ json: [String: Any]) {
        guard let result = json[JSONConstants.Value] as? [[String: Any]], result.count > 0 else {
            return
        }
        for remoteUser in result {
            let metadataString = remoteUser[JSONConstants.Metadata] as! String
            let json = metadataString.data(using: .utf8)!.toJSON()
            if let name = json?["clientData"] as? String,
                !name.contains("_SCREEN"),
                let connectionId = remoteUser[JSONConstants.Id] as? String,
                let streams = remoteUser["streams"] as? [[String: Any]],
                let streamId = streams[0]["id"] as? String  {
                print("AlreadyJoinedParticipant user: \(name) and connectionId: \(connectionId)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                     self.uidelegate?.remoteParticipantJoined()
                     self.webRTCClient.createRemotePeerConnection(name, connectionId: connectionId,
                                                render: self.remoteVideoRender, streamId: streamId)
                }
                //As of now supporting only one already joined remote participant
                return
            }
        }
    }
    
    func handleParticipantJoined(_ json: [String: Any]) {
        guard let params = json[JSONConstants.Params] as? [String: Any],
            let connectionId = params[JSONConstants.Id] as? String else {
            return
        }
        let metadataString = params[JSONConstants.Metadata] as! String
        let json = metadataString.data(using: .utf8)!.toJSON()
        guard let name = json?["clientData"] as? String,
            !name.contains("_SCREEN") else {
            return
        }
        self.uidelegate?.remoteParticipantJoined()
        webRTCClient.createRemotePeerConnection(name, connectionId: connectionId, render: remoteVideoRender)
    }
    
    func handleParticipantPublished(_ json: [String: Any]) {
        print("handleParticipantPublished: \(json)")
        guard let streams = json["streams"] as? [[String: Any]],
            let streamId = streams[0]["id"] as? String else {
            return
        }
        webRTCClient.createRemotePeerConnectionOffer(streamId)
    }
    
    func handleParticipantLeft(_ json: [String: Any]) {
        guard let connectionId = json[JSONConstants.ConnectionId] as? String else {
            return
        }
        self.uidelegate?.remoteParticipantLeft()
        webRTCClient.remoteParticiapntLeft(connectionId)
    }
    
    func handleScreenShare(_ isShare: Bool) {
        webRTCClient.shareLocalPeerScreen(isShare)
    }
    
    func handleFlipCamera(_ isFlip: Bool) {
        webRTCClient.flipCamera(isFlip)
    }
}

extension OpenViduManager: WebRTCClientDelegate {

    func onIceCandidate(_ iceCandidate: RTCIceCandidate, connectionId: String) {
        sendIceCandidate(iceCandidate, connectionId: connectionId)
    }
    
    func publishLocalStreamVideo(_ localDescription: String) {
        publishLocalStream(localDescription)
    }
    
    func receiveRemoteVideoStream(_ remoteDescription: String, streamId: String) {
        self.receiveVideoFrom(remoteDescription, streamId: streamId)
    }
}

extension OpenViduManager: SocketClientDelegate {
    func socketConnected() {
        print("Socket connected")
        joinRoom()
    }
    
    func socketDisconnected(_ error: String) {
        print("Socket disconnected \(error)")
    }
    
    func socketReceive(message: String) {
        print("socketReceive: \(message)")
        let data = message.data(using: .utf8)!
        do {
            let json: [String: Any] = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as! [String : Any]
            if json[JSONConstants.Result] != nil {
                handleSignalResponse(json)
            } else {
                handleSignalEvents(json)
            }
        } catch let error as NSError {
            print("ERROR parsing JSON: ", error)
        }
    }
}

//OpenVidu events
extension OpenViduManager {
    private func joinRoom() {
        var params: [String: String] = [:]
        //params["recorder"] = "false"
        params["platform"] = "iOS"
        params[JSONConstants.Metadata] = "{\"clientData\": \"" + "iOS-User" + "\"}"
        params["secret"] = ""
        params["session"] = sessionId
        params["token"] = tokenId
        var json: [String: Any] = [JSONConstants.Params: params]
        json[JSONConstants.Method] = "joinRoom"
        let id = socketClient.sendJSON(json)
        event["joinRoom"] = id
    }
    
    private func leaveRoom() {
        let json: [String: Any] = [JSONConstants.Method: JSONConstants.LeaveRoom]
        let id = socketClient.sendJSON(json)
        event[JSONConstants.LeaveRoom] = id
    }
    
    private func sendIceCandidate(_ iceCandidate: RTCIceCandidate, connectionId: String) {
        var params: [String: String] = [:]
        params["sdpMid"] = iceCandidate.sdpMid
        params["sdpMLineIndex"] = String(iceCandidate.sdpMLineIndex)
        params["candidate"] = String(iceCandidate.sdp)
        params["endpointName"] =  connectionId
        var json: [String: Any] = [JSONConstants.Params: params]
        json[JSONConstants.Method] = "onIceCandidate"
        _ = socketClient.sendJSON(json)
        //event["onIceCandidate"] = id
    }
    
    private func publishLocalStream(_ sdp: String) {
        var params: [String:String] = [:]
        params["audioActive"] = "true"
        params["videoActive"] = "true"
        params["doLoopback"] = "false"
        params["hasAudio"] = "true"
        params["hasVideo"] = "true"
        params["frameRate"] = "30"
        params["typeOfVideo"] = "CAMERA"
        params["videoDimensions"] = "{\"width\":640,\"height\":480}"
        params["sdpOffer"] = sdp
        var json: [String: Any] = [JSONConstants.Params: params]
        json[JSONConstants.Method] = "publishVideo"
        let id = socketClient.sendJSON(json)
        event["publishVideo"] = id
    }
    
    private func receiveVideoFrom(_ sdp: String, streamId: String) {
        var params: [String:String] = [:]
        params["sdpOffer"] = sdp
        params["sender"] = streamId
        var json: [String: Any] = [JSONConstants.Params: params]
        json[JSONConstants.Method] = "receiveVideoFrom"
        let id = socketClient.sendJSON(json)
        event["receiveVideoFrom"] = id
    }
}

extension OpenViduManager {
    func muteMic(_ value: Bool) {
        self.delegate?.muteLocalAudioTrack(value)
    }
    
    func muteVideo(_ value: Bool) {
        self.delegate?.muteLocalVideoTrack(value)
    }
}
