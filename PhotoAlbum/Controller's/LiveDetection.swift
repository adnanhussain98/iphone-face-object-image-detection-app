//
//  LiveDetection.swift
//  PhotoAlbum
//
//  Created by Adnan Hussain on 27/03/2019.
//  Copyright © 2019 Adnan Hussain. All rights reserved.
//

import UIKit
import AVKit
import CoreML
import Vision

class LiveDetection: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    //links object detectionResult label
    @IBOutlet weak var detectionResult: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //live video will be captured once loaded
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        //video capture
        guard let captureDevice = AVCaptureDevice.default(for: .video) else
        {
            return
        }
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else
        {
            return
        }
        
        captureSession.addInput(input)
        
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        
        setupIdentifierConfidenceLabel()
    }
    
    //calculations for confidence. This is the accuracy of the result.
    fileprivate func setupIdentifierConfidenceLabel() {
        view.addSubview(detectionResult)
        detectionResult.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32).isActive = true
        detectionResult.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        detectionResult.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        detectionResult.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            else
        {
            return
        }
        
        //uses the inceptionv3 model
        guard let mobileNetModel = try? VNCoreMLModel (for: Inceptionv3().model)
            else
        {
            return
        }
        
        let request = VNCoreMLRequest(model: mobileNetModel)
        { (finishedReq, err) in
            
            guard let results = finishedReq.results as?
                [VNClassificationObservation]
                else {
                    return
            }
            guard let firstObservation = results.first else
            {
                return
            }
            
            print(firstObservation.identifier, firstObservation.confidence)
            
            //shows the results and percentage of confidence
            DispatchQueue.main.async {
                self.detectionResult.text = "\(firstObservation.confidence * 100)%\(firstObservation.identifier)"
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
}
