//
//  LoginViewController.swift
//  AnimalCollector
//
//  Created by Quang Nguyen on 1/28/18.
//  Copyright © 2018 AppCoda. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {
    
    // MARK: Constants
    private let showUserAccount = "showUserAccount"
    
    // MARK: Outlets
    @IBOutlet weak var userEmail: UITextField!
    @IBOutlet weak var userPassword: UITextField!
    @IBOutlet weak var errorMessage: UILabel!
    // TODO add username UITextfield ??
    
    // MARK: Override Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setupView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // dismiss keyboard when view is touched
        userEmail.resignFirstResponder()
        userPassword.resignFirstResponder()
    }
    
    // MARK: Actions
    @IBAction func loginDidTouch(_ sender: UIButton) {
        guard let email = userEmail.text, let password = userPassword.text else {
            print("not a valid form of email or password")
            return
        }
        
        // auth user
        handleAuth(email: email, password: password)
    }
    
    @IBAction func signUpDidTouch(_ sender: Any) {
        guard let email = userEmail.text, let password = userPassword.text else {
            print("not a valid form of email or password")
            return
        }
        
        // register user
        handleRegister(email: email, password: password)
        
    }
    
    // MARK: Functions
    func handleRegister(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { (user, err) in
            
            if err != nil {
                print((err! as NSError).localizedDescription)
                
                // handle error
                if let errCode = AuthErrorCode(rawValue: err!._code) {
                    switch errCode {
                    case .emailAlreadyInUse:
                        self.errorMessage.text = "Email already exist"
                    case .invalidEmail:
                        self.errorMessage.text = "Email form is invalid"
                    case .missingEmail:
                        self.errorMessage.text = "Email is missing"
                    case .weakPassword:
                        self.errorMessage.text = "Password must be 6 chars or more"
                    default:
                        print("Create User Error: \(err!)")
                    }
                }
                self.errorMessage.isHidden = false
                return
            }
            
            // configure Firebase db
            guard let uid = user?.uid else {
                return
            }
            
            let rootRef = Database.database().reference()
            let userRef = rootRef.child("users").child(uid)
            let values = ["email": email, "password": password, "score": 0] as [String : Any]
            userRef.updateChildValues(values) { (error, rootRef) in
                if error !=  nil {
                    print(error as Any)
                    return
                }
                
                print("successfully created user")
            }
            
            self.prepareForUserAccountViewSegue()
        }
    }
    
    func handleAuth(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            
            if user == nil {
                print(error as Any)
                // handle error
                if let errCode = AuthErrorCode(rawValue: error!._code) {
                    switch errCode {
                    case .userNotFound:
                        self.errorMessage.text = "User doesn't exist"
                    case .invalidEmail:
                        self.errorMessage.text = "Email form is invalid"
                    case .missingEmail:
                        self.errorMessage.text = "Email is missing"
                    case .wrongPassword:
                        self.errorMessage.text = "Wrong password. Please try again"
                    default:
                        print("Log In User Error: \(error!)")
                    }
                }
                self.errorMessage.isHidden = false
                return
            }
            
            self.prepareForUserAccountViewSegue()
        }
    }
    
    func prepareForUserAccountViewSegue() {
        performSegue(withIdentifier: showUserAccount, sender: self)
        errorMessage.isHidden = true
        clearTextFields()
    }
    
    func clearTextFields() {
        userEmail.text = ""
        userPassword.text = ""
    }
    
    func setupView() {
        errorMessage.isHidden = true
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

extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat) {
        self.init(red: r/255, green: g/255, blue: b/255, alpha: 1)
    }
}
