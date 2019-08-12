//
//  ViewController.swift
//  ML-TestBed
//
//  Created by Song on 2019-08-12.
//  Copyright © 2019 Song. All rights reserved.
//

import UIKit
import Vision
import CoreML

//Note: run app on iOS device and iOS version is 11.1+
//
class ViewController: UIViewController {

    @IBOutlet weak var productImageView: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
}

//MARK: - ML methods
extension ViewController {
    
    func createRequest(productImage: CIImage) -> Void {
        
        //load our product model that was trained by Create ML
        guard let productModel = try? VNCoreMLModel(for: ProductClassifier_bay().model) else {
            fatalError("The model could not be loaded now, check it in Create ML")
        }
        
        //request for prediction by Core ML and Vision
        let request = VNCoreMLRequest(model: productModel, completionHandler: { [weak self] request, error in
            self?.processPredictions(for: request, error: error)
        })
        request.imageCropAndScaleOption = .centerCrop
        
        //run request in background queue, so that the main queue isn’t blocked while requests executing
        let handler = VNImageRequestHandler(ciImage: productImage)
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([request])
            } catch {
                print(error)
            }
        }

    }
    
    func processPredictions(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard let results = request.results else {
                self?.resultLabel.text = "Unable to classify product image.\n\(error!.localizedDescription)"
                return
            }
            
            let predictionss = results as! [VNClassificationObservation]
            let firstResult = predictionss.first
            
            self?.resultLabel.text = "This product belongs to \(String(describing: firstResult!.identifier))"
        }
    }
    
}

//MARK: - Select photos
extension ViewController: UINavigationControllerDelegate {
    
    @IBAction func clickedBarButtonCamera() {
        
        guard UIImagePickerController.isSourceTypeAvailable(.camera)  else {
            let alert = UIAlertController(title: "No Camera", message: "This device does not support camera.", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func clickedBarButtonSelectPhoto() {
        
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary)  else {
            let alert = UIAlertController(title: "No Photos", message: "This device does not support photos.", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension  ViewController:  UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // The info dictionary may contain multiple representations of the image. You want to use the original.
        guard let selectedImage = info[.originalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        
        // Set productImageView to display the selected image.
        productImageView.image = selectedImage
        
        // Convert UIImage to CIImage
        guard let ciImage = CIImage(image: selectedImage) else {
            fatalError("couldn't convert UIImage to CIImage")
        }
        
        //create request for this product ciimage
        self.createRequest(productImage: ciImage)
        
        // Dismiss the picker.
        dismiss(animated: true, completion: nil)
        
    }
    
}
