//
//  Home2.swift
//  Theory Parking
//
//  Created by Omar Waked on 7/6/21.
//  Copyright © 2021 Raedam. All rights reserved.
//

import UIKit
import MapKit
import Alamofire
import SwiftyJSON
import BLTNBoard
import FirebaseAnalytics

class HomeViewController2: UIViewController, CLLocationManagerDelegate {
     
    private let locationManager = CLLocationManager()
    let destinationTextField = createButton(Title: "Destination", FontName: font, FontSize: 20, FontColor: standardContrastColor, BorderWidth: 0, CornerRaduis: 12, BackgroundColor: standardBackgroundColor.withAlphaComponent(0.7), BorderColor: UIColor.clear.cgColor, Target: self, Action: #selector(showRouteInfo))
    var userLocation = CLLocation()
    var destinationLocation = CLLocation()
    
    // BLTNBoard START
    let backgroundStyles = BackgroundStyles()
    var currentBackground = (name: "Dimmed", style: BLTNBackgroundViewStyle.dimmed)
        
    lazy var bulletinManagerStartRoute: BLTNItemManager = {
        let page = BulletinDataSource.startRoute()
        return BLTNItemManager(rootItem: page)
    }()
    
    lazy var bulletinManagerShowInfo: BLTNItemManager = {
        let page = BulletinDataSource.routeInfo()
        return BLTNItemManager(rootItem: page)
    }()
    
    lazy var bulletinManagerCancelRoute: BLTNItemManager = {
        let page = BulletinDataSource.cancelRoute()
        return BLTNItemManager(rootItem: page)
    }()
    
    lazy var bulletinManagerForceLocation: BLTNItemManager = {
        let page = BulletinDataSource.updateLocationSettings()
        return BLTNItemManager(rootItem: page)
    }()
    // BLTNBoard END
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createViewLayout()
        NotificationCenter.default.addObserver(self, selector: #selector(createRoute(notification:)), name: NSNotification.Name(rawValue: "createRoute"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(confirmRoute(notification:)), name: NSNotification.Name(rawValue: "confirmRoute"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(startRoute(notification:)), name: NSNotification.Name(rawValue: "startRoute"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(cancelRoute(notification:)), name: NSNotification.Name(rawValue: "cancelRoute"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(infoRoute(notification:)), name: NSNotification.Name(rawValue: "moreInfo"), object: nil)
    
    }
    

     override func viewDidAppear(_ animated: Bool) {
        setNeedsStatusBarAppearanceUpdate()
        checkConnection()
        
     }
     
     override func viewWillAppear(_ animated: Bool) {
        
        self.view.layoutSubviews()
        self.view.addSubview(destinationTextField)
        destinationTextField.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        destinationTextField.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 80).isActive = true
        destinationTextField.widthAnchor.constraint(equalToConstant: self.view.frame.width - 100).isActive = true
        destinationTextField.heightAnchor.constraint(equalToConstant: (self.view.frame.width - 60)/5.5).isActive = true
        if destinationTextField.isHidden {
            navigationbarAttributes(Hidden: false, Translucent: false)

            if DirectionsData.count > 0 {
                let directionTitle = SelectedParkingData[indexPath.row].Name
                    //DirectionsData[indexPath.row].Manuver

                self.setupNavigationBar(LargeText: true, Title: directionTitle, SystemImageR: true, ImageR: true, ImageTitleR: "ellipsis", TargetR: self, ActionR: #selector(self.showRouteInfo), SystemImageL: false, ImageL: false, ImageTitleL: "", TargetL: self, ActionL: nil)
                let DirectionsTitleAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: standardContrastColor, NSAttributedString.Key.font: UIFont(name: font, size: 28)!]
                self.navigationController?.navigationBar.largeTitleTextAttributes = DirectionsTitleAttributes
            }
        }else{
            navigationbarAttributes(Hidden: true, Translucent: false)
            destinationTextField.isEnabled = true
        }
     }

     func createViewLayout(){
        view.backgroundColor = standardBackgroundColor
         
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.startUpdatingLocation()
        }else{
            locationManager.requestWhenInUseAuthorization()
            //MARK: Force user to enable location
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
        currentUserLocation = location
        locationManager.stopUpdatingLocation()
        
        
        if location.distance(from: destinationLocation) <= blockDistance {
            updateDirectionsView()
        }else{
            
        }

    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading){

    }
    
    @objc func createRoute(notification: NSNotification){
        destinationLocation = CLLocation(latitude: SelectedParkingData[indexPath.row].Location.latitude, longitude: SelectedParkingData[indexPath.row].Location.longitude)
        
        let destinationLocation2D = CLLocationCoordinate2D(latitude: SelectedParkingData[indexPath.row].Location.latitude, longitude: SelectedParkingData[indexPath.row].Location.longitude)
        
        dismiss(animated: true, completion: {

 
        })
    }
    
    @objc func confirmRoute(notification: NSNotification){
        self.bulletinManagerStartRoute.allowsSwipeInteraction = false
        self.bulletinManagerStartRoute.showBulletin(above: self)
    }
    
    @objc func infoRoute(notification: NSNotification){
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.pushViewController(DirectionsTable(), animated: false)
    }
    
    @objc func startRoute(notification: NSNotification){
        destinationLocation = CLLocation(latitude: SelectedParkingData[indexPath.row].Location.latitude, longitude: SelectedParkingData[indexPath.row].Location.longitude)

        let destinationLocation2D = CLLocationCoordinate2D(latitude:  SelectedParkingData[indexPath.row].Location.latitude, longitude: SelectedParkingData[indexPath.row].Location.longitude)
        
        dismiss(animated: true, completion: {
            self.destinationTextField.isHidden = true
        })
    }

    @objc func cancelRoute(notification: NSNotification){
        SelectedParkingData.removeAll()
        self.navigationbarAttributes(Hidden: true, Translucent: true)
        self.destinationTextField.isHidden = false
        self.reloadInputViews()
    }
    
    @objc func showRouteInfo(){
        self.bulletinManagerShowInfo.allowsSwipeInteraction = false
        self.bulletinManagerShowInfo.showBulletin(above: self)
    }
    
    func updateDirectionsView(){
        print("USER NEAR STRUCTURE")
    }

}

