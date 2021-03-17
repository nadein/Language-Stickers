//
//  CaptureSessionManager.swift
//  Language Stickers
//
//  Created by Alex Nadein on 15.03.2021.
//

import UIKit
import AVFoundation

class CaptureSessionManager: NSObject {
  
  // MARK: - Static
  static let shared = CaptureSessionManager()
  
  // MARK: - Properties
  public var bufferSize: CGSize = .zero
  public weak var sampleBufferDelegate: AVCaptureVideoDataOutputSampleBufferDelegate?
  
  private weak var previewView: UIView?
  private var rootLayer: CALayer! = nil
  private var previewLayer: AVCaptureVideoPreviewLayer! = nil
  
  private let session = AVCaptureSession()
  private let videoDataOutput = AVCaptureVideoDataOutput()
  private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
  
  // MARK: - Init
  
  private override init() {}
  
  // MARK: - Setup
  
  func setupCaptureSessionWith(previewView: UIView, sampleBufferDelegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
    self.previewView = previewView
    self.sampleBufferDelegate = sampleBufferDelegate
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
      videoDataOutput.setSampleBufferDelegate(self.sampleBufferDelegate, queue: videoDataOutputQueue)
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
  
  // MARK: - Session control
  
  func startCaptureSession() {
    session.startRunning()
  }
  
  func teardownAVCapture() {
    previewLayer.removeFromSuperlayer()
    previewLayer = nil
  }
}
