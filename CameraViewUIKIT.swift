//
//  CameraViewUIKIT.swift
//  pikdproto
//
//  Created by Leo Nguyen on 8/9/25.
//

import UIKit
import AVFoundation
import Vision


//for camera inputs

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    let HandPoseReq = VNDetectHumanHandPoseRequest()
    let overlayView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set background color (in case camera fails)
        view.backgroundColor = .black
        
        setupCamera()
        setupOver()
        //        setupHelloWorldLabel()
    }
    
    func setupOver() {
        overlayView.frame = view.bounds
        overlayView.backgroundColor = .clear
        view.addSubview(overlayView)
    }
    
    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            print("Could not access camera")
            return
        }
        
        let vidOut = AVCaptureVideoDataOutput()
        vidOut.setSampleBufferDelegate(self, queue: DispatchQueue(label: "herro"))
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        if captureSession.canAddOutput(vidOut) {
            captureSession.addOutput(vidOut)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(previewLayer, below: view.layer.sublayers?.first)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    func captureOutput (_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
        let reqHandl = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try reqHandl.perform([HandPoseReq])
            if let observations = HandPoseReq.results, !observations.isEmpty {
                DispatchQueue.main.async {
                    handleHandObs(observations)
                }
            } else {
                DispatchQueue.main.async {
                    self.overlayView.layer.sublayers?.forEach {$0.removeFromSuperlayer()}
                }
            }
        } catch {
            print("uh oh the shit couldnt perform:",error)
            
        }
        
        
        
        func handleHandObs(_ observations: [VNHumanHandPoseObservation]) {
            
            overlayView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            
            for obs in observations {
                guard let recognizedPoints = try? obs.recognizedPoints(.all) else { continue }
                
                let allIndex: [VNHumanHandPoseObservation.JointName] = [
                    .indexTip, .indexDIP, .indexPIP, .indexMCP
                ]
                
                for Joint in allIndex {
                    if let index = recognizedPoints[Joint], index.confidence > 0.5 {
                        let normalizedPoint = CGPoint(x: index.location.x, y: 1 - index.location.y)
                        let screenPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: normalizedPoint)
                        drawPoint(screenPoint)
                    }
                }
                
//                for (_, point) in points {
//                    if point.confidence > 0.5 {
//                        let normalizedPoint = CGPoint(x: point.location.x, y: 1 - point.location.y)
//                        let screenPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: normalizedPoint)
//                        if let recognizedPoints = try? obs.recognizedPoints(.all),
//                           let indexTip = recognizedPoints[.indexTip] {
//                            drawPoint(screenPoint)
//                        }
//                    }
                }
            }
        }
        
        func drawPoint(_ point: CGPoint) {
            let circleLayer = CAShapeLayer()
            let radius: CGFloat = 6
            let circlePath = UIBezierPath(ovalIn: CGRect(x: point.x - radius/2, y: point.y - radius/2, width: radius, height: radius))
            circleLayer.path = circlePath.cgPath
            circleLayer.fillColor = UIColor.red.cgColor
            overlayView.layer.addSublayer(circleLayer)
        }
    
// uncomment this and use points from new index display/tracking to detect swipes -- connect with label makers to displays
//        func Detecting(_ LandmarkBuffer: points) {
//            
//        
//        func swipeDetected(_ dir: SwipeDir) {
//            let swipeLab = UILabel()
//            if dir == "right" {
//                swipeLab.text = "right fool"
//            }
//            
//            else if dir == "left" {
//                swipeLab.text = "left boi"
//            }
//            
//            else if dir == "down" {
//                swipeLab.text = "downii"
//            }
//            
//            else if dir == "up" {
//                swipeLab.text = "upping"
//            }
//            swipeLab.font = UIFont.systemFont(ofSize: 36, weight: .bold)
//            swipeLab.textColor = .white
//            swipeLab.translatesAutoresizingMaskIntoConstraints = false
//            
//            view.addSubview(swipeLab)
//            NSLayoutConstraint.activate([
//                swipeLab.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//                swipeLab.centerYAnchor.constraint(equalTo: view.centerYAnchor)
//            ])
//        }
}
//    func setupHelloWorldLabel() {
//        let label = UILabel()
//        label.text = "Hello World"
//        label.font = UIFont.systemFont(ofSize: 36, weight: .bold)
//        label.textColor = .white
//        label.translatesAutoresizingMaskIntoConstraints = false
//
//        view.addSubview(label)
//
//        NSLayoutConstraint.activate([
//            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
//        ])
// 
//    }
