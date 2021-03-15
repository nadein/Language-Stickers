//
//  CaptureSessionManager.swift
//  Language Stickers
//
//  Created by Alex Nadein on 15.03.2021.
//

import UIKit
import AVFoundation

class CaptureSessionManager: NSObject {
  
  // MARK: - Properties
  
  private weak var previewView: UIView!
  
  private var bufferSize: CGSize = .zero
  private var rootLayer: CALayer! = nil
  private var previewLayer: AVCaptureVideoPreviewLayer! = nil
  
  private let session = AVCaptureSession()
  private let videoDataOutput = AVCaptureVideoDataOutput()
  private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
  
  // MARK: - Init
  
  init(previewView: UIView) {
    super.init()
    self.previewView = previewView
  }
  
  func setupCaptureSession() {
    var deviceInput: AVCaptureDeviceInput!
    
    // Select a video device, make an input
    let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first
    do {
      deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
    } catch {
      print("Could not create video device input: \(error)")
      return
    }
    
    session.beginConfiguration()
    session.sessionPreset = .vga640x480 // Model image size is smaller.
    
    // Add a video input
    guard session.canAddInput(deviceInput) else {
      print("Could not add video device input to the session")
      session.commitConfiguration()
      return
    }
    session.addInput(deviceInput)
    if session.canAddOutput(videoDataOutput) {
      session.addOutput(videoDataOutput)
      // Add a video data output
      videoDataOutput.alwaysDiscardsLateVideoFrames = true
      videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
      videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
    } else {
      print("Could not add video data output to the session")
      session.commitConfiguration()
      return
    }
    let captureConnection = videoDataOutput.connection(with: .video)
    // Always process the frames
    captureConnection?.isEnabled = true
    do {
      try  videoDevice!.lockForConfiguration()
      let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice?.activeFormat.formatDescription)!)
      bufferSize.width = CGFloat(dimensions.width)
      bufferSize.height = CGFloat(dimensions.height)
      videoDevice!.unlockForConfiguration()
    } catch {
      print(error)
    }
    session.commitConfiguration()
    previewLayer = AVCaptureVideoPreviewLayer(session: session)
    previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    rootLayer = previewView.layer
    previewLayer.frame = rootLayer.bounds
    rootLayer.addSublayer(previewLayer)
  }
  
  func startCaptureSession() {
    session.startRunning()
  }
  
  func teardownAVCapture() {
    previewLayer.removeFromSuperlayer()
    previewLayer = nil
  }
  
  public func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
    let curDeviceOrientation = UIDevice.current.orientation
    let exifOrientation: CGImagePropertyOrientation
    
    switch curDeviceOrientation {
    case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
      exifOrientation = .left
    case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, home button on the right
      exifOrientation = .upMirrored
    case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, home button on the left
      exifOrientation = .down
    case UIDeviceOrientation.portrait:            // Device oriented vertically, home button on the bottom
      exifOrientation = .up
    default:
      exifOrientation = .up
    }
    return exifOrientation
  }
}

extension CaptureSessionManager: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ captureOutput: AVCaptureOutput, didDrop didDropSampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    // print("frame dropped")
  }
}