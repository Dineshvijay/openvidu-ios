//
//  ViewController.swift
//  VideoChat
//
//  Created by Dinesh on 5/30/21.
//

import UIKit
import WebRTC
import MBProgressHUD

class ViewController: BaseViewController {

    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var sessionName: UITextField!
    var localVideoView: RTCEAGLVideoView!
    var remoteVideoView: RTCEAGLVideoView!
    var floatingView: FloatingVideoView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setStyles()
    }
    
    func setStyles() {
        joinButton.layer.cornerRadius = 20.0
        joinButton.layer.masksToBounds = true
        userName.delegate = self
        sessionName.delegate = self
    }

    @IBAction func showPage(_ sender: Any) {
        let vc = self.storyboard!.instantiateViewController(identifier: "ViewController2")
        self.navigationController!.pushViewController(vc, animated: true)
        
    }
    
    @IBAction func join(_ sender: Any) {
        guard let name = userName.text, let roomId = sessionName.text,
              !name.isEmpty, !roomId.isEmpty else {
            assertionFailure("🚨: Room ID and User name should not empty!!!")
            return
        }
        App.userName = name
        App.videoWidth = self.view.frame.width
        App.videoHeight = self.view.frame.height
        let progress = MBProgressHUD.showAdded(to: self.view, animated: true)
        progress.mode = .indeterminate
        HttpClient.getToken(forSession: roomId) { (token) in
            DispatchQueue.main.async {
                progress.hide(animated: true)
                if !token.isEmpty {
                    self.start(self.sessionName.text!, token: token)
                }
            }
        }
        //self.start("", token: "")
    }
    
    func configureFloatingViewWithXIB() {
        if let floatingVideoView = Bundle.main.loadNibNamed("FloatingVideoView", owner: self, options: nil)?.first as? FloatingVideoView, let window = UIApplication.shared.windows.first  {
            if let existingFloatingVideoView = window.subviews.filter({ $0.tag == floatingVideoViewTag}).first as? FloatingVideoView {
                 self.floatingView = existingFloatingVideoView
                 window.bringSubviewToFront(existingFloatingVideoView)
            } else {
                self.floatingView = floatingVideoView
                self.floatingView.controlDelegate = self
                self.floatingView.frame = self.view.bounds
                self.floatingView.tag = floatingVideoViewTag
                window.addSubview(self.floatingView)
                window.bringSubviewToFront(self.floatingView)
                self.floatingView.setup()
            }
        }
    }
    
    func start(_ session: String, token: String) {
        configureFloatingViewWithXIB()
        (self.localVideoView, self.remoteVideoView) = self.floatingView.getRenderVideoView()
        self.remoteVideoView.isUserInteractionEnabled = true
        self.localVideoView.isUserInteractionEnabled = true
        OpenViduManager.shared.uidelegate = self
        OpenViduManager.shared.testView = UIApplication.shared.windows.first!.rootViewController!.view
        OpenViduManager.shared.connect(urlString: "https://demos.openvidu.io/openvidu",
                                          sessionId: session,
                                          tokenId: token,
                                          localView: self.localVideoView,
                                          remoteView: self.remoteVideoView)
        
    }
    
    override func viewOrientationChanges() {
        super.viewOrientationChanges()
        print("self.view.bounds: \(self.view.bounds)")
        if floatingView != nil {
            floatingView.updateRemoteView(frame: self.view.bounds)
        }
    }
    
}

extension ViewController: FloatingVideoViewControlsDelegate {
    func muteVideo(_ status: Bool) {
        OpenViduManager.shared.muteVideo(status)
    }
    
    func muteMic(_ status: Bool) {
        print("Mic tapped")
        OpenViduManager.shared.muteMic(status)
    }
    
    func shareScreen(_ status: Bool) {
        print("sharing screen tap")
        OpenViduManager.shared.handleScreenShare(status)
    }
    
    func disconnectCall() {
        print("disconnect call")
        OpenViduManager.shared.disconnect()
        floatingView.removeFromSuperview()
    }
    
    func flipCamera(_ status: Bool) {
        print("Flip camera tap")
        OpenViduManager.shared.handleFlipCamera(status)
    }
}

extension ViewController: OpenViduManagerUIDelegate {
    func remoteParticipantJoined() {
        print("remoteParticipantJoined")
        
    }
    
    func remoteParticipantLeft() {
        print("remoteParticipantLeft")
    }
}

extension ViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
