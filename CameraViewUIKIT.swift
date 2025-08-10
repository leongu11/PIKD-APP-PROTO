//
//  CameraViewUIKIT.swift
//  pikdproto
//
//  Created by Leo Nguyen on 8/9/25.
//

import UIKit
import AVFoundation
import Vision

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
                    self.handleHandObs(observations)
                }
            } else {
                DispatchQueue.main.async {
                    self.overlayView.layer.sublayers?.forEach {$0.removeFromSuperlayer()}
                }
            }
        } catch {
            print("uh oh the shit couldnt perform:",error)
            }
        }
    }
    
    func handleHandObs(_ observations: [VNHumanHandPoseObservation]) {
        
        overlayView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        for obs in observations {
            guard let points = try? obs.recognizedPoints(.all) else { continue }
            for (_, point) in points {
                if point.confidence > 0.5 {
                    let normalizedPoint = CGPoint(x: point.location.x, y: 1 - point.location.y)
                    let screenPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: normalizedPoint)
                    drawPoint(screenPoint)
                }
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

