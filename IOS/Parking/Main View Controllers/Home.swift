//
//  Home2.swift
//  Theory Parking
//
//  Created by Omar Waked on 7/6/21.
//  Copyright © 2021 Raedam. All rights reserved.
//

import UIKit
import MapKit
import GooglePlaces
import Alamofire
import SwiftyJSON
import BLTNBoard
import FirebaseAnalytics
import Mapbox
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation

class HomeViewController: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate {
     
    let locationManager = CLLocationManager()
    let destinationTextField = createButton(Title: "Destination", FontName: font, FontSize: 20, FontColor: standardContrastColor, BorderWidth: 0, CornerRaduis: 12, BackgroundColor: standardBackgroundColor.withAlphaComponent(0.7), BorderColor: UIColor.clear.cgColor, Target: self, Action: #selector(searchLocation))
    var userLocation = CLLocation()
    var destinationLocation = CLLocation()
    let APIKey = "AIzaSyBLF8x5SR3UJbI-ybS04Bd9TPUebvziMlw"
    var mapView: MGLMapView?
    var mapStyle = String()
    var darkMapStyle = "mapbox://styles/omarwaked/ckr8fjs3i2nbx19pd2tpkosu2" 
    var lightMapStyle = "mapbox://styles/omarwaked/ckr8fjs3i2nbx19pd2tpkosu2"
    
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
        view.backgroundColor = standardBackgroundColor

        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.startUpdatingLocation()
        }else{
            locationManager.requestWhenInUseAuthorization()
            //MARK: Force user to enable location
        }

        updateMapStyle()
        NotificationCenter.default.addObserver(self, selector: #selector(createRoute(notification:)), name: NSNotification.Name(rawValue: "createRoute"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(confirmRoute(notification:)), name: NSNotification.Name(rawValue: "confirmRoute"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(startRoute(notification:)), name: NSNotification.Name(rawValue: "startRoute"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(cancelRoute(notification:)), name: NSNotification.Name(rawValue: "cancelRoute"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(infoRoute(notification:)), name: NSNotification.Name(rawValue: "moreInfo"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadMap(notification:)), name: NSNotification.Name(rawValue: "loadMap"), object: nil)
    }

     override func viewDidAppear(_ animated: Bool) {
        setNeedsStatusBarAppearanceUpdate()
        checkConnection()
     }
     
     override func viewWillAppear(_ animated: Bool) {
        self.view.layoutSubviews()
        createMap()
        self.view.addSubview(destinationTextField)
        destinationTextField.target(forAction: #selector(self.searchLocation), withSender: self)
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
    
    func createMap(){
        print(currentUserLocation)
        let mapView = MGLMapView(frame: view.bounds, styleURL: URL(string: darkMapStyle))
        mapView.setCenter(CLLocationCoordinate2D(latitude: currentUserLocation.coordinate.latitude, longitude: currentUserLocation.coordinate.longitude), zoomLevel: 17, animated: false)
        mapView.showsTraffic = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.showsTraffic = true
        view.addSubview(mapView)
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
//        mapView?.setCenter(CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude), zoomLevel: 17, animated: false)
        locationManager.stopUpdatingLocation()

        if location.distance(from: destinationLocation) <= blockDistance {
            updateDirectionsView()
        }
    }
         
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading){

    }

     @objc func searchLocation(){
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
                case .notDetermined, .restricted, .denied:
                    self.bulletinManagerForceLocation.allowsSwipeInteraction = false
                    self.bulletinManagerForceLocation.showBulletin(above: self)
                case .authorizedAlways, .authorizedWhenInUse:
                    let AutofillController = GMSAutocompleteViewController()
                    AutofillController.delegate = self
                    AutofillController.tableCellSeparatorColor = standardContrastColor
                    AutofillController.tableCellBackgroundColor = standardBackgroundColor
                    AutofillController.primaryTextColor = standardContrastColor
                    AutofillController.tableCellSeparatorColor = .darkGray
                    present(AutofillController, animated: true, completion: nil)
                @unknown default:
                break
            }
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
}

extension HomeViewController: GMSAutocompleteViewControllerDelegate {

    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        destinationName = place.name!
        
        dismiss(animated: true) {
            SelectedParkingData.removeAll()
            getDocumentNearBy(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude, meters: 1000)
            showView(self: self, ViewController: ResultView())
        }
    }
    
    @objc func createRoute(notification: NSNotification){
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
            // Define two waypoints to travel between
            let origin = Waypoint(coordinate: CLLocationCoordinate2D(latitude: self.userLocation.coordinate.latitude, longitude: self.userLocation.coordinate.longitude), name: "Current Location")
            let destination = Waypoint(coordinate: CLLocationCoordinate2D(latitude: destinationLocation2D.latitude, longitude: destinationLocation2D.longitude), name: "Destination")

            // Set options
            let routeOptions = NavigationRouteOptions(waypoints: [origin, destination])

            // Request a route using MapboxDirections.swift
            Directions.shared.calculate(routeOptions) { [weak self] (session, result) in
                switch result {
                case .failure(let error):
                    print(error.localizedDescription)
                case .success(let response):
                    guard let route = response.routes?.first, let strongSelf = self else {
                        return
                    }
                    // Pass the first generated route to the the NavigationViewController
                    let viewController = NavigationViewController(for: route, routeIndex: 0, routeOptions: routeOptions)
                    viewController.modalPresentationStyle = .fullScreen
                    strongSelf.present(viewController, animated: true, completion: nil)
                    if viewController.isBeingDismissed {
                        print("NAV CLOSED")
                    }
                }
            }
        })
    }

    @objc func cancelRoute(notification: NSNotification){
        SelectedParkingData.removeAll()
        self.navigationbarAttributes(Hidden: true, Translucent: true)
        self.destinationTextField.isHidden = false
        self.reloadInputViews()
    }
    
    @objc func loadMap(notification: NSNotification) {
//        if !SelectedParkingData.isEmpty {
//            destinationTextField.isEnabled = false
//            destinationTextField.isHidden = true
//            destinationLocation = CLLocation(latitude: SelectedParkingData[indexPath.row].Location.latitude, longitude: SelectedParkingData[indexPath.row].Location.longitude)
//
//            if DirectionsData.isEmpty {
//                self.getRouteSteps(source: self.userLocation.coordinate, destination: self.destinationLocation.coordinate)
//            }
//        }else{
//            destinationTextField.isEnabled = true
//            destinationTextField.isHidden = false
//        }
    }
    
    @objc func showRouteInfo(){
        self.bulletinManagerShowInfo.allowsSwipeInteraction = false
        self.bulletinManagerShowInfo.showBulletin(above: self)
    }
    
    func updateDirectionsView(){
        print("USER NEAR STRUCTURE")
    }
    
    func updateMapStyle(){
        if self.traitCollection.userInterfaceStyle == .dark {
            mapStyle = darkMapStyle
            self.view.reloadInputViews()
        }else{
            mapStyle = lightMapStyle
            self.view.reloadInputViews()
        }
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
        
        updateMapStyle()
    }
    
}

