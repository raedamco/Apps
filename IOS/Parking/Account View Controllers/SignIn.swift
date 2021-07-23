//
//  SignIn.swift
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

var ReturnMessage = String()
var LoginSuccess = Bool()

class SignIn: UIViewController, UITextFieldDelegate {
    
    let emailTextField = createTextField(FontName: font, FontSize: 18, KeyboardType: .emailAddress, ReturnType: .next, BackgroundColor: standardBackgroundColor, SecuredEntry: false, Placeholder: "Email", Target: self)
    let passwordTextField = createTextField(FontName: font, FontSize: 18, KeyboardType: .default, ReturnType: .continue, BackgroundColor: standardBackgroundColor, SecuredEntry: true, Placeholder: "Password", Target: self)
    
    let loginButton = createButton(Title: "Login", FontName: font, FontSize: 25, FontColor: standardBackgroundColor, BorderWidth: 1.5, CornerRaduis: 12, BackgroundColor: standardContrastColor, BorderColor: UIColor.white.cgColor, Target: self, Action: #selector(login))
    let signupButton = createButton(Title: "Don't have an account? Sign up here.", FontName: font, FontSize: 15, FontColor: standardTintColor, BorderWidth: 0, CornerRaduis: 12, BackgroundColor: .clear, BorderColor: UIColor.white.cgColor, Target: self, Action: #selector(signup))
    let forgotButton = createButton(Title: "forgot?", FontName: font, FontSize: 16, FontColor: standardTintColor, BorderWidth: 0, CornerRaduis: 0, BackgroundColor: .clear, BorderColor: UIColor.white.cgColor, Target: self, Action: #selector(passwordReset))

    let blacksubView = createViewOverlay()
    let animationView = createAnimationView(Animation: "success", Speed: 0.25)
    let label = createLabel(LabelText: "", TextColor: standardContrastColor, FontName: font, FontSize: 23, TextAlignment: .center, TextBreak: .byWordWrapping, NumberOfLines: 0)

    // BLTNBoard START
    let backgroundStyles = BackgroundStyles()
    var currentBackground = (name: "Dimmed", style: BLTNBackgroundViewStyle.dimmed)
    
    lazy var bulletinManagerForgotPassword: BLTNItemManager = {
        let page = BulletinDataSource.makeForgotPasswordPage()
        return BLTNItemManager(rootItem: page)
    }()
    
    lazy var bulletinManagerVerifyAccount: BLTNItemManager = {
        let page = BulletinDataSource.makeVerifyPage()
        return BLTNItemManager(rootItem: page)
    }()
    
    var errorMessageBLTN = String()
    lazy var bulletinManagerError: BLTNItemManager = {
        let page = BulletinDataSource.makeErrorPage(message: errorMessageBLTN)
        return BLTNItemManager(rootItem: page)
    }()
    // BLTNBoard END
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createScreenLayout()
    }
    
    @objc func temp(){
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationbarAttributes(Hidden: false, Translucent: false)
        setupNavigationBar(LargeText: true, Title: "Login", SystemImageR: false, ImageR: false, ImageTitleR: "", TargetR: nil, ActionR: nil, SystemImageL: true, ImageL: true, ImageTitleL: "xmark", TargetL: self, ActionL: #selector(self.closeView))
    }

    override func viewDidAppear(_ animated: Bool) {
        setNeedsStatusBarAppearanceUpdate()
        checkConnection()
    }
    
    func createScreenLayout(){
        view.backgroundColor = standardBackgroundColor
        
        emailTextField.delegate = self
        passwordTextField.delegate = self

        view.addSubview(emailTextField)
        view.addSubview(passwordTextField)
        view.addSubview(forgotButton)
        view.addSubview(signupButton)
        view.addSubview(loginButton)
        
        emailTextField.topAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -120).isActive = true
        emailTextField.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        emailTextField.widthAnchor.constraint(equalToConstant: self.view.frame.width - 60).isActive = true

        passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 40).isActive = true
        passwordTextField.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        passwordTextField.widthAnchor.constraint(equalToConstant: self.view.frame.width - 60).isActive = true
        
        forgotButton.titleLabel?.textAlignment = .right
        forgotButton.rightAnchor.constraint(equalTo: self.passwordTextField.rightAnchor).isActive = true
        forgotButton.centerYAnchor.constraint(equalTo: self.passwordTextField.centerYAnchor, constant: -5).isActive = true
        
        signupButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30).isActive = true
        signupButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        signupButton.widthAnchor.constraint(equalToConstant: self.view.frame.width - 60).isActive = true
        signupButton.heightAnchor.constraint(equalToConstant: (self.view.frame.width - 60)/4.5).isActive = true
        
        loginButton.topAnchor.constraint(equalTo: signupButton.topAnchor, constant: -60).isActive = true
        loginButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        loginButton.widthAnchor.constraint(equalToConstant: self.view.frame.width - 60).isActive = true
        loginButton.heightAnchor.constraint(equalToConstant: (self.view.frame.width - 60)/5.5).isActive = true
    }

    @objc func login(){
        emptyTextField()
        if !emailTextField.text!.isEmpty && !passwordTextField.text!.isEmpty {
            Database.checkAccess(Email: emailTextField.text!){ (true) in
                if LoginSuccess{
                    Auth.auth().signIn(withEmail: self.emailTextField.text!, password: self.passwordTextField.text!, completion: { (user,error) in
                        if user != nil{
                            getUserData(UID: Auth.auth().currentUser!.uid) { (true) in
                                if UserData[indexPath.row].BetaAccess {
                                    self.navigationController?.setNavigationBarHidden(true, animated: true)
                                    self.tabBarController?.tabBar.isHidden = true
                                    self.navigationController?.popViewController(animated: true)
                                    self.navigationController?.removeFromParent()
                                    self.navigationController?.pushViewController(TabBarViewController(), animated: false)
                                }
                            }
                        }else{
                            if let errorCode = AuthErrorCode(rawValue: (error?._code)!) {
                                self.errorMessageBLTN = errorCode.errorMessage
                                self.bulletinManagerError.allowsSwipeInteraction = false
                                self.bulletinManagerError.showBulletin(above: self)
                            }
                        }
                    })
                }else{
                    self.errorMessageBLTN = "Your account exists. Please wait for an email from us with your access into the app."
                    self.bulletinManagerError.allowsSwipeInteraction = false
                    self.bulletinManagerError.showBulletin(above: self)
                }
            }
        }
    }
    
    @objc func passwordReset() {
        bulletinManagerForgotPassword.allowsSwipeInteraction = false
        self.bulletinManagerForgotPassword.showBulletin(above: self)
    }
    
    @objc func signup(){
        self.navigationController?.pushViewController(SignUp(), animated: false)
    }
    
    @objc func closeView() {
        self.navigationController?.pushViewController(StartViewController(), animated: false)
    }

}

extension SignIn {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
           if emailTextField.isEditing == true {
               emailTextField.setBottomBorderSelected()
           }
           if passwordTextField.isEditing == true {
               passwordTextField.setBottomBorderSelected()
           }
       }
       
       func textFieldDidEndEditing(_ textField: UITextField) {
           if emailTextField.isEditing == false {
               emailTextField.setBottomBorderNotSelected()
           }
           if passwordTextField.isEditing == false {
               passwordTextField.setBottomBorderNotSelected()
           }
       }
       
       func textFieldhide(_ textField: UITextField) -> Bool {
           textField.resignFirstResponder()
           return true
       }
       
       func textFieldShouldReturn(_ textField: UITextField) -> Bool {
           if passwordTextField.isEditing == true && passwordTextField.text?.isEmpty == false {
               login()
               textField.resignFirstResponder()
           }else{
               if emailTextField.isEditing == true && emailTextField.text?.isEmpty == false {
                   passwordTextField.becomeFirstResponder()
               }
           }
           return false
       }
       
        func emptyTextField(){
            if emailTextField.text?.isEmpty == true || passwordTextField.text?.isEmpty == true {
                self.errorMessageBLTN = "All text fields must be filled out"
                self.bulletinManagerError.allowsSwipeInteraction = false
                self.bulletinManagerError.showBulletin(above: self)
            }
        }
    
}
