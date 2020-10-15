//
//  StartView.swift
//  Parking
//
//  Created by Omar on 10/19/19.
//  Copyright © 2019 Theory Parking. All rights reserved.
//


import Foundation
import Firebase
import UIKit
import BLTNBoard

class StartView: UIViewController {
    
    let loginButton = createButton(Title: "log in", FontName: font, FontSize: 25, FontColor: standardBackgroundColor, BorderWidth: 1.5, CornerRaduis: 12, BackgroundColor: standardContrastColor, BorderColor: UIColor.white.cgColor, Target: self, Action: #selector(login))
    let createAccountButton = createButton(Title: "sign up", FontName: font, FontSize: 25, FontColor: standardBackgroundColor, BorderWidth: 1.5, CornerRaduis: 12, BackgroundColor: standardContrastColor, BorderColor: UIColor.white.cgColor, Target: self, Action: #selector(signup))
    var currentBackground = (name: "Dimmed", style: BLTNBackgroundViewStyle.dimmed)
    let backgroundStyles = BackgroundStyles()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadStartView(notification:)), name: NSNotification.Name(rawValue: "reloadStartView"), object: nil)
        createScreenLayout()
    }
    
    lazy var bulletinManager: BLTNItemManager = {
        let page = BulletinDataSource.NotitificationsPage()
        return BLTNItemManager(rootItem: page)
    }()
    
    func showBulletin(){
        self.bulletinManager.showBulletin(above: self)
        bulletinManager.allowsSwipeInteraction = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setNeedsStatusBarAppearanceUpdate()
        checkConnection()
        view.setNeedsFocusUpdate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationbarAttributes(Hidden: false, Translucent: false)
        setupNavigationBar(LargeText: true, Title: "raedam", SystemImageR: false, ImageR: false, ImageTitleR: "", TargetR: nil, ActionR: nil, SystemImageL: false, ImageL: false, ImageTitleL: "", TargetL: nil, ActionL: nil)
    }
    
    func createScreenLayout(){
        view.backgroundColor = standardBackgroundColor
        
        view.addSubview(createAccountButton)
        view.addSubview(loginButton)
        
        createAccountButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -60).isActive = true
        createAccountButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        createAccountButton.widthAnchor.constraint(equalToConstant: self.view.frame.width - 60).isActive = true
        createAccountButton.heightAnchor.constraint(equalToConstant: (self.view.frame.width - 60)/5.5).isActive = true
        
        loginButton.bottomAnchor.constraint(equalTo: createAccountButton.topAnchor, constant: -20).isActive = true
        loginButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        loginButton.widthAnchor.constraint(equalToConstant: self.view.frame.width - 60).isActive = true
        loginButton.heightAnchor.constraint(equalToConstant: (self.view.frame.width - 60)/5.5).isActive = true
    }

    @objc func login(){
        self.navigationController?.pushViewController(SignIn(), animated: false)
    }
    
    @objc func signup(){
        self.navigationController?.pushViewController(SignUp(), animated: false)
    }
    
    @objc func reloadStartView(notification: NSNotification) {
        self.view.reloadInputViews()
        self.updateViewConstraints()
        setNeedsFocusUpdate()
        
        navigationbarAttributes(Hidden: true, Translucent: false)
    }
}
