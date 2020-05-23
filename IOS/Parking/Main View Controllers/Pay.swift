//
//  Manage.swift
//  Parking
//
//  Created by Omar on 3/28/20.
//  Copyright © 2020 Theory Parking. All rights reserved.
//

import UIKit
import MapKit
import GoogleMaps
import GooglePlaces
import BLTNBoard
import PassKit
import Stripe

class ParkViewController: UIViewController, CLLocationManagerDelegate {
     
    private let locationManager = CLLocationManager()
    var userLocation = CLLocation()
    
    var paymentSucceeded = false

    let checkInButton = createButton(Title: "Check In", FontName: fontBold, FontSize: 20, FontColor: standardBackgroundColor, BorderWidth: 0, CornerRaduis: 5, BackgroundColor: standardContrastColor, BorderColor: UIColor.clear.cgColor, Target: self, Action: #selector(searchLocation))
    let paymentButton = createPaymentButton(Target: self, Action: #selector(checkout))
 
    let currentLocation = createLabel(LabelText: "", TextColor: standardContrastColor, FontName: font, FontSize: 26, TextAlignment: .center, TextBreak: .byWordWrapping, NumberOfLines: 1)
    let timeLabel = createLabel(LabelText: "", TextColor: standardContrastColor, FontName: fontBold, FontSize: 30, TextAlignment: .center, TextBreak: .byWordWrapping, NumberOfLines: 0)
    
    var mainTimer = customTimer()
    var mainNSTimer = Timer()
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
    // BLTNBoard END
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.reloadInputViews()
        createViewLayout()
        paymentButton.isEnabled = Stripe.deviceSupportsApplePay()
        paymentButton.layer.borderColor = UIColor.clear.cgColor
        NotificationCenter.default.addObserver(self, selector: #selector(displayParkingInfo(notification:)), name: NSNotification.Name(rawValue: "checkIn"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(enterLocation(notification:)), name: NSNotification.Name(rawValue: "enterLocation"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(startPayment(notification:)), name: NSNotification.Name(rawValue: "startPayment"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resetTimer(notification:)), name: NSNotification.Name(rawValue: "resetTimer"), object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        setNeedsStatusBarAppearanceUpdate()
        checkConnection()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationbarAttributes(Hidden: false, Translucent: false)
        createViewLayout()
    }
    
    func createViewLayout(){
        view.backgroundColor = standardBackgroundColor
        setupNavigationBar(LargeText: true, Title: "Pay", SystemImageR: true, ImageR: true, ImageTitleR: "ellipsis", TargetR: self, ActionR: #selector(moreInfo), SystemImageL: false, ImageL: false, ImageTitleL: "", TargetL: nil, ActionL: nil)

        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
        
        self.view.addSubview(checkInButton)
        
        checkInButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        checkInButton.centerYAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -180).isActive = true
        checkInButton.widthAnchor.constraint(equalToConstant: self.view.frame.width - 110).isActive = true
        checkInButton.heightAnchor.constraint(equalToConstant: (self.view.frame.width - 60)/5.5).isActive = true

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
        retrieveNearByParking(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude, meters: nearByDistance)
        
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
        if NearByParking.count >= 1 {
            self.bulletinManagerParkingInfo.allowsSwipeInteraction = false
            self.bulletinManagerParkingInfo.showBulletin(above: self)
            
        }else{
            self.bulletinManagerNoParking.allowsSwipeInteraction = false
            self.bulletinManagerNoParking.showBulletin(above: self)
        }
    }
    
    @objc func moreInfo(){
        if NearByParking.isEmpty == true {
            self.bulletinManagerNoParking.showBulletin(above: self)
        }else{
            self.bulletinManagerInfo.showBulletin(above: self)
        }
        
    }
    
    @objc func startPayment(notification: NSNotification){
        checkInButton.removeFromSuperview()
        startDatabaseTimer()
        currentLocation.text = NearByParking[indexPath.row].Organization
        
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
        
        startTimer()
    }
    
    func startTimer(){
        isRunning = !isRunning
    }

    @objc func checkout(){
        proccessPayment()
    }
    
    var isRunning = false {
        didSet {
            if isRunning == true {
                mainTimer.start()
                mainNSTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
                    self.timeLabel.text = self.mainTimer.inString
                    let chargeText = "$" + String(format:"%.2f", (Double(self.mainTimer.inInt) * Double(truncating: NearByParking[indexPath.row].Prices)))
                    self.navigationItem.title = chargeText
                }
            }else{
                mainNSTimer.invalidate()
                mainTimer.pause()
            }
        }
    }
    
}

extension ParkViewController: GMSAutocompleteViewControllerDelegate {
        
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

}


