//
//  HomeViewController.swift
//  Parking
//
//  Created by Omar on 9/8/19.
//  Copyright © 2019 WAKED. All rights reserved.
//

import UIKit
import MapKit
import GoogleMaps
import GooglePlaces
import Alamofire
import SwiftyJSON
import BLTNBoard

var selectedParkingLocation = CLLocation()

class HomeViewController: UIViewController, CLLocationManagerDelegate {
     
    private let locationManager = CLLocationManager()
    let destinationTextField = createButton(Title: "Destination", FontName: font, FontSize: 20, FontColor: standardContrastColor, BorderWidth: 0, CornerRaduis: 5, BackgroundColor: standardBackgroundColor.withAlphaComponent(0.7), BorderColor: UIColor.clear.cgColor, Target: self, Action: #selector(searchLocation))
    let mapView = GMSMapView()
    var userLocation = CLLocation()
    var destinationLocation = CLLocation()
    var polyline = GMSPolyline()
    var circle = GMSCircle()
    let APIKey = "AIzaSyBLF8x5SR3UJbI-ybS04Bd9TPUebvziMlw"
    
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
    
    func updateMapStyle(){
        if self.traitCollection.userInterfaceStyle == .dark {
            styleMap(DarkMode: true)
            self.view.reloadInputViews()
        }else{
            styleMap(DarkMode: false)
            self.view.reloadInputViews()
        }
    }
     
     override func viewDidAppear(_ animated: Bool) {
        setNeedsStatusBarAppearanceUpdate()
        checkConnection()
        updateMapStyle()
        
     }
     
     override func viewWillAppear(_ animated: Bool) {
        updateMapStyle()
        
        self.view.addSubview(destinationTextField)
        destinationTextField.target(forAction: #selector(self.searchLocation), withSender: self)
        destinationTextField.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        destinationTextField.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 100).isActive = true
        destinationTextField.widthAnchor.constraint(equalToConstant: self.view.frame.width - 100).isActive = true
        destinationTextField.heightAnchor.constraint(equalToConstant: (self.view.frame.width - 60)/5.5).isActive = true
        
        self.view.layoutSubviews()
    
        if destinationTextField.isHidden {
            navigationbarAttributes(Hidden: false, Translucent: false)
            self.setupNavigationBar(LargeText: true, Title: destinationName, SystemImageR: true, ImageR: true, ImageTitleR: "info.circle", TargetR: self, ActionR: #selector(self.showRouteInfo), SystemImageL: true, ImageL: true, ImageTitleL: "xmark", TargetL: self, ActionL: #selector(self.cancelRoute(notification:)))
        }else{
            navigationbarAttributes(Hidden: true, Translucent: false)
        }
     }

     func createViewLayout(){
        view.backgroundColor = standardBackgroundColor
         
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.startUpdatingLocation()
            mapView.isMyLocationEnabled = true
            mapView.settings.allowScrollGesturesDuringRotateOrZoom = true
            mapView.settings.rotateGestures = true
        }else{
            locationManager.requestWhenInUseAuthorization()
            //Force user to enable location
        }
        
         view = mapView
     }
     
     func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
         guard status == .authorizedWhenInUse else {
             return
         }
         locationManager.startUpdatingLocation()
         mapView.isMyLocationEnabled = true
     }
     
