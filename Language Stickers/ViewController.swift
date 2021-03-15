//
//  ViewController.swift
//  Language Stickers
//
//  Created by Alex Nadein on 12.03.2021.
//

import UIKit

class ViewController: UIViewController {
  
  var captureSessionManager: CaptureSessionManager!

  override func viewDidLoad() {
    super.viewDidLoad()
    captureSessionManager = CaptureSessionManager(previewView: view)
    captureSessionManager.setupCaptureSession()
    captureSessionManager.startCaptureSession()
  }
}

