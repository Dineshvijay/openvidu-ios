//
//  BaseViewController.swift
//  VideoChat
//
//  Created by Dinesh on 5/30/21.
//

import UIKit

class BaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate { [weak self] (context) in
            guard let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation else {
                return
            }
            if orientation == .landscapeLeft || orientation == .landscapeRight {
               
            } else {
                
            }
            self?.viewOrientationChanges()
            } completion: { (context) in
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if UIDevice.current.orientation.isLandscape {
            print("Landscape")
        } else {
            print("Portrait")
        }
        self.viewOrientationChanges()
    }
    
    func viewOrientationChanges() {
        
    }

}