     func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
         guard let location = locations.first else {
             return
         }
        userLocation = location
        mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 17, bearing: 0, viewingAngle: 0)
        locationManager.stopUpdatingLocation()
     }
     
     @objc func searchLocation(){
        let AutofillController = GMSAutocompleteViewController()
        AutofillController.delegate = self
        AutofillController.tableCellSeparatorColor = standardContrastColor
        AutofillController.tableCellBackgroundColor = standardBackgroundColor
        AutofillController.primaryTextColor = standardContrastColor
        AutofillController.tableCellSeparatorColor = .darkGray
        present(AutofillController, animated: true, completion: nil)
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
        destinationLocation = CLLocation(latitude: SelectedParkingData[indexPath.row].Location.latitude, longitude: SelectedParkingData[indexPath.row].Location.longitude)
        
        let destinationLocation2D = CLLocationCoordinate2D(latitude:  SelectedParkingData[indexPath.row].Location.latitude, longitude: SelectedParkingData[indexPath.row].Location.longitude)
        
        dismiss(animated: true, completion: {
            self.mapView.settings.compassButton = true
            self.mapView.settings.myLocationButton = true
            self.drawCircle(position: destinationLocation2D)
            self.getRouteSteps(source: self.userLocation.coordinate, destination: self.destinationLocation.coordinate)
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
            self.drawCircle(position: destinationLocation2D)
            self.getRouteSteps(source: self.userLocation.coordinate, destination: self.destinationLocation.coordinate)
            self.destinationTextField.isHidden = true
            self.navigationbarAttributes(Hidden: false, Translucent: false)
            self.setupNavigationBar(LargeText: true, Title: destinationName, SystemImageR: true, ImageR: true, ImageTitleR: "info.circle", TargetR: self, ActionR: #selector(self.showRouteInfo), SystemImageL: true, ImageL: true, ImageTitleL: "xmark", TargetL: self, ActionL: #selector(self.cancelRouteConfirm(notification:)))
        })
    }
    
    @objc func cancelRouteConfirm(notification: NSNotification){
        self.bulletinManagerCancelRoute.allowsSwipeInteraction = false
        self.bulletinManagerCancelRoute.showBulletin(above: self)
    }
    
    @objc func cancelRoute(notification: NSNotification){
        self.mapView.camera = GMSCameraPosition(target: userLocation.coordinate, zoom: 17, bearing: 0, viewingAngle: 0)
        SelectedParkingData.removeAll()
        self.navigationbarAttributes(Hidden: true, Translucent: true)
        self.destinationTextField.isHidden = false
        self.mapView.clear()
    }
    
    
    @objc func showRouteInfo(){
        self.bulletinManagerShowInfo.allowsSwipeInteraction = false
        self.bulletinManagerShowInfo.showBulletin(above: self)
    }
    

    func drawCircle(position: CLLocationCoordinate2D) {
        circle = GMSCircle(position: position, radius: 30)
        circle.fillColor = UIColor(red:0.13, green:0.35, blue:0.88, alpha:0.35)
        circle.strokeColor = .white
        circle.map = mapView
    }
    
    func drawPath(from polyStr: String){
       let path = GMSPath(fromEncodedPath: polyStr)
       let polyline = GMSPolyline(path: path)
       polyline.strokeColor = UIColor(red: 0.08, green: 0.43, blue: 0.88, alpha: 1.00)
       polyline.strokeWidth = 3.0
       polyline.map = mapView

       let currentZoom = mapView.camera.zoom
       let cameraUpdate = GMSCameraUpdate.fit(GMSCoordinateBounds(coordinate: self.userLocation.coordinate, coordinate: self.destinationLocation.coordinate))
       mapView.moveCamera(cameraUpdate)
       mapView.animate(toZoom: currentZoom - 0.2)

    }
    
    func getRouteSteps(source: CLLocationCoordinate2D,destination: CLLocationCoordinate2D) {
        let session = URLSession.shared

        let url = URL(string: "https://maps.googleapis.com/maps/api/directions/json?origin=\(source.latitude),\(source.longitude)&destination=\(destination.latitude),\(destination.longitude)&sensor=false&mode=driving&key=\(APIKey)")!

        let task = session.dataTask(with: url, completionHandler: {
            (data, response, error) in

            guard error == nil else {
                print(error!.localizedDescription)
                return
            }

            guard let jsonResult = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any] else {
                print("error in JSONSerialization")
                return
            }

            guard let routes = jsonResult["routes"] as? [Any] else { return }
            guard let route = routes[0] as? [String: Any] else { return }
            guard let legs = route["legs"] as? [Any] else { return }
            guard let leg = legs[0] as? [String: Any] else { return }
            guard let steps = leg["steps"] as? [Any] else { return }
            guard let duration = leg["duration"] as? [String: Any] else { return }
            guard let distance = leg["distance"] as? [String: Any] else { return }

            RouteData.append(RouteInfo(Time: String(describing: duration["text"]! as Any), Distance: String(describing: distance["text"]! as Any)))

            for item in steps {
                guard let step = item as? [String: Any] else { return }
                guard let stepTurns = step["html_instructions"] as? String else { return }
                guard let stepDistance = step["distance"] as? [String: Any] else { return }
                guard let stepTime = step["duration"] as? [String: Any] else { return }
                guard let polyline = step["polyline"] as? [String: Any] else { return }
                guard let polyLineString = polyline["points"] as? String else { return }
                
                DispatchQueue.main.async {
                    self.drawPath(from: polyLineString)
                }
                
                DirectionsData.append(DirectionsInfo(Time: String(describing: stepTime["text"]! as Any), Distance: String(describing: stepDistance["text"]! as Any), Manuver: stepTurns.html2String))
                //step["maneuver"] as? String ?? ""
            }

        })
        task.resume()
    }
    
    
    
    func styleMap(DarkMode: Bool) {
        mapView.settings.myLocationButton = true
        mapView.settings.rotateGestures = false
        var style = String()
        
        if DarkMode == true {
            style = "darkstyle"
        }else{
            style = "lightstyle"
        }
        
        do{
            if let styleURL = Bundle.main.url(forResource: style, withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            }else{
                NSLog("Unable to find style.json")
            }
        }catch{
            NSLog("One or more of the map styles failed to load. \(error)")
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

        if self.traitCollection.userInterfaceStyle == .dark {
            styleMap(DarkMode: true)
            self.view.reloadInputViews()
        }else{
            styleMap(DarkMode: false)
            self.view.reloadInputViews()
        }
    }
    
    
    
}
