////
////  ParkViewController.swift
////  Theory Parking
////
////  Created by Omar Waked on 6/27/21.
////  Copyright © 2021 Raedam. All rights reserved.
////
//
//import UIKit
//import MapKit
//import GooglePlaces
//import Alamofire
//import SwiftyJSON
//import BLTNBoard
//import FirebaseAnalytics
//
//class ParkViewController: UIViewController, CLLocationManagerDelegate {
// 
//    private let locationManager = CLLocationManager()
//    var userLocation = CLLocation()
//    var destinationLocation = CLLocation()
//    let APIKey = "AIzaSyBLF8x5SR3UJbI-ybS04Bd9TPUebvziMlw"
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        createViewLayout()
//    }
//
//    func updateMapStyle(){
//        if self.traitCollection.userInterfaceStyle == .dark {
//            styleMap(DarkMode: true)
//            self.view.reloadInputViews()
//        }else{
//            styleMap(DarkMode: false)
//            self.view.reloadInputViews()
//        }
//    }
//
//    override func viewDidAppear(_ animated: Bool) {
//        setNeedsStatusBarAppearanceUpdate()
//        checkConnection()
//        updateMapStyle()
//    }
// 
//    override func viewWillAppear(_ animated: Bool) {
//        updateMapStyle()
//        self.view.layoutSubviews()
//    }
//
//    func createViewLayout(){
//        view.backgroundColor = standardBackgroundColor
//        setupNavigationBar(LargeText: true, Title: "Park", SystemImageR: false, ImageR: false, ImageTitleR: "", TargetR: nil, ActionR: nil, SystemImageL: false, ImageL: false, ImageTitleL: "", TargetL: nil, ActionL: nil)
//        
//        if CLLocationManager.locationServicesEnabled() {
//            locationManager.delegate = self
//            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
//            locationManager.startUpdatingLocation()
//            mapView.isMyLocationEnabled = true
//            mapView.settings.allowScrollGesturesDuringRotateOrZoom = true
//            mapView.settings.rotateGestures = true
//        }else{
//            locationManager.requestWhenInUseAuthorization()
//        //MARK: Force user to enable location
//        }
//        view = mapView
// }
// 
//    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//        guard status == .authorizedWhenInUse else {
//            return
//        }
//        locationManager.startUpdatingLocation()
//        mapView.camera = GMSCameraPosition(target: userLocation.coordinate, zoom: 17)
//    }
// 
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let location = locations.first else {
//            return
//        }
//        userLocation = location
//        currentUserLocation = location
//        mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 17, bearing: 0, viewingAngle: 0)
//        locationManager.stopUpdatingLocation()
//        let update = GMSCameraUpdate.setTarget(location.coordinate)
//        mapView.moveCamera(update)
//    }
//
//
//    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading){
//
//    }
//
//}
//
//extension ParkViewController {
//    func styleMap(DarkMode: Bool) {
//        mapView.settings.myLocationButton = true
//        mapView.settings.rotateGestures = false
//        var style = String()
//        
//        if DarkMode == true || userDefaults.bool(forKey: "THEME") == true {
//            style = "darkstyle"
//        }else{
//            style = "lightstyle"
//        }
//        
//        do{
//            if let styleURL = Bundle.main.url(forResource: style, withExtension: "json") {
//                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
//            }else{
//                print("Unable to find style.json")
//            }
//        }catch{
//            print("One or more of the map styles failed to load. \(error)")
//        }
//    }
//        
//    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//        super.traitCollectionDidChange(previousTraitCollection)
//
//        guard UIApplication.shared.applicationState == .inactive else {
//            return
//        }
//
//        if self.traitCollection.userInterfaceStyle == .dark {
//            styleMap(DarkMode: true)
//            self.view.reloadInputViews()
//        }else{
//            styleMap(DarkMode: false)
//            self.view.reloadInputViews()
//        }
//    }
//}
