//
//  ViewController.swift
//  PhotoAlbum
//
//  Created by Adnan Hussain on 05/03/2019.
//  Copyright © 2019 Adnan Hussain. All rights reserved.
//

import UIKit
import CoreML
import Vision
import AVKit

class ViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //links share button
    @IBAction func shareButton(_ sender: Any) {
        //sets the default sharing message
        let activityItem: [AnyObject] = [self.displayImage.image ?? displayImage, objectDetectionLabel.text  as AnyObject, faceDetection.text  as AnyObject]
        let avc = UIActivityViewController(activityItems: activityItem as [AnyObject], applicationActivities: nil)
        self.present(avc, animated: true, completion: nil)
    }
    
    //links export button
    //this function is similar to share button but exports the results as a CSV file
    @IBAction func exportResult(_ sender: Any)
    {
        //creating file name
        let fileName = "results.csv"
        //setting path for CSV file to be saved
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        //CSV will include face detection, object detection and display image
        do {
            var csvText = "Face Detection,Detection ,Image\n\(String(describing: faceDetection)),\(objectDetectionLabel),\(displayImage)"
            
            //adding the text to the CSV file
            try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
            
            //lets user share results to different applications
            let vc = UIActivityViewController(activityItems: [path], applicationActivities: [])
            
            present(vc, animated: true, completion: nil)
        }
        catch {
            //error message if it fails to create CSV
            print("Creating the CSV file failed")
            print("\(error)")
        }
    }
    
    @IBOutlet weak var displayImage: UIImageView!
    
    //links detection button
    @IBAction func detectionButton(_ sender: Any) {
        guard let image = displayImage.image, let ciImage = CIImage(image: image)
        else {
                return
        }
        //calls the function
        detectObject(image: ciImage)
    }
    
    //links object detection label
    @IBOutlet weak var objectDetectionLabel: UILabel!
    //links face detection label
    @IBOutlet weak var faceDetection: UILabel!
    
    //audio button
    @IBAction func audioButton(_ sender: Any) {
        //reads out object detection reults
        self.readMe(myText: objectDetectionLabel.text!, myLang: "en-US")
        //reads out face detection reults
        self.readMe(myText: faceDetection.text!, myLang: "en-US")
    }
    
    //screen reader settings
    func readMe(myText: String, myLang: String){
        let utterance = AVSpeechUtterance(string: myText)
        //voice language
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        //voice speed
        utterance.rate = 0.5
        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
    }
    
    //gallery button
    @IBAction func galleryButton(_ sender: Any) {
        //calls the function
        getphoto()
    }
    
    //allows user to get photo from the library
    func getphoto(){
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present (imagePicker, animated: true, completion: nil)
    }
    
    //camera button
    @IBAction func cameraButton(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            //user can click "take photo" ui alert if camera is available
            let cameraAction = UIAlertAction(title: "Take photo", style: .default, handler: {(_) in
                imagePicker.sourceType = .camera
                self.present(imagePicker,animated: true, completion: nil)
            })
            alertController.addAction(cameraAction)
        }
        else{
            //if camera isn't available, this ui alert will show
            let cancelAction = UIAlertAction(title: "Camera not available", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
        }
        
        present(alertController, animated: true, completion: nil)
    }

    
    //the library used to detect objects
    let model = Inceptionv3()
    
    func detectObject(image: CIImage){
        //links object detection label, when uses presses detect, it will say "detecting object"
        objectDetectionLabel.text = "Detecting Object..."
        //uses the model to detect object
        guard let model = try? VNCoreMLModel(for: model.model)
        //error message if it can't detect object
        else {fatalError("Cannot detect")}
        let request = VNCoreMLRequest(model: model) { (request,error) in
            guard let results = request.results as? [VNClassificationObservation],
                let topResult = results.first else{fatalError()}
            
            DispatchQueue.main.async {
                //outputs the result along with the percentage of confidence (accuracy)
                self.objectDetectionLabel.text = "\(Int(topResult.confidence * 100))% \(topResult.identifier)"
            }
        }
        let handler = VNImageRequestHandler(ciImage: image)
        DispatchQueue.global(qos: .userInteractive).async{
            do{
                try handler.perform([request])
            }catch{
                //debug message
                print(error)
            }
        }
    }
    
    //image picker
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage =
            info[.originalImage] as? UIImage
            else {return}
        displayImage.image = selectedImage
        
        dismiss(animated: true, completion: nil)
        
        identifyFacesWithLandmarks(image: selectedImage)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func identifyFacesWithLandmarks(image: UIImage) {
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [ : ])
        
        faceDetection.text = "Looking for a face"
        
        let request = VNDetectFaceLandmarksRequest(completionHandler: handleFaceLandmarksRecognition)
        try! handler.perform([request])
    }
    
    func handleFaceLandmarksRecognition(request: VNRequest, error: Error?) {
        guard let foundFaces = request.results as? [VNFaceObservation] else {
            //error message
            fatalError ("Problem loading picture to examine faces")
        }
        //links face detection label. This show how many faces were found
        faceDetection.text = "Found \(foundFaces.count) faces"
        
        //library used to recognise faces and landmarks
        for faceRectangle in foundFaces {
            
            guard let landmarks = faceRectangle.landmarks else {
                continue
            }
            
            var landmarkRegions: [VNFaceLandmarkRegion2D] = []
            
            if let faceContour = landmarks.faceContour {
                landmarkRegions.append(faceContour)
            }
            if let leftEye = landmarks.leftEye {
                landmarkRegions.append(leftEye)
            }
            if let rightEye = landmarks.rightEye {
                landmarkRegions.append(rightEye)
            }
            if let nose = landmarks.nose {
                landmarkRegions.append(nose)
            }
            //draws on the image
            drawImage(source: displayImage.image!, boundary: faceRectangle.boundingBox, faceLandmarkRegions: landmarkRegions)
            
        }
    }
    
    //uses the library to recognise faces and landmarks
    func drawImage(source: UIImage, boundary: CGRect, faceLandmarkRegions: [VNFaceLandmarkRegion2D])  {
        UIGraphicsBeginImageContextWithOptions(source.size, false, 1)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: 0, y: source.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setLineJoin(.round)
        context.setLineCap(.round)
        context.setShouldAntialias(true)
        context.setAllowsAntialiasing(true)
        
        let rect = CGRect(x: 0, y:0, width: source.size.width, height: source.size.height)
        context.draw(source.cgImage!, in: rect)
        
        //draw rectangles around faces
        var fillColor = UIColor.green
        fillColor.setStroke()
        
        let rectangleWidth = source.size.width * boundary.size.width
        let rectangleHeight = source.size.height * boundary.size.height
        
        context.addRect(CGRect(x: boundary.origin.x * source.size.width, y:boundary.origin.y * source.size.height, width: rectangleWidth, height: rectangleHeight))
        context.drawPath(using: CGPathDrawingMode.stroke)
        
        //draw facial features
        fillColor = UIColor.red
        fillColor.setStroke()
        context.setLineWidth(2.0)
        for faceLandmarkRegion in faceLandmarkRegions {
            var points: [CGPoint] = []
            for i in 0..<faceLandmarkRegion.pointCount {
                let point = faceLandmarkRegion.normalizedPoints[i]
                let p = CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
                points.append(p)
            }
            let facialPoints = points.map { CGPoint(x: boundary.origin.x * source.size.width + $0.x * rectangleWidth, y: boundary.origin.y * source.size.height + $0.y * rectangleHeight) }
            context.addLines(between: facialPoints)
            context.drawPath(using: CGPathDrawingMode.stroke)
        }
        
        let modifiedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        displayImage.image = modifiedImage
    }
    
}
