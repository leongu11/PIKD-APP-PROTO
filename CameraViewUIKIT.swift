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
    let maxFrames = 25
    var xBuffer = [CGFloat]()
    var yBuffer = [CGFloat]()
    var prevDir = "none"
    
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
                    
                        if Joint == .indexTip {
                            xBuffer.append(index.location.x)
                            yBuffer.append(index.location.y)
                            //debug this shit too
                            if xBuffer.count > maxFrames {
                                xBuffer.removeFirst(xBuffer.count - maxFrames)
                                
                            }
                            
                            if yBuffer.count > maxFrames{
                                yBuffer.removeFirst(yBuffer.count - maxFrames)
                            }
                            
                            Detecting(xBuffer: xBuffer, yBuffer: yBuffer)
                        }
                        
                    }
                }
                }
            }
        }
        
        func removeLabel(_ tag: Int) {
            view.viewWithTag(tag)?.removeFromSuperview()
            
        }
        func drawPoint(_ point: CGPoint) {
            let circleLayer = CAShapeLayer()
            let radius: CGFloat = 6
            let circlePath = UIBezierPath(ovalIn: CGRect(x: point.x - radius/2, y: point.y - radius/2, width: radius, height: radius))
            circleLayer.path = circlePath.cgPath
            circleLayer.fillColor = UIColor.red.cgColor
            overlayView.layer.addSublayer(circleLayer)
        }
    
        func Detecting(xBuffer: Array<CGFloat>, yBuffer: Array<CGFloat>) {
            if let xBufF = xBuffer.first, let xBufL = xBuffer.last, let yBufF = yBuffer.first, let yBufL = yBuffer.last {
                let disY = xBufF - xBufL
                let disX = yBufF - yBufL
                
                var differentiateFlag = "none"
                
                if abs(disX) > abs(disY) {
                    differentiateFlag = "horiz"
                }
                
                else {
                    differentiateFlag = "vert"
                }
                
                //detecting swipes
                
                let disXply = String(format: "%.2f %.2f", abs(disX), abs(disY))
                
                DispatchQueue.main.async {
                    self.showDelta(dt: disXply)
                }
                
                if disX <= -0.2, differentiateFlag == "horiz"{
                    DispatchQueue.main.async {
                        self.swipeDetected(dir: "left")
                    }
                }
                
                else if disX >= 0.2, differentiateFlag == "horiz" {
                    DispatchQueue.main.async {
                        self.swipeDetected(dir: "right")
                    }
                }
                
                else {
                    DispatchQueue.main.async {
                        self.swipeDetected(dir: "none")
                    }

                }
                
                if disY >= 0.2, differentiateFlag == "vert" {
                    DispatchQueue.main.async {
                        self.swipeDetected(dir: "up")
                    }
                }
                
                else if disY <= -0.2, differentiateFlag == "vert" {
                    DispatchQueue.main.async {
                        self.swipeDetected(dir: "down")
                    }
                }
                
                else {
                    DispatchQueue.main.async {
                        self.swipeDetected(dir: "none")
                    }
                }
            }
        }
            
        func showDelta(dt: String) {
            let deltaShow = UILabel()
            deltaShow.text = dt
            removeLabel(41)
            deltaShow.font = UIFont.systemFont(ofSize: 36, weight: .bold)
            deltaShow.textColor = .white
            deltaShow.translatesAutoresizingMaskIntoConstraints = false
            deltaShow.tag = 41
            
            view.addSubview(deltaShow)
                        
            NSLayoutConstraint.activate([
                deltaShow.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                deltaShow.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }
        func swipeDetected(dir: String) {
            let swipeLab = UILabel()
            if dir == "right" {
                swipeLab.text = "right fool"
            }
            
            else if dir == "left" {
                swipeLab.text = "left boi"
            }
            
            else if dir == "down" {
                swipeLab.text = "downii"
            }
            
            else if dir == "up" {
                swipeLab.text = "upping"
            }
            
            else {
                swipeLab.text = ""
            }
            
            removeLabel(67)
            print(dir)
            swipeLab.font = UIFont.systemFont(ofSize: 36, weight: .bold)
            swipeLab.textColor = .white
            swipeLab.translatesAutoresizingMaskIntoConstraints = false
            swipeLab.tag = 67
            
            view.addSubview(swipeLab)
                        
            NSLayoutConstraint.activate([
                swipeLab.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                swipeLab.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }
}

