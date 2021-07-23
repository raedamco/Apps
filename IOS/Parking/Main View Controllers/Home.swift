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

let APIKey = "AIzaSyBLF8x5SR3UJbI-ybS04Bd9TPUebvziMlw"
var darkMapStyle = "mapbox://styles/omarwaked/ckr8fjs3i2nbx19pd2tpkosu2"
var lightMapStyle = "mapbox://styles/omarwaked/ckr8g3omj4b3p17mzxu40u71m"

class HomeViewController: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate {
     
    let locationManager = CLLocationManager()
    let destinationTextField = createButton(Title: "Destination", FontName: font, FontSize: 20, FontColor: standardContrastColor, BorderWidth: 0, CornerRaduis: 12, BackgroundColor: standardBackgroundColor.withAlphaComponent(0.7), BorderColor: UIColor.clear.cgColor, Target: self, Action: #selector(searchLocation))
    var userLocation = CLLocation()
    var destinationLocation = CLLocation()
    var mapView: MGLMapView?
    var mapStyle = String()
    var style = [Style]()
    
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
        NotificationCenter.default.addObserver(self, selector: #selector(confirmRoute(notification:)), name: NSNotification.Name(rawValue: "confirmRoute"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(startRoute(notification:)), name: NSNotification.Name(rawValue: "startRoute"), object: nil)
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
        navigationbarAttributes(Hidden: true, Translucent: false)
     }
    
    func createMap(){
        let mapView = MGLMapView(frame: view.bounds, styleURL: URL(string: mapStyle))
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
        }else{
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
    
    @objc func startRoute(notification: NSNotification){
        destinationLocation = CLLocation(latitude: SelectedParkingData[indexPath.row].Location.latitude, longitude: SelectedParkingData[indexPath.row].Location.longitude)
        let destinationLocation2D = CLLocationCoordinate2D(latitude:  SelectedParkingData[indexPath.row].Location.latitude, longitude: SelectedParkingData[indexPath.row].Location.longitude)
        
        dismiss(animated: true, completion: {
            let origin = Waypoint(coordinate: CLLocationCoordinate2D(latitude: self.userLocation.coordinate.latitude, longitude: self.userLocation.coordinate.longitude), name: "Current Location")
            let destination = Waypoint(coordinate: CLLocationCoordinate2D(latitude: destinationLocation2D.latitude, longitude: destinationLocation2D.longitude), name: "Destination")
            let routeOptions = NavigationRouteOptions(waypoints: [origin, destination])

            Directions.shared.calculate(routeOptions) { [weak self] (session, result) in
                switch result {
                case .failure(let error):
                    print(error.localizedDescription)
                case .success(let response):
                    guard let route = response.routes?.first, let strongSelf = self else {
                        return
                    }
//                    simulationIsEnabled ? .always : .onPoorGPS
                    let navigationService = MapboxNavigationService(route: route, routeIndex: 0, routeOptions: routeOptions, simulating: .always)

                    let navigationOptions = NavigationOptions(styles: self!.style, navigationService: navigationService)
                    let viewController = NavigationViewController(for: route, routeIndex: 0, routeOptions: routeOptions, navigationOptions: navigationOptions)
                    viewController.modalPresentationStyle = .fullScreen
                    viewController.view.backgroundColor = standardBackgroundColor
                    strongSelf.present(viewController, animated: true, completion: nil)
                    viewController.showsEndOfRouteFeedback = false
                    if viewController.isBeingDismissed {
                        SelectedParkingData.removeAll()
                    }
                }
            }
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
            style = [CustomDayStyle()]
            self.view.reloadInputViews()
        }else{
            mapStyle = lightMapStyle
            style = [CustomNightStyle()]
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


class CustomDayStyle: DayStyle {
 
    private let backgroundColor = #colorLiteral(red: 0.06276176125, green: 0.6164312959, blue: 0.3432356119, alpha: 1)
    private let darkBackgroundColor = #colorLiteral(red: 0.0473754704, green: 0.4980872273, blue: 0.2575169504, alpha: 1)
    private let secondaryBackgroundColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
    private let blueColor = #colorLiteral(red: 0.26683864, green: 0.5903761983, blue: 1, alpha: 1)
    private let lightGrayColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
    private let darkGrayColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    private let primaryLabelColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    private let secondaryLabelColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.9)
     
    required init() {
        super.init()
        mapStyleURL = URL(string: lightMapStyle)!
        styleType = .day
    }
 
    override func apply() {
        super.apply()
        ArrivalTimeLabel.appearance().textColor = lightGrayColor
        BottomBannerView.appearance().backgroundColor = secondaryBackgroundColor
        Button.appearance().textColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        CancelButton.appearance().tintColor = lightGrayColor
        DistanceLabel.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).unitTextColor = secondaryLabelColor
        DistanceLabel.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).valueTextColor = primaryLabelColor
        DistanceLabel.appearance(whenContainedInInstancesOf: [StepInstructionsView.self]).unitTextColor = lightGrayColor
        DistanceLabel.appearance(whenContainedInInstancesOf: [StepInstructionsView.self]).valueTextColor = darkGrayColor
        DistanceRemainingLabel.appearance().textColor = lightGrayColor
        DismissButton.appearance().textColor = darkGrayColor
        FloatingButton.appearance().backgroundColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
        FloatingButton.appearance().tintColor = blueColor
        InstructionsBannerView.appearance().backgroundColor = backgroundColor
        LanesView.appearance().backgroundColor = darkBackgroundColor
        LaneView.appearance().primaryColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        ManeuverView.appearance().backgroundColor = backgroundColor
        ManeuverView.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).primaryColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        ManeuverView.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).secondaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5)
        ManeuverView.appearance(whenContainedInInstancesOf: [NextBannerView.self]).primaryColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        ManeuverView.appearance(whenContainedInInstancesOf: [NextBannerView.self]).secondaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5)
        ManeuverView.appearance(whenContainedInInstancesOf: [StepInstructionsView.self]).primaryColor = darkGrayColor
        ManeuverView.appearance(whenContainedInInstancesOf: [StepInstructionsView.self]).secondaryColor = lightGrayColor
        MarkerView.appearance().pinColor = blueColor
        NextBannerView.appearance().backgroundColor = backgroundColor
        NextInstructionLabel.appearance().textColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        NavigationMapView.appearance().tintColor = blueColor
        NavigationMapView.appearance().routeCasingColor = #colorLiteral(red: 0.1968861222, green: 0.4148176908, blue: 0.8596113324, alpha: 1)
        NavigationMapView.appearance().trafficHeavyColor = #colorLiteral(red: 0.9995597005, green: 0, blue: 0, alpha: 1)
        NavigationMapView.appearance().trafficLowColor = blueColor
        NavigationMapView.appearance().trafficModerateColor = #colorLiteral(red: 1, green: 0.6184511781, blue: 0, alpha: 1)
        NavigationMapView.appearance().trafficSevereColor = #colorLiteral(red: 0.7458544374, green: 0.0006075350102, blue: 0, alpha: 1)
        NavigationMapView.appearance().trafficUnknownColor = blueColor
        // Customize the color that appears on the traversed section of a route
        NavigationMapView.appearance().traversedRouteColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 0.5)
        PrimaryLabel.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).normalTextColor = primaryLabelColor
        PrimaryLabel.appearance(whenContainedInInstancesOf: [StepInstructionsView.self]).normalTextColor = darkGrayColor
        ResumeButton.appearance().backgroundColor = secondaryBackgroundColor
        ResumeButton.appearance().tintColor = blueColor
        SecondaryLabel.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).normalTextColor = secondaryLabelColor
        SecondaryLabel.appearance(whenContainedInInstancesOf: [StepInstructionsView.self]).normalTextColor = darkGrayColor
        TimeRemainingLabel.appearance().textColor = lightGrayColor
        TimeRemainingLabel.appearance().trafficLowColor = darkBackgroundColor
        TimeRemainingLabel.appearance().trafficUnknownColor = darkGrayColor
        WayNameLabel.appearance().normalTextColor = blueColor
        WayNameView.appearance().backgroundColor = secondaryBackgroundColor
    }
}
 
