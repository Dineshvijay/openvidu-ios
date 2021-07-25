//
//  FloatingVideoView.swift
//  DraggleView
//
//  Created by Dinesh on 5/30/21.
//

import UIKit
import WebRTC

protocol FloatingVideoViewControlsDelegate: class {
    func muteMic(_ status: Bool)
    func muteVideo(_ status: Bool)
    func shareScreen(_ status: Bool)
    func flipCamera(_ status: Bool)
    func disconnectCall()
}
class FloatingVideoView: UIView {
    
    @IBOutlet weak var minimizeButton: UIButton!
    @IBOutlet weak var expandButton: UIButton!
    @IBOutlet weak var topViewControls: UIView!
    @IBOutlet private weak var controlView: UIView!
    @IBOutlet private weak var localVideoView: RTCEAGLVideoView!
    @IBOutlet private weak var remoteVideoView: RTCEAGLVideoView!
    
    @IBOutlet weak var cameraSwitchButton: UIButton!
    @IBOutlet weak var videoBtnImage: UIImageView!
    @IBOutlet private weak var micButton: UIButton!
    @IBOutlet private weak var screenShare: UIButton!
    @IBOutlet private weak var callEndButton: UIButton!
    @IBOutlet private weak var videoButton: UIButton!
    @IBOutlet private weak var remoteViewTopPin: NSLayoutConstraint!
    @IBOutlet private weak var remoteViewBottomPin: NSLayoutConstraint!
    @IBOutlet private weak var remoteViewLeftPin: NSLayoutConstraint!
    @IBOutlet private weak var remoteViewRightPin: NSLayoutConstraint!

    @IBOutlet weak var localVideoHeightPin: NSLayoutConstraint!
    @IBOutlet weak var localVideoWidthPin: NSLayoutConstraint!

    @IBOutlet weak var stackView: UIStackView!
    private var localViewTopLeftCornerFrame: CGRect!
    private var localViewTopRightCornerFrame: CGRect!
    private var localViewBottomLeftCornerFrame: CGRect!
    private var localViewBottomRightCornerFrame: CGRect!
    private var remoteViewTopLeftCornerFrame: CGRect!
    private var remoteViewTopRightCornerFrame: CGRect!
    private var remoteViewBottomLeftCornerFrame: CGRect!
    private var remoteViewBottomRightCornerFrame: CGRect!
    private var originalFrame: CGRect!
    private var manipulatedFrame: CGRect!
    public weak var controlDelegate: FloatingVideoViewControlsDelegate?
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func getRenderVideoView() -> (local: RTCEAGLVideoView, remote: RTCEAGLVideoView) {
        return(self.localVideoView, self.remoteVideoView)
    }
    
