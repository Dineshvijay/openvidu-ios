//
//  JSONConstants.swift
//  WebRTCapp
//
//  Created by Sergio Paniego Blanco on 02/05/2018.
//  Copyright © 2018 Sergio Paniego Blanco. All rights reserved.
//
import UIKit

struct JSONConstants {
    static let Value = "value"
    static let Params = "params"
    static let Method = "method"
    static let Id = "id"
    static let Result = "result"
    static let IceCandidate = "iceCandidate"
    static let ParticipantJoined = "participantJoined"
    static let ParticipantPublished = "participantPublished"
    static let ParticipantLeft = "participantLeft"
    static let PrepareReceiveVideoFrom = "prepareReceiveVideoFrom"
    static let PublishVideo = "publishVideo"
    static let ReceiveVideoFrom = "receiveVideoFrom"
    static let SessionId = "sessionId"
    static let SdpAnswer = "sdpAnswer"
    static let JoinRoom = "joinRoom"
    static let Metadata = "metadata"
    static let JsonRPC = "jsonrpc"
    static let ConnectionId = "connectionId"
    static let LeaveRoom = "leaveRoom"
}

struct App {
    static var userName: String = "iOS"
    static var videoWidth: CGFloat = 0.0
    static var videoHeight: CGFloat = 0.0
}