class CustomNightStyle: NightStyle {
 
    private let backgroundColor = #colorLiteral(red: 0.06276176125, green: 0.6164312959, blue: 0.3432356119, alpha: 1)
    private let darkBackgroundColor = #colorLiteral(red: 0.0473754704, green: 0.4980872273, blue: 0.2575169504, alpha: 1)
    private let secondaryBackgroundColor = #colorLiteral(red: 0.1335069537, green: 0.133641988, blue: 0.1335278749, alpha: 1)
    private let blueColor = #colorLiteral(red: 0.26683864, green: 0.5903761983, blue: 1, alpha: 1)
    private let lightGrayColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
    private let darkGrayColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    private let primaryTextColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    private let secondaryTextColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.9)
     
    required init() {
        super.init()
        mapStyleURL = URL(string: darkMapStyle)!
        styleType = .night
    }
     
    override func apply() {
        super.apply()
        DistanceRemainingLabel.appearance().normalTextColor = primaryTextColor
        BottomBannerView.appearance().backgroundColor = secondaryBackgroundColor
        FloatingButton.appearance().backgroundColor = #colorLiteral(red: 0.1434620917, green: 0.1434366405, blue: 0.1819391251, alpha: 0.9037466989)
        TimeRemainingLabel.appearance().textColor = primaryTextColor
        TimeRemainingLabel.appearance().trafficLowColor = primaryTextColor
        TimeRemainingLabel.appearance().trafficUnknownColor = primaryTextColor
        ResumeButton.appearance().backgroundColor = #colorLiteral(red: 0.1434620917, green: 0.1434366405, blue: 0.1819391251, alpha: 0.9037466989)
        ResumeButton.appearance().tintColor = blueColor
    }
}
