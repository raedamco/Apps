//
//  HomeViewController.swift
//  Parking
//
//  Created for Theory Parking on 9/8/19.
//  Copyright © 2020 Theory Parking. All rights reserved.
//
import UIKit
import MapKit
import GoogleMaps
import GooglePlaces
import Alamofire
import SwiftyJSON
import BLTNBoard
import FirebaseAnalytics

var selectedParkingLocation = CLLocation()
var currentUserLocation = CLLocation()

class HomeViewController: UIViewController, CLLocationManagerDelegate {
     
    private let locationManager = CLLocationManager()
    let destinationTextField = createButton(Title: "Destination", FontName: font, FontSize: 20, FontColor: standardContrastColor, BorderWidth: 0, CornerRaduis: 12, BackgroundColor: standardBackgroundColor.withAlphaComponent(0.7), BorderColor: UIColor.clear.cgColor, Target: self, Action: #selector(searchLocation))
    let mapView = GMSMapView()
    var userLocation = CLLocation()
    var destinationLocation = CLLocation()
    var polyline = GMSPolyline()
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
        NotificationCenter.default.addObserver(self, selector: #selector(loadMap(notification:)), name: NSNotification.Name(rawValue: "loadMap"), object: nil)
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
        self.view.layoutSubviews()
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
            //MARK: Force user to enable location
        }
        
        view = mapView
     }
     
