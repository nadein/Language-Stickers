//
//  ViewController.swift
//  Language Stickers
//
//  Created by Alex Nadein on 12.03.2021.
//

import UIKit

class ViewController: UIViewController {
  
  var captureSessionManager: CaptureSessionManager!
  var visionManager: VisionManager!

  override func viewDidLoad() {
    super.viewDidLoad()
    captureSessionManager = CaptureSessionManager.shared
    visionManager = VisionManager.shared
    captureSessionManager.setupCaptureSessionWith(previewView: view, sampleBufferDelegate: visionManager)
    visionManager.setupVisionSessionWith(rootLayer: view.layer)
    captureSessionManager.startCaptureSession()
  }
}

