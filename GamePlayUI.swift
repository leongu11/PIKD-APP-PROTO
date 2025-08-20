//
//  GamePlayUI.swift
//  PIKD PROTOTYPE XCODE
//
//  Created by Leo Nguyen on 8/17/25.
//

import Foundation
import UIKit

class BoxViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let myBox = UIView()
        
        myBox.backgroundColor = .systemBlue
        myBox.frame = CGRect(x: 100, y: 100, width: 100, height: 100)
        myBox.layer.cornerRadius = 12
        myBox.layer.shadowOpacity = 0.5
        
        view.addSubview (myBox)
    }
}