     func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedWhenInUse else {
            return
        }
        locationManager.startUpdatingLocation()
        mapView.camera = GMSCameraPosition(target: userLocation.coordinate, zoom: 17)
        
     }
     
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        
        userLocation = location
        currentUserLocation = location
        mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 17, bearing: 0, viewingAngle: 0)
        locationManager.stopUpdatingLocation()
        let update = GMSCameraUpdate.setTarget(location.coordinate)
        mapView.moveCamera(update)


        if location.distance(from: destinationLocation) <= blockDistance {
            updateDirectionsView()
        }else{
            
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
                    print("location enabled")
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
        destinationLocation = CLLocation(latitude: SelectedParkingData[indexPath.row].Location.latitude, longitude: SelectedParkingData[indexPath.row].Location.longitude)
        
        let destinationLocation2D = CLLocationCoordinate2D(latitude: SelectedParkingData[indexPath.row].Location.latitude, longitude: SelectedParkingData[indexPath.row].Location.longitude)
        
        dismiss(animated: true, completion: {
            self.mapView.settings.compassButton = true
            self.mapView.settings.myLocationButton = true
            self.addMarker(position: destinationLocation2D)
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
            self.addMarker(position: destinationLocation2D)
            self.getRouteSteps(source: self.userLocation.coordinate, destination: self.destinationLocation.coordinate)
            self.destinationTextField.isHidden = true
        })
    }

    @objc func cancelRoute(notification: NSNotification){
        self.mapView.camera = GMSCameraPosition(target: userLocation.coordinate, zoom: 17, bearing: 0, viewingAngle: 0)
        SelectedParkingData.removeAll()
        self.navigationbarAttributes(Hidden: true, Translucent: true)
        self.destinationTextField.isHidden = false
        self.mapView.clear()
        self.reloadInputViews()
    }
    
    @objc func loadMap(notification: NSNotification) {
        if !SelectedParkingData.isEmpty {
            destinationTextField.isEnabled = false
            destinationTextField.isHidden = true
            destinationLocation = CLLocation(latitude: SelectedParkingData[indexPath.row].Location.latitude, longitude: SelectedParkingData[indexPath.row].Location.longitude)
            if DirectionsData.isEmpty {
                self.getRouteSteps(source: self.userLocation.coordinate, destination: self.destinationLocation.coordinate)
            }
        }else{
            destinationTextField.isEnabled = true
            destinationTextField.isHidden = false
        }
    }
    
    @objc func showRouteInfo(){
        self.bulletinManagerShowInfo.allowsSwipeInteraction = false
        self.bulletinManagerShowInfo.showBulletin(above: self)
    }
    
    func updateDirectionsView(){
        print("USER NEAR STRUCTURE")
    }
    
    func addMarker(position: CLLocationCoordinate2D) {
        
//        let pulseAnimation = CABasicAnimation(keyPath: "opacity")
//        pulseAnimation.duration = 30
//        pulseAnimation.fromValue = 0
//        pulseAnimation.toValue = 1
//        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
//        pulseAnimation.autoreverses = true
//        pulseAnimation.repeatCount = .greatestFiniteMagnitude
//        self.view.layer.add(pulseAnimation, forKey: nil)
        let marker = GMSMarker()
        marker.position = position
        marker.map = mapView
        marker.appearAnimation = .pop
    }
    
    func drawPath(from polyStr: String){
        let path = GMSPath(fromEncodedPath: polyStr)
        let polyline = GMSPolyline(path: path)
        polyline.strokeColor = UIColor(red: 0.08, green: 0.43, blue: 0.88, alpha: 1.00)
        polyline.strokeWidth = 3.0
        polyline.map = mapView
//        self.mapView.camera = GMSCameraPosition(target: userLocation.coordinate, zoom: 16, bearing: 0, viewingAngle: 25)
    }
    
    func getRouteSteps(source: CLLocationCoordinate2D,destination: CLLocationCoordinate2D) {
        let url = URL(string: "https://maps.googleapis.com/maps/api/directions/json?origin=\(source.latitude),\(source.longitude)&destination=\(destination.latitude),\(destination.longitude)&sensor=false&mode=driving&key=\(APIKey)")!
        
        AF.request(url, method: .post).validate(statusCode: 200..<300).responseJSON { responseJSON in
            switch responseJSON.result {
                case .success(let json): //print(json)
                    let jsonResult = json as? [String: AnyObject]
                    
                    guard let routes = jsonResult!["routes"] as? [Any] else { return }
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
                   
//                        guard let maneuver = step["maneuver"] as? String else { return }
//                        print(maneuver)
                       
                        DispatchQueue.main.async {
                            self.drawPath(from: polyLineString)
                            DirectionsData.append(DirectionsInfo(Time: String(describing: stepTime["text"]! as Any), Distance: String(describing: stepDistance["text"]! as Any), Manuver: stepTurns.html2String))
                           
                            if DirectionsData.count > 0 {
                                self.navigationbarAttributes(Hidden: false, Translucent: false)
                                let directionTitle = SelectedParkingData[indexPath.row].Name
                                   //DirectionsData[indexPath.row].Manuver + " in " + DirectionsData[indexPath.row].Distance //DirectionsData[indexPath.row].Manuver
                                self.setupNavigationBar(LargeText: true, Title: directionTitle, SystemImageR: true, ImageR: true, ImageTitleR: "ellipsis", TargetR: self, ActionR: #selector(self.showRouteInfo), SystemImageL: false, ImageL: false, ImageTitleL: "", TargetL: self, ActionL: nil)
                                let DirectionsTitleAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: standardContrastColor, NSAttributedString.Key.font: UIFont(name: font, size: 28)!]
                                self.navigationController?.navigationBar.largeTitleTextAttributes = DirectionsTitleAttributes
                           }
                       }
                   }
                case .failure(let error): print(error)
            }
        }

        let cameraUpdate = GMSCameraUpdate.fit(GMSCoordinateBounds(coordinate: self.userLocation.coordinate, coordinate: self.destinationLocation.coordinate))
        self.mapView.moveCamera(cameraUpdate)
        let currentZoom = self.mapView.camera.zoom
        self.mapView.animate(toZoom: currentZoom - 0.8)
    }
}

extension HomeViewController {
    func styleMap(DarkMode: Bool) {
        mapView.settings.myLocationButton = true
        mapView.settings.rotateGestures = false
        var style = String()
        
        if DarkMode == true || userDefaults.bool(forKey: "THEME") == true {
            style = "darkstyle"
        }else{
            style = "lightstyle"
        }
        
        do{
            if let styleURL = Bundle.main.url(forResource: style, withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            }else{
                print("Unable to find style.json")
            }
        }catch{
            print("One or more of the map styles failed to load. \(error)")
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
