//
//  Manage.swift
//  Parking
//
//  Created by Omar on 3/28/20.
//  Copyright © 2020 Theory Parking. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import BLTNBoard
import PassKit
import Stripe
import FirebaseFunctions

class PayViewController: UIViewController, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    var userLocation = CLLocation()
    
    var idempotencyKey = String()
    let checkInButton = createButton(Title: "Check In", FontName: fontBold, FontSize: 20, FontColor: standardBackgroundColor, BorderWidth: 0, CornerRaduis: 12, BackgroundColor: standardContrastColor, BorderColor: UIColor.clear.cgColor, Target: self, Action: #selector(searchLocation))
    let paymentButton = createPaymentButton(Target: self, Action: #selector(proccessPayment))
    let currentLocation = createLabel(LabelText: "", TextColor: standardContrastColor, FontName: font, FontSize: 26, TextAlignment: .center, TextBreak: .byWordWrapping, NumberOfLines: 1)
    let timeLabel = createLabel(LabelText: "", TextColor: standardContrastColor, FontName: fontBold, FontSize: 30, TextAlignment: .center, TextBreak: .byWordWrapping, NumberOfLines: 0)
    
    var baseURLString: String? = "https://us-central1-theory-parking.cloudfunctions.net"
    var baseURL: URL {
        if let urlString = self.baseURLString, let url = URL(string: urlString) {
            return url
        } else {
            fatalError()
        }
    }
    
    var records = [String]()
    
    // BLTNBoard START
    let backgroundStyles = BackgroundStyles()
    var currentBackground = (name: "Dimmed", style: BLTNBackgroundViewStyle.dimmed)
    
    lazy var bulletinManagerParkingInfo: BLTNItemManager = {
        let page = BulletinDataSource.parkingProviderInfo()
        return BLTNItemManager(rootItem: page)
    }()
    
    lazy var bulletinManagerNoParking: BLTNItemManager = {
        let page = BulletinDataSource.noParkingProviderInfo()
        return BLTNItemManager(rootItem: page)
    }()
    
    lazy var bulletinManagerInfo: BLTNItemManager = {
        let page = BulletinDataSource.parkingInfo()
        return BLTNItemManager(rootItem: page)
    }()
    
    lazy var bulletinManagerPaymentComplete: BLTNItemManager = {
        let page = BulletinDataSource.paymentSuccessful()
        return BLTNItemManager(rootItem: page)
    }()
    
    lazy var bulletinManagerPaymentError: BLTNItemManager = {
        let page = BulletinDataSource.makeErrorPage(message: "Unable to present Apple Pay authorization.")
        return BLTNItemManager(rootItem: page)
    }()
    
    lazy var bulletinManagerLoadingAnimation: BLTNItemManager = {
        let page = BulletinDataSource.LoadingAnimation()
        return BLTNItemManager(rootItem: page)
    }()
    // BLTNBoard END
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.reloadInputViews()
        createViewLayout()
        paymentButton.isEnabled = StripeAPI.deviceSupportsApplePay()
        
        NotificationCenter.default.addObserver(self, selector: #selector(displayParkingInfo(notification:)), name: NSNotification.Name(rawValue: "checkIn"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(enterLocation(notification:)), name: NSNotification.Name(rawValue: "enterLocation"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(startPayment(notification:)), name: NSNotification.Name(rawValue: "startPayment"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resetTimer(notification:)), name: NSNotification.Name(rawValue: "resetTimer"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(transactionCompleted(notification:)), name: NSNotification.Name(rawValue: "endTransaction"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(finishProcessing(notification:)), name: NSNotification.Name(rawValue: "finishProcessing"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(presentLoadingAnimation(notification:)), name: NSNotification.Name(rawValue: "presentLoadingAnimation"), object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        setNeedsStatusBarAppearanceUpdate()
        checkConnection()
        
        if (TransactionData.count > 0) && (TransactionData[indexPath.row].Current) {
            isRunning = !isRunning
            self.checkInButton.removeFromSuperview()
            currentLocation.text = SelectedParkingData[indexPath.row].Organization
            
            self.view.addSubview(currentLocation)
            self.view.addSubview(timeLabel)
            self.view.addSubview(paymentButton)
            
            currentLocation.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            currentLocation.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 80).isActive = true
            currentLocation.widthAnchor.constraint(equalToConstant: self.view.frame.width - 50).isActive = true
            currentLocation.heightAnchor.constraint(equalToConstant: (self.view.frame.width - 60)/5.5).isActive = true

            timeLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            timeLabel.centerYAnchor.constraint(equalTo: self.currentLocation.bottomAnchor, constant: 90).isActive = true
            timeLabel.widthAnchor.constraint(equalToConstant: self.view.frame.width - 100).isActive = true
            timeLabel.heightAnchor.constraint(equalToConstant: (self.view.frame.width - 60)/5.5).isActive = true
            
            paymentButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            paymentButton.centerYAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -180).isActive = true
            paymentButton.widthAnchor.constraint(equalToConstant: self.view.frame.width - 110).isActive = true
            paymentButton.heightAnchor.constraint(equalToConstant: (self.view.frame.width - 60)/5.5).isActive = true
       }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationbarAttributes(Hidden: false, Translucent: false)
        createViewLayout()
    }
    
    func createViewLayout(){
        view.backgroundColor = standardBackgroundColor
        if (TransactionData.count > 0) && (TransactionData[indexPath.row].Current) {
            isRunning = !isRunning
            setupNavigationBar(LargeText: true, Title: "$" + String(format:"%.2f", (Double(mainTimer.inInt) * Double(truncating: SelectedParkingData[indexPath.row].Price))), SystemImageR: true, ImageR: true, ImageTitleR: "ellipsis", TargetR: self, ActionR: #selector(moreInfo), SystemImageL: false, ImageL: false, ImageTitleL: "", TargetL: nil, ActionL: nil)
        }else{
            setupNavigationBar(LargeText: true, Title: "Pay", SystemImageR: true, ImageR: true, ImageTitleR: "ellipsis", TargetR: self, ActionR: #selector(moreInfo), SystemImageL: false, ImageL: false, ImageTitleL: "", TargetL: nil, ActionL: nil)
            
            self.view.addSubview(checkInButton)
            
            checkInButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            checkInButton.centerYAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -180).isActive = true
            checkInButton.widthAnchor.constraint(equalToConstant: self.view.frame.width - 110).isActive = true
            checkInButton.heightAnchor.constraint(equalToConstant: (self.view.frame.width - 60)/5.5).isActive = true
        }
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    
    }
     
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedWhenInUse else {
            return
        }
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        
        userLocation = location
        locationManager.stopUpdatingLocation()
    }
     
    @objc func searchLocation(){
        // MARK: CHECK IF USER HAS PAYMENT SETUP BEFORE ALLOWING THEM TO CHECK IN
        //retrieveNearByParking(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude, meters: nearByDistance)
        if SelectedParkingData.count >= 1 {
            self.bulletinManagerParkingInfo.allowsSwipeInteraction = false
            self.bulletinManagerParkingInfo.showBulletin(above: self)
        }else{
            self.bulletinManagerNoParking.allowsSwipeInteraction = false
            self.bulletinManagerNoParking.showBulletin(above: self)
        }
    }
    
    @objc func enterLocation(notification: NSNotification){
        let AutofillController = GMSAutocompleteViewController()
        AutofillController.delegate = self
        AutofillController.tableCellSeparatorColor = standardContrastColor
        AutofillController.tableCellBackgroundColor = standardBackgroundColor
        AutofillController.primaryTextColor = standardContrastColor
        AutofillController.tableCellSeparatorColor = .darkGray
        present(AutofillController, animated: true, completion: nil)
     }
    
    @objc func displayParkingInfo(notification: NSNotification){
        
    }
    
    @objc func moreInfo(){
        if SelectedParkingData.isEmpty == true {
            self.bulletinManagerNoParking.showBulletin(above: self)
        }else{
            self.bulletinManagerInfo.showBulletin(above: self)
        }
        
    }
    
    @objc func startPayment(notification: NSNotification){
        isRunning = !isRunning
        self.bulletinManagerLoadingAnimation.dismissBulletin()
        checkInButton.removeFromSuperview()
        currentLocation.text = SelectedParkingData[indexPath.row].Organization
        
        self.view.addSubview(currentLocation)
        self.view.addSubview(timeLabel)
        self.view.addSubview(paymentButton)

        currentLocation.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        currentLocation.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 80).isActive = true
        currentLocation.widthAnchor.constraint(equalToConstant: self.view.frame.width - 50).isActive = true
        currentLocation.heightAnchor.constraint(equalToConstant: (self.view.frame.width - 60)/5.5).isActive = true
        
        timeLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        timeLabel.centerYAnchor.constraint(equalTo: self.currentLocation.bottomAnchor, constant: 90).isActive = true
        timeLabel.widthAnchor.constraint(equalToConstant: self.view.frame.width - 100).isActive = true
        timeLabel.heightAnchor.constraint(equalToConstant: (self.view.frame.width - 60)/5.5).isActive = true

        paymentButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        paymentButton.centerYAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -180).isActive = true
        paymentButton.widthAnchor.constraint(equalToConstant: self.view.frame.width - 110).isActive = true
        paymentButton.heightAnchor.constraint(equalToConstant: (self.view.frame.width - 60)/5.5).isActive = true
    }
    
    var isRunning = false {
        didSet {
        if isRunning == true {
                mainTimer.start()
                mainNSTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
                    self.timeLabel.text = mainTimer.inString
                    let chargeText = "$" + String(format:"%.2f", (Double(mainTimer.inInt) * Double(truncating: SelectedParkingData[indexPath.row].Price)))
                    self.navigationItem.title = chargeText
               }
           }else{
               mainNSTimer.invalidate()
               mainTimer.pause()
           }
       }
    }
}

extension PayViewController: GMSAutocompleteViewControllerDelegate {
        
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        destinationName = place.name!
        
        dismiss(animated: true, completion: {
            self.currentLocation.text = destinationName
        })
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print("Error: ", error.localizedDescription)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard UIApplication.shared.applicationState == .inactive else {
            return
        }

        if self.traitCollection.userInterfaceStyle == .dark {
            self.view.reloadInputViews()
        }else{
            self.view.reloadInputViews()
        }
    }
    
    @objc func presentLoadingAnimation(notification: NSNotification){
        self.bulletinManagerLoadingAnimation.allowsSwipeInteraction = false
        self.bulletinManagerLoadingAnimation.showBulletin(above: self)
    }
    

}


