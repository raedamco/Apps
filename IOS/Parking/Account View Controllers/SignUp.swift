//
//  SignUp.swift
//  Parking
//
//  Created by Omar on 10/19/19.
//  Copyright © 2019 Theory Parking. All rights reserved.
//


import UIKit
import Firebase
import LocalAuthentication
import Lottie
import BLTNBoard
import FirebaseFunctions
import Stripe
import Alamofire

class SignUp: UIViewController, UITextFieldDelegate{
    
    let emailTextField = createTextField(FontName: font, FontSize: 18, KeyboardType: .emailAddress, ReturnType: .next, BackgroundColor: standardBackgroundColor, SecuredEntry: false, Placeholder: "Email", Target: self)
    let nameTextField = createTextField(FontName: font, FontSize: 18, KeyboardType: .default, ReturnType: .next, BackgroundColor: standardBackgroundColor, SecuredEntry: false, Placeholder: "Name", Target: self)
    let passwordTextField = createTextField(FontName: font, FontSize: 18, KeyboardType: .default, ReturnType: .next, BackgroundColor: standardBackgroundColor, SecuredEntry: true, Placeholder: "Password", Target: self)
    let passwordVerifyTextField = createTextField(FontName: font, FontSize: 18, KeyboardType: .default, ReturnType: .next, BackgroundColor: standardBackgroundColor, SecuredEntry: true, Placeholder: "Verify Password", Target: self)
    let createAccountButton = createButton(Title: "Next", FontName: font, FontSize: 25, FontColor: standardBackgroundColor, BorderWidth: 1.5, CornerRaduis: 6, BackgroundColor: standardContrastColor, BorderColor: UIColor.clear.cgColor, Target: self, Action: #selector(createAccount))
    let loginButton = createButton(Title: "Have an account? Log In", FontName: font, FontSize: 15, FontColor: standardTintColor, BorderWidth: 0, CornerRaduis: 0, BackgroundColor: standardClearColor, BorderColor: UIColor.clear.cgColor, Target: self, Action: #selector(login))
    let privacyPolicyButton = createButton(Title: "Privacy Policy", FontName: font, FontSize: 14, FontColor: standardTintColor, BorderWidth: 0, CornerRaduis: 0, BackgroundColor: standardClearColor, BorderColor: UIColor.clear.cgColor, Target: self, Action: #selector(viewPrivacyPolicy))
   
    // BLTNBoard START
        let backgroundStyles = BackgroundStyles()
        var currentBackground = (name: "Dimmed", style: BLTNBackgroundViewStyle.dimmed)

        var errorMessageBLTN = String()
        lazy var bulletinManagerError: BLTNItemManager = {
            let page = BulletinDataSource.makeErrorPage(message: errorMessageBLTN)
            return BLTNItemManager(rootItem: page)
        }()
    
        var userEmail = String()
        lazy var bulletinManagerSuccess: BLTNItemManager = {
            let page = BulletinDataSource.reservedSpotPage(email: userEmail)
            return BLTNItemManager(rootItem: page)
        }()
    // BLTNBoard END
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createScreenLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationbarAttributes(Hidden: false, Translucent: false)
        setupNavigationBar(LargeText: true, Title: "Sign Up", SystemImageR: false, ImageR: false, ImageTitleR: "", TargetR: nil, ActionR: nil, SystemImageL: true, ImageL: true, ImageTitleL: "xmark", TargetL: self, ActionL: #selector(self.closeView))
        NotificationCenter.default.addObserver(self, selector: #selector(closeViewBulletin(notification:)), name: NSNotification.Name(rawValue: "closeView"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setNeedsStatusBarAppearanceUpdate()
        checkConnection()
    }
    
    func createScreenLayout(){
        view.backgroundColor = standardBackgroundColor
        nameTextField.autocapitalizationType = .words
        nameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        passwordVerifyTextField.delegate = self

        view.addSubview(nameTextField)
        view.addSubview(emailTextField)
        view.addSubview(passwordTextField)
        view.addSubview(passwordVerifyTextField)
        view.addSubview(privacyPolicyButton)
        view.addSubview(loginButton)
        view.addSubview(createAccountButton)
        
        
        nameTextField.topAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -180).isActive = true
        nameTextField.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        nameTextField.widthAnchor.constraint(equalToConstant: self.view.frame.width - 60).isActive = true
        
        emailTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 30).isActive = true
        emailTextField.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        emailTextField.widthAnchor.constraint(equalToConstant: self.view.frame.width - 60).isActive = true
        
        passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 30).isActive = true
        passwordTextField.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        passwordTextField.widthAnchor.constraint(equalToConstant: self.view.frame.width - 60).isActive = true
        
        passwordVerifyTextField.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 30).isActive = true
        passwordVerifyTextField.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        passwordVerifyTextField.widthAnchor.constraint(equalToConstant: self.view.frame.width - 60).isActive = true
        
        privacyPolicyButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30).isActive = true
        privacyPolicyButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        privacyPolicyButton.widthAnchor.constraint(equalToConstant: self.view.frame.width - 60).isActive = true
        privacyPolicyButton.heightAnchor.constraint(equalToConstant: (self.view.frame.width - 60)/5.5).isActive = true
        
        loginButton.bottomAnchor.constraint(equalTo: privacyPolicyButton.bottomAnchor, constant: -30).isActive = true
        loginButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        loginButton.widthAnchor.constraint(equalToConstant: self.view.frame.width - 60).isActive = true
        loginButton.heightAnchor.constraint(equalToConstant: (self.view.frame.width - 60)/5.5).isActive = true
        
