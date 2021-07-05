//
//  BetaSignUpViewController.swift
//  Theory Parking
//
//  Created by Omar Waked on 7/4/21.
//  Copyright © 2021 Raedam. All rights reserved.
//

import Foundation
import Firebase
import UIKit
import BLTNBoard
import Lottie

class BetaSignUpView: UIViewController {
    
    let signupButton = createButton(Title: "Reserve my Spot", FontName: font, FontSize: 25, FontColor: standardBackgroundColor, BorderWidth: 1.5, CornerRaduis: 12, BackgroundColor: standardContrastColor, BorderColor: UIColor.white.cgColor, Target: self, Action: #selector(signup))
    let learnMoreButton = createButton(Title: "Learn More", FontName: font, FontSize: 20, FontColor: standardTintColor, BorderWidth: 0, CornerRaduis: 0, BackgroundColor: standardClearColor, BorderColor: UIColor.clear.cgColor, Target: self, Action: #selector(learnMore))
    var currentBackground = (name: "Dimmed", style: BLTNBackgroundViewStyle.dimmed)
    let backgroundStyles = BackgroundStyles()
    var animationString = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadStartView(notification:)), name: NSNotification.Name(rawValue: "reloadStartView"), object: nil)
        createScreenLayout()
    }
    
    lazy var bulletinManagerReserveSpot: BLTNItemManager = {
        let page = BulletinDataSource.reserveSpot()
        return BLTNItemManager(rootItem: page)
    }()
    

    override func viewDidAppear(_ animated: Bool) {
        setNeedsStatusBarAppearanceUpdate()
        checkConnection()
        view.setNeedsFocusUpdate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationbarAttributes(Hidden: false, Translucent: false)
        setupNavigationBar(LargeText: true, Title: "Raedam", SystemImageR: false, ImageR: false, ImageTitleR: "", TargetR: nil, ActionR: nil, SystemImageL: false, ImageL: false, ImageTitleL: "", TargetL: nil, ActionL: nil)
    }
    
    func createScreenLayout(){
        view.backgroundColor = standardBackgroundColor
        animationString = "b1"
        var loadingAnimation = Animation.named(animationString)
        
        if self.traitCollection.userInterfaceStyle == .dark {
            loadingAnimation = Animation.named("b1")
            self.view.reloadInputViews()
        }else{
            loadingAnimation = Animation.named("b2")
            self.view.reloadInputViews()
        }
        
        let lottieView = AnimationView(animation: loadingAnimation)
        // 2. SECOND STEP (Adding and setup):
        self.view.addSubview(lottieView)
        lottieView.contentMode = .scaleAspectFit
        lottieView.loopMode = .loop
        lottieView.animationSpeed = 0.5
        lottieView.play(toFrame: .infinity)
        // 3. THIRD STEP (LAYOUT PREFERENCES):
        lottieView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lottieView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            lottieView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            lottieView.topAnchor.constraint(equalTo: self.view.topAnchor),
            lottieView.bottomAnchor.constraint(equalTo: self.view.centerYAnchor, constant: 100)
        ])
        
        view.addSubview(signupButton)
        view.addSubview(learnMoreButton)
        
        learnMoreButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30).isActive = true
        learnMoreButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        learnMoreButton.widthAnchor.constraint(equalToConstant: self.view.frame.width - 60).isActive = true
        learnMoreButton.heightAnchor.constraint(equalToConstant: (self.view.frame.width - 60)/5.5).isActive = true
        
        signupButton.bottomAnchor.constraint(equalTo: learnMoreButton.bottomAnchor, constant: -60).isActive = true
        signupButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        signupButton.widthAnchor.constraint(equalToConstant: self.view.frame.width - 60).isActive = true
        signupButton.heightAnchor.constraint(equalToConstant: (self.view.frame.width - 60)/5.5).isActive = true

    }

    @objc func signup(){
        bulletinManagerReserveSpot.allowsSwipeInteraction = false
        self.bulletinManagerReserveSpot.showBulletin(above: self)
    }
    
    @objc func learnMore(){
        openWeb(Title: "Learn More", URL: "https://raedam.co")
    }
 
    @objc func reloadStartView(notification: NSNotification) {
        self.view.reloadInputViews()
        self.updateViewConstraints()
        setNeedsFocusUpdate()
        
        navigationbarAttributes(Hidden: true, Translucent: false)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard UIApplication.shared.applicationState == .inactive else {
            return
        }

        if self.traitCollection.userInterfaceStyle == .dark {
            animationString = "b1"
            self.view.reloadInputViews()
        }else{
            animationString = "b2"
            self.view.reloadInputViews()
        }
    }
}
