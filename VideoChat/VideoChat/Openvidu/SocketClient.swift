//
//  SocketClient.swift
//  VideoChat
//
//  Created by Dinesh on 5/30/21.
//

import Foundation
import Starscream

protocol SocketClientDelegate: class {
    func socketConnected()
    func socketDisconnected(_ error: String)
    func socketReceive(message: String)
}

class SocketClient {
    var delegate: SocketClientDelegate?
    private var webSocket: WebSocket
    private var jsonId: Int = 0
    private var timer: Timer?
    
    init(urlString: String) {
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        webSocket = WebSocket(request: request)
        webSocket.disableSSLCertValidation = true
        webSocket.delegate = self
        webSocket.connect()
    }
    
    private func pingMessageHandler() {
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(SocketClient.doPing), userInfo: nil, repeats: true)
        doPing()
    }
    
    @objc private func doPing() {
        var pingParams: [String: Any] = [JSONConstants.Params: ["interval": "5000"]]
        pingParams[JSONConstants.Method] = "ping"
        _ = sendJSON(pingParams)
    }
    
    func sendJSON(_ json: [String: Any]) -> Int {
        var params = json
        params[JSONConstants.Id] = "\(jsonId)"
        params[JSONConstants.JsonRPC] = "2.0"
        guard let msg = params.toJsonString() else {
            print("toJsonString error")
            return 0
        }
        print("Socket Sending: \(msg)")
        webSocket.write(string: msg)
        let writeId = jsonId
        jsonId += 1
        return writeId
    }
    
    func disconnect() {
        if webSocket.isConnected {
            self.webSocket.disconnect()
        }
    }
}

extension SocketClient: WebSocketDelegate {
    
    func websocketDidConnect(socket: WebSocketClient) {
        pingMessageHandler()
        self.delegate?.socketConnected()
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        self.delegate?.socketDisconnected(error?.localizedDescription ?? "Something went wrong")
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        self.delegate?.socketReceive(message: text)
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        
    }
}