        createAccountButton.topAnchor.constraint(equalTo: loginButton.topAnchor, constant: -60).isActive = true
        createAccountButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        createAccountButton.widthAnchor.constraint(equalToConstant: self.view.frame.width - 60).isActive = true
        createAccountButton.heightAnchor.constraint(equalToConstant: (self.view.frame.width - 60)/5.5).isActive = true
        
    }

    @objc func createAccount(){
        textFieldEntries()
        
        if emailTextField.text?.isEmpty == false && passwordTextField.text?.isEmpty == false && passwordTextField.text == passwordVerifyTextField.text && passwordVerifyTextField.text?.isEmpty == false && nameTextField.text?.isEmpty == false {
            Auth.auth().createUser(withEmail: self.emailTextField.text!, password: self.passwordTextField.text!) { (user, error) in
                if user != nil {
//                    self.signIn()
                    self.createDatabaseAccount()
                }else{
                    if let errorCode = AuthErrorCode(rawValue: (error?._code)!) {
                        self.errorMessageBLTN = errorCode.errorMessage
                        self.bulletinManagerError.allowsSwipeInteraction = false
                        self.bulletinManagerError.showBulletin(above: self)
                    }
                }
            }
        }
    }
    
    @objc func closeViewBulletin(notification: NSNotification) {
        self.navigationController?.pushViewController(StartViewController(), animated: false)
        try! Auth.auth().signOut()
    }
    
//    @objc func signIn(){
//        Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!, completion: { (user,error) in
//            if user != nil {
//                getUserData(UID: Auth.auth().currentUser!.uid) { (true) in
//                    self.userEmail = self.emailTextField.text!
//                    self.bulletinManagerSuccess.allowsSwipeInteraction = false
//                    self.bulletinManagerSuccess.showBulletin(above: self)
//                }
//            }else{
//                if let errorCode = AuthErrorCode(rawValue: (error?._code)!) {
//                    self.errorMessageBLTN = errorCode.errorMessage
//                    self.bulletinManagerError.allowsSwipeInteraction = false
//                    self.bulletinManagerError.showBulletin(above: self)
//                }
//            }
//        })
//    }
//
    @objc func createDatabaseAccount(){
        let UUID = Auth.auth().currentUser?.uid
        //MARK: THIS NEEDS TO BE REMOVED IN FUTURE VERSIONS
        let structData: [String: Any] = ["Beta Access": false, "Name": self.nameTextField.text!, "Permits":[:],"Vehicles":[]]

        database.collection("Users").document("Commuters").collection("Users").document(UUID!).setData(structData, merge: true) { error in
            if let error = error?.localizedDescription {
                print(error)
            }else{
                self.userEmail = self.emailTextField.text!
                self.bulletinManagerSuccess.allowsSwipeInteraction = false
                self.bulletinManagerSuccess.showBulletin(above: self)
                
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    @objc func login(){
        self.navigationController?.pushViewController(SignIn(), animated: false)
    }
    
    @objc func viewPrivacyPolicy(){
        webLink = "https://raedam.co/privacy"
        webViewLabel = "Privacy Policy"
        let webView = UINavigationController(rootViewController: webViewScreen())
        self.navigationController?.present(webView, animated: false, completion: nil)
    }
    
    @objc func closeView() {
        self.navigationController?.pushViewController(StartViewController(), animated: false)
    }
    
}


extension SignUp {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldEntries(){
        if emailTextField.text?.isEmpty == true || passwordTextField.text?.isEmpty == true || passwordVerifyTextField.text?.isEmpty == true || nameTextField.text?.isEmpty == true {
            self.errorMessageBLTN = "All text fields must be filled out"
            self.bulletinManagerError.allowsSwipeInteraction = false
            self.bulletinManagerError.showBulletin(above: self)
        }
        
        if passwordTextField.text != passwordVerifyTextField.text {
            self.errorMessageBLTN = "Passwords do not match"
            self.bulletinManagerError.allowsSwipeInteraction = false
            self.bulletinManagerError.showBulletin(above: self)
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if emailTextField.isEditing == true {
            emailTextField.setBottomBorderSelected()
        }
        if passwordTextField.isEditing == true {
            passwordTextField.setBottomBorderSelected()
        }
        if passwordVerifyTextField.isEditing == true {
            passwordVerifyTextField.setBottomBorderSelected()
        }
        if nameTextField.isEditing == true {
            nameTextField.setBottomBorderSelected()
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if emailTextField.isEditing == false {
            emailTextField.setBottomBorderNotSelected()
        }
        if passwordTextField.isEditing == false {
            passwordTextField.setBottomBorderNotSelected()
        }
        if passwordVerifyTextField.isEditing == false {
            passwordVerifyTextField.setBottomBorderNotSelected()
        }
        if nameTextField.isEditing == false {
            nameTextField.setBottomBorderNotSelected()
        }
    }
    
    func textFieldhide(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if passwordVerifyTextField.isEditing == true && passwordVerifyTextField.text?.isEmpty == false {
            createAccount()
            textField.resignFirstResponder()
        }else{
            if emailTextField.isEditing == true && emailTextField.text?.isEmpty == false {
                passwordTextField.becomeFirstResponder()
            }else{
                if nameTextField.isEditing == true && nameTextField.text?.isEmpty == false {
                    emailTextField.becomeFirstResponder()
                }else{
                    if passwordTextField.isEditing == true && passwordTextField.text?.isEmpty == false {
                        passwordVerifyTextField.becomeFirstResponder()
                    }
                }
            }
        }
        return false
    }
}
