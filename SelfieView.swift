//
//  SelfieView.swift
//  PIKD PROTOTYPE XCODE
//
//  Created by Leo Nguyen on 8/9/25.
// its the wrapper from UIkit to SwiftUI

import UIKit
import SwiftUI

struct CameraView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CameraViewController {
        CameraViewController()
    }
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}