    func setup() {
        originalFrame = self.frame
        self.backgroundColor = .clear
        self.controlView.backgroundColor = .clear
        self.localVideoView.layer.borderColor = UIColor.red.cgColor
        self.remoteVideoView.layer.borderColor = UIColor.black.cgColor
        self.remoteVideoView.layer.borderWidth = 2.0
        self.localVideoView.layer.borderWidth = 2.0
        self.localVideoView.layer.masksToBounds = true
        self.remoteVideoView.layer.masksToBounds = true
        configureRoundedButtons(self.micButton)
        configureRoundedButtons(self.videoButton)
        configureRoundedButtons(self.screenShare)
        configureRoundedButtons(self.cameraSwitchButton)
        configureRoundedButtons(self.callEndButton, color: .red)
        manipulatedFrame = self.frame
        self.addRemoteViewPanGesture(self)
        self.remoteVideoView.bringSubviewToFront(self.localVideoView)
        self.remoteVideoView.bringSubviewToFront(self.controlView)
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.expandView(false)
            self.updateRemoteViewHotCorners()
        })
    }
    
    func configureRoundedButtons(_ button: UIButton, color: UIColor? = .black) {
        let buttonColor: UIColor = color == nil ? UIColor.black : color!
        button.layer.backgroundColor = buttonColor.withAlphaComponent(0.80).cgColor
        button.layer.cornerRadius = button.frame.width / 2
        button.layer.masksToBounds = true
    }
    
    @IBAction func micTap(_ button: UIButton) {
        guard let bgColor = button.layer.backgroundColor else {
            return
        }
        let mute = UIColor.red.withAlphaComponent(0.80).cgColor
        let unmute = UIColor.black.withAlphaComponent(0.80).cgColor
        if bgColor == mute {
            button.layer.backgroundColor = unmute
            self.controlDelegate?.muteMic(false)
        } else {
            button.layer.backgroundColor = mute
            self.controlDelegate?.muteMic(true)
        }
    }
    
    @IBAction func cameraSwitch(_ button: UIButton) {
        guard let bgColor = button.layer.backgroundColor else {
            return
        }
        let share = UIColor.red.withAlphaComponent(0.80).cgColor
        let unshare = UIColor.black.withAlphaComponent(0.80).cgColor
        if bgColor == unshare {
            button.layer.backgroundColor = share
            self.controlDelegate?.flipCamera(true)
        } else {
            button.layer.backgroundColor = unshare
            self.controlDelegate?.flipCamera(false)
        }
    }
    
    @IBAction func screenShareTap(_ button: UIButton) {
        guard let bgColor = button.layer.backgroundColor else {
            return
        }
        let share = UIColor.red.withAlphaComponent(0.80).cgColor
        let unshare = UIColor.black.withAlphaComponent(0.80).cgColor
        if bgColor == unshare {
            button.layer.backgroundColor = share
            self.controlDelegate?.shareScreen(true)
        } else {
            button.layer.backgroundColor = unshare
            self.controlDelegate?.shareScreen(false)
        }
    }
    
    @IBAction func callEndTap(_ sender: Any) {
        self.controlDelegate?.disconnectCall()
    }
    
    @IBAction func expandAction(_ sender: UIButton) {
        guard let image = sender.imageView?.image else {
            return
        }
        if image == UIImage(systemName: "arrow.up.backward.and.arrow.down.forward") {
            expandButton.setImage(UIImage(systemName: "arrow.down.right.and.arrow.up.left"), for: .normal)
            expand()
        } else {
            expandButton.setImage(UIImage(systemName: "arrow.up.backward.and.arrow.down.forward"), for: .normal)
            expand()
        }
        
    }
    
    @IBAction func videoAction(_ sender: UIButton) {
        guard let bgColor = sender.layer.backgroundColor else {
            return
        }
        sender.tintColor = .white
        let mute = UIColor.red.withAlphaComponent(0.80).cgColor
        let unmute = UIColor.black.withAlphaComponent(0.80).cgColor
        if bgColor == mute {
            sender.layer.backgroundColor = unmute
            self.controlDelegate?.muteVideo(false)
            videoBtnImage.image = UIImage(systemName: "video")
            self.localVideoView.isHidden = false
        } else {
            sender.layer.backgroundColor = mute
            self.controlDelegate?.muteVideo(true)
            self.localVideoView.isHidden = true
            videoBtnImage.image = UIImage(systemName: "video.slash")
        }
    }
    
    @IBAction func minimizeAction(_ sender: Any) {
        minimise()
    }
           
    private func addRemoteViewPanGesture(_ gView: UIView) {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleRemoteViewPanGesture(_:)))
        gView.addGestureRecognizer(panGesture)
    }
    
    @objc func expand() {
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            if self.originalFrame.width == self.frame.width && self.originalFrame.height ==  self.frame.height {
                self.expandView(true)
                self.updateRemoteViewHotCorners()
            } else {
                self.expandView(false)
            }
        })
    }
    
    @objc func handleRemoteViewPanGesture(_ gesture: UIPanGestureRecognizer) {
        if self.originalFrame.width == self.frame.width {
            return
        }
        if self.frame.height == CGFloat(44)  {
            return
        }
        if gesture.state == .changed {
         let translation = gesture.translation(in: self)
             self.center = CGPoint(x: self.center.x + translation.x, y: self.center.y + translation.y)
            gesture.setTranslation(.zero, in: self)
         } else if gesture.state == .ended {
            print("self.frame: \(self.frame)")
             if self.frame.intersects(self.remoteViewTopLeftCornerFrame) {
                  moveRemoteView(self.remoteViewTopLeftCornerFrame)
             } else if self.frame.intersects(self.remoteViewTopRightCornerFrame) {
                  moveRemoteView(self.remoteViewTopRightCornerFrame)
             } else if self.frame.intersects(self.remoteViewBottomRightCornerFrame) {
                  moveRemoteView(self.remoteViewBottomRightCornerFrame)
             } else if self.frame.intersects(self.remoteViewBottomLeftCornerFrame) {
                  moveRemoteView(self.remoteViewBottomLeftCornerFrame)
             } else {
                 print("Invalid corner")
                 moveRemoteView(self.remoteViewBottomRightCornerFrame)
             }
         }
    }

    private func moveRemoteView(_ frame: CGRect) {
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.frame = frame
        })
    }
    
    private func moveLocalView(_ frame: CGRect) {
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.localVideoView.frame = frame
        })
    }
    
    
    //Update this method when we do orientation
     private func expandView(_ animate: Bool) {
        self.remoteVideoView.layer.borderWidth = animate ? 2.0 : 0.0
        self.localVideoWidthPin.constant = animate ? UIConstraints.shrinkLocalVideoWidth : UIConstraints.defaultLocalVideoWidth
        self.localVideoHeightPin.constant = animate ? UIConstraints.shrinkLocalVideoHeight : UIConstraints.defaultLocalVideoHeight
        let yPin = animate ? self.frame.height - self.frame.height/2.45 : UIConstraints.constant
        let xPin = CGFloat(0)
        let height = animate ? (self.frame.height - self.frame.height/1.7) : self.originalFrame.height
        let width = animate ? (self.frame.width/2.3) : self.originalFrame.width
        let shrinkFrame = CGRect(x: xPin,
                                y: yPin,
                                width: width,
                                height: height)
        self.manipulatedFrame = animate ? shrinkFrame : originalFrame
        self.frame = self.manipulatedFrame
        print("self.manipulatedFrame: \(self.frame)")
        self.controlView.alpha =  animate ? 0.0 : 1.0
        self.localVideoView.alpha = animate ? 0.0 : 1.0
        self.remoteVideoView.alpha = 1.0
        //self.stackView.spacing = animate ? 10 : 30
        self.layoutIfNeeded()
    }
    
    private func minimise() {
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
           if self.frame.height != CGFloat(44) {
                self.minimizeScreen(true)
           } else {
                self.minimizeScreen(false)
           }
        })
    }
    
    private func minimizeScreen(_ animate: Bool) {
        let yPin = animate ? self.originalFrame.height - self.topViewControls.frame.height : CGFloat(0)
        let xPin = CGFloat(0)
        let height = animate ? CGFloat(44.0) : self.manipulatedFrame.height
        let minimizeFrame = CGRect(x: xPin,
                                y: yPin,
                                width: self.manipulatedFrame.width,
                                height: height)
        self.frame = animate ? minimizeFrame : self.manipulatedFrame
        self.controlView.alpha = animate ? 0.0 : 1.0
        self.remoteVideoView.alpha = animate ? 0.0 : 1.0
        self.localVideoView.alpha = animate ? 0.0 : 1.0
        self.layoutIfNeeded()
    }
    
    func updateRemoteViewHotCorners() {
        self.remoteViewTopLeftCornerFrame = CGRect(x: UIConstraints.constant, y: UIConstraints.constant, width: self.frame.width, height: self.frame.height)
        
        self.remoteViewTopRightCornerFrame = CGRect(x: (self.originalFrame.width - self.frame.width), y: UIConstraints.constant, width: self.frame.width, height: self.frame.height)
        
        self.remoteViewBottomLeftCornerFrame = CGRect(x: UIConstraints.constant, y: (self.originalFrame.height - self.frame.height), width: self.frame.width, height: self.frame.height)
        
        self.remoteViewBottomRightCornerFrame = CGRect(x: (self.originalFrame.width - self.frame.width), y: (self.originalFrame.height - self.frame.height), width: self.frame.width, height: self.frame.height)
    }
    
    func updateRemoteView(frame: CGRect) {
//        self.frame = frame
//        manipulatedFrame = self.frame
//        layoutIfNeeded()
    }
}
