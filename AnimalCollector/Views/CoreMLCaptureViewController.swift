//
//  ViewController.swift
//  CoreMLDemo
//
//  Created by Sai Kambampati on 14/6/2017.
//  Copyright © 2017 AppCoda. All rights reserved.
//

import UIKit
import CoreML
import FirebaseStorage
import FirebaseAuth
import FirebaseDatabase

class CoreMLCaptureViewController: UIViewController, UINavigationControllerDelegate {
    
    // MARK: Constants
    let showUserAccount = "showUserAccount"
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var classifier: UILabel!
    @IBOutlet weak var saveImageButton: UIButton!
    @IBOutlet weak var errorMessage: UILabel!
    
    var model: Inceptionv3!
    
    var animalDataToSave: AnimalData?
    var curUserUID: String?
    var sv: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        checkIfUserIsLoggedIn()
        initView()
        resetViewProperties()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        model = Inceptionv3()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initView() {
        animalDataToSave = AnimalData(key: "", imageName: "", imageURL: "", score: 0)
    }
    
    @IBAction func camera(_ sender: Any) {
        
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            return
        }
        
        let cameraPicker = UIImagePickerController()
        cameraPicker.delegate = self
        cameraPicker.sourceType = .camera
        cameraPicker.allowsEditing = false
        
        present(cameraPicker, animated: true)
    }
    
    @IBAction func openLibrary(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    @IBAction func saveImageButtonDidTouch(_ sender: Any) {
        sv = UIViewController.displaySpinner(onView: self.view)
        
        // save image to firebase
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imagesRef = storageRef.child("images")
        let userRef = imagesRef.child(curUserUID!)
        let imageToSaveRef = userRef.child((animalDataToSave?.imageName)!)
        
        let imageToSave = imageView.image
        let uploadImageMetadata = StorageMetadata()
        uploadImageMetadata.contentType = "image/jpeg"
        
        if let uploadData = UIImagePNGRepresentation(imageToSave!) {
            imageToSaveRef.putData(uploadData, metadata: uploadImageMetadata) { (metadata, error) in
                guard let metadata = metadata else {
                    print(error!)
                    return
                }
                // Metadata contains file metadata such as size, content-type, and download URL.
                if let imageURL = metadata.downloadURL()?.absoluteString {
                    self.animalDataToSave?.imageURL = imageURL
                    self.saveAnimalDataToUserAccount()
                }
            }
        }
    }
    
    private func saveAnimalDataToUserAccount() {
        let ref: DatabaseReference = Database.database().reference()
        let usersRef = ref.child("users")
        let curUserRef = usersRef.child(curUserUID!)
        let scoreRef = curUserRef.child("score")
        
        
        scoreRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if let score = snapshot.value as? Int {
                let newScore = score + (self.animalDataToSave?.score)!
                scoreRef.setValue(newScore)
                
                UIViewController.removeSpinner(spinner: self.sv!)
                
                DispatchQueue.main.async {
                    self.prepareForUserAccountViewSegue()
                }
            }
        }) { (error) in
            print(error.localizedDescription)
        }
        
        let collectionsRef = curUserRef.child("collections")
        let animalRef = collectionsRef.child((animalDataToSave?.key)!)
        
        // TODO testing
        let values = [
            "key": self.animalDataToSave?.key as Any,
            "imageName": self.animalDataToSave?.imageName as Any,
            "imageURL": self.animalDataToSave?.imageURL as Any,
            "score": self.animalDataToSave?.score as Any,
            ] as [String : Any]
        
        animalRef.setValue(values)
    }
    
    func findAnimals(predictionLabel: String) {
        saveImageButton.isHidden = true
        
        let animalsScore = AnimalScore()
        let predictionsArr = predictionLabel.components(separatedBy: ", ")
        let filteredPredictions = predictionsArr.filter {
            let key = $0.trimmingCharacters(in: .whitespaces)
            return animalsScore.animals[key] != nil
        }
        
        if (filteredPredictions.isEmpty) {
            errorMessage.isHidden = false
            errorMessage.text = "This is not a valid animal. Please select or capture another image of an animal"
        } else {
            errorMessage.isHidden = true
            let key = filteredPredictions[0]
            
            animalDataToSave?.key = key
            animalDataToSave?.imageName = "\(key).jpg"
            animalDataToSave?.score = animalsScore.animals[key]!.score
            
            classifier.text = "Score is \(animalsScore.animals[key]!.score)"
            
            // TODO check if user already has this animal in his collection
            // if they do, then ask if they want to replace this image with their current one
            // maybe, let them preview their current image?
            
            saveImageButton.isHidden = false
        }
    }
    
    func prepareForUserAccountViewSegue() {
        performSegue(withIdentifier: showUserAccount, sender: self)
        resetViewProperties()
    }
    
    func checkIfUserIsLoggedIn() {
        if let currentUser = Auth.auth().currentUser {
            self.curUserUID = currentUser.uid
        } else {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        }
    }
    
    @objc func handleLogout() {
        do {
            try Auth.auth().signOut()
        } catch let logoutError {
            print(logoutError)
        }
        
        let loginViewController = LoginViewController()
        present(loginViewController, animated: true, completion: nil)
    }
 
    func resetViewProperties() {
        imageView.image = nil
        classifier.text = "Select or Capture an image of an animal"
        saveImageButton.isHidden = true
        errorMessage.text = ""
        errorMessage.isHidden = true
    }
}

extension CoreMLCaptureViewController: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true)
        classifier.text = "Analyzing Image..."
        guard let image = info["UIImagePickerControllerOriginalImage"] as? UIImage else {
            return
        }
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 299, height: 299), true, 2.0)
        image.draw(in: CGRect(x: 0, y: 0, width: 299, height: 299))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(newImage.size.width), Int(newImage.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(newImage.size.width), height: Int(newImage.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) //3
        
        context?.translateBy(x: 0, y: newImage.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        newImage.draw(in: CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        imageView.image = newImage
        
        guard let prediction = try? model.prediction(image: pixelBuffer!) else {
            return
        }
        
        classifier.text = "I think this is a \(prediction.classLabel)."
        
        findAnimals(predictionLabel: prediction.classLabel)
    }
}

extension UIViewController {
    class func displaySpinner(onView : UIView) -> UIView {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(activityIndicatorStyle: .whiteLarge)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        
        return spinnerView
    }
    
    class func removeSpinner(spinner :UIView) {
        DispatchQueue.main.async {
            spinner.removeFromSuperview()
        }
    }
}
