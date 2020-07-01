//
//  HomeViewController.swift
//  Parking
//
//  Created for Theory Parking on 9/8/19.
//  Copyright © 2020 Theory Parking. All rights reserved.
//

import UIKit
import MapKit
//import GoogleMaps
//import GooglePlaces
import Alamofire
import SwiftyJSON
import BLTNBoard
import AVFoundation
import DropDown
import CoreLocation

var selectedParkingLocation = CLLocation()

class HomeViewController: UIViewController, CLLocationManagerDelegate, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate, MKLocalSearchCompleterDelegate {
   
    func updateSearchResults(for searchController: UISearchController) {
//        getDirections(to: <#T##MKMapItem#>)
    }
    
    var autoCompleteData = [String]()
    var dropButton = DropDown()
    var searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()
    
    private let locationManager = CLLocationManager()
    let mapView = MKMapView()
    var userLocation = CLLocation()
    var destinationLocation = CLLocation()
    var steps = [MKRoute.Step]()
    let speechSynthesizer = AVSpeechSynthesizer()
    var currentDirections = String()
    var stepCounter = 0
    let search = UISearchController(searchResultsController: nil)
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
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.startUpdatingLocation()
        mapSettings()
        mapView.setRegion(MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: 200, longitudinalMeters: 200), animated: true)
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
        view = mapView
        createSearchBar()
        
        searchCompleter.delegate = self
        
        dropButton.anchorView = search.searchBar
        dropButton.bottomOffset = CGPoint(x: 0, y:(dropButton.anchorView?.plainView.bounds.height)!)
        dropButton.backgroundColor = standardBackgroundColor.withAlphaComponent(0.7)
        dropButton.textColor = standardContrastColor
        dropButton.direction = .bottom

        dropButton.selectionAction = { [unowned self] (index: Int, item: String) in
            print("Selected item: \(item) at index: \(index)") //Selected item: code at index: 0
            
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(item) {
                placemarks, error in
                
                let localSearchRequest = MKLocalSearch.Request()
                localSearchRequest.naturalLanguageQuery = item
                let region = MKCoordinateRegion(center: self.userLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
                localSearchRequest.region = region
                let localSearch = MKLocalSearch(request: localSearchRequest)
                localSearch.start { (response, _) in
                    guard let response = response else { return }
                    guard let firstMapItem = response.mapItems.first else { return }
                    
                    destinationName = item
                    SelectedParkingData.removeAll()
                    getDocumentNearBy(latitude: firstMapItem.placemark.coordinate.latitude, longitude: firstMapItem.placemark.coordinate.longitude, meters: 1000)
                    showView(self: self, ViewController: ResultView())
                    
//                    self.getDirections(destination: firstMapItem)
//                    self.navigationItem.searchController!.searchBar.placeholder = item
//                    self.navigationItem.searchController!.searchBar.resignFirstResponder()
                }
            }
        }
        
        
        
        
    
            if DirectionsData.count > 0 {
//                let directionTitle = SelectedParkingData[indexPath.row].Name
//                    //DirectionsData[indexPath.row].Manuver
//
//                self.setupNavigationBar(LargeText: true, Title: directionTitle, SystemImageR: true, ImageR: true, ImageTitleR: "ellipsis", TargetR: self, ActionR: #selector(self.showRouteInfo), SystemImageL: false, ImageL: false, ImageTitleL: "", TargetL: self, ActionL: nil)
//                let DirectionsTitleAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: standardContrastColor, NSAttributedString.Key.font: UIFont(name: font, size: 28)!]
//                self.navigationController?.navigationBar.largeTitleTextAttributes = DirectionsTitleAttributes
//                let DirectionsTitleAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: standardContrastColor, NSAttributedString.Key.font: UIFont(name: font, size: 20)!]
//                self.navigationController?.navigationBar.largeTitleTextAttributes = DirectionsTitleAttributes
            }

    }
    
    func createSearchBar(){
        self.navigationController?.navigationBar.isTranslucent = true
        search.searchResultsUpdater = self
        search.searchBar.placeholder = "Destination"
        search.searchBar.barTintColor = standardBackgroundColor.withAlphaComponent(0.7)
        search.searchBar.tintColor = standardContrastColor
        search.searchBar.delegate = self
        search.delegate = self
        self.navigationItem.searchController = search
        self.view.layoutSubviews()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchCompleter.queryFragment = (self.navigationItem.searchController?.searchBar.text)!
        let searchBar = self.navigationItem.searchController!.searchBar
        if searchBar.text?.isEmpty == true {
            autoCompleteData.removeAll()
        }
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        let searchBar = self.navigationItem.searchController!.searchBar
        searchBar.setShowsCancelButton(true, animated: true)
        for ob: UIView in ((searchBar.subviews[0])).subviews {
            if let z = ob as? UIButton {
                let btn: UIButton = z
                btn.setTitleColor(UIColor.white, for: .normal)
            }
        }
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        let searchBar = self.navigationItem.searchController!.searchBar
        searchBar.showsCancelButton = false
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        let searchBar = self.navigationItem.searchController!.searchBar
        searchBar.resignFirstResponder()
        searchBar.text = ""
        dropButton.hide()
    }

}

extension HomeViewController {

    @objc func createRoute(notification: NSNotification){
        destinationLocation = CLLocation(latitude: SelectedParkingData[indexPath.row].Location.latitude, longitude: SelectedParkingData[indexPath.row].Location.longitude)
        self.getDirections(destination: MKMapItem(placemark: MKPlacemark(coordinate: self.destinationLocation.coordinate)))
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
        self.getDirections(destination: MKMapItem(placemark: MKPlacemark(coordinate: destinationLocation.coordinate)))
    }

    @objc func cancelRoute(notification: NSNotification){
        SelectedParkingData.removeAll()
        self.setupNavigationBar(LargeText: true, Title: "", SystemImageR: true, ImageR: false, ImageTitleR: "", TargetR: self, ActionR: nil, SystemImageL: false, ImageL: false, ImageTitleL: "", TargetL: self, ActionL: nil)
        let annotationsToRemove = mapView.annotations.filter { $0 !== mapView.userLocation }
        mapView.removeAnnotations(annotationsToRemove)
        self.reloadInputViews()
    }
    
    @objc func showRouteInfo(){
        self.bulletinManagerShowInfo.allowsSwipeInteraction = false
        self.bulletinManagerShowInfo.showBulletin(above: self)
    }
    
    func updateDirectionsView(){
        print("USER NEAR STRUCTURE")
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        
        if !autoCompleteData.contains(searchResults[indexPath.row].title){
            autoCompleteData.append(searchResults[indexPath.row].title)
        }
        
        dropButton.dataSource = autoCompleteData
        dropButton.show()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // handle error
    }
}


//Map & user permissions
extension HomeViewController {

    func mapSettings(){
        mapView.isZoomEnabled = true
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        mapView.isScrollEnabled = true
        mapView.showsTraffic = true
        mapView.showsUserLocation = true
        mapView.showsBuildings = true
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        guard let currentLocation = locations.first else { return }
        userLocation = currentLocation
        mapView.userTrackingMode = .followWithHeading
        
        if currentLocation.distance(from: destinationLocation) <= blockDistance {
            updateDirectionsView()
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("ENTERED")
        stepCounter += 1
        if stepCounter < steps.count {
            let currentStep = steps[stepCounter]
            let message = "In \(currentStep.distance) meters, \(currentStep.instructions)"
//            directionsLabel.text = message
            let speechUtterance = AVSpeechUtterance(string: message)
            speechSynthesizer.speak(speechUtterance)
        } else {
            let message = "Arrived at destination"
//            directionsLabel.text = message
            let speechUtterance = AVSpeechUtterance(string: message)
            speechSynthesizer.speak(speechUtterance)
            stepCounter = 0
            locationManager.monitoredRegions.forEach({ self.locationManager.stopMonitoring(for: $0) })
        }
    }
}

extension HomeViewController: MKMapViewDelegate {
    func getDirections(destination: MKMapItem) {
        let sourceMapItem = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
        
        let directionsRequest = MKDirections.Request()
        directionsRequest.source = sourceMapItem
        directionsRequest.destination = destination
        directionsRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionsRequest)
        directions.calculate { (response, _) in
            guard let response = response else { return }
            guard let primaryRoute = response.routes.first else { return }
            
            self.mapView.addOverlay(primaryRoute.polyline)
            self.locationManager.monitoredRegions.forEach({ self.locationManager.stopMonitoring(for: $0) })
            
            self.steps = primaryRoute.steps
            RouteData.append(RouteInfo(Time: String(describing: primaryRoute.expectedTravelTime.asString(style: .abbreviated)), Distance: convertToMiles(Value: primaryRoute.distance)))
            
            for i in 0 ..< primaryRoute.steps.count {
                let step = primaryRoute.steps[i]

                let region = CLCircularRegion(center: step.polyline.coordinate, radius: 20, identifier: "\(i)")
                self.locationManager.startMonitoring(for: region)
                let circle = MKCircle(center: region.center, radius: region.radius)
                self.mapView.addOverlay(circle)
                
                DirectionsData.append(DirectionsInfo(Time: "temp", Distance: convertToMiles(Value: step.distance), Manuver: String(describing: step.instructions)))
            }
            
            let initialMessage = "In \(convertToMiles(Value: self.steps[0].distance)), \(self.steps[0].instructions) then in \(convertToMiles(Value: self.steps[1].distance)), \(self.steps[1].instructions)."
            self.currentDirections = initialMessage
//            print(initialMessage)
//            self.directionsLabel.text = initialMessage
//            let speechUtterance = AVSpeechUtterance(string: initialMessage)
//            self.speechSynthesizer.speak(speechUtterance)
            self.stepCounter += 1
//
        }
//
        if DirectionsData.count > 0 {
             let directionTitle = currentDirections

             self.setupNavigationBar(LargeText: true, Title: directionTitle, SystemImageR: true, ImageR: true, ImageTitleR: "ellipsis", TargetR: self, ActionR: #selector(self.showRouteInfo), SystemImageL: false, ImageL: false, ImageTitleL: "", TargetL: self, ActionL: nil)
//
//             let DirectionsTitleAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: standardContrastColor, NSAttributedString.Key.font: UIFont(name: font, size: 18)!]
//             self.navigationController?.navigationBar.largeTitleTextAttributes = DirectionsTitleAttributes
//             self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
//             self.navigationController?.navigationBar.shadowImage = UIImage()
//             self.navigationController?.navigationBar.isTranslucent = false
//             self.navigationController?.view.backgroundColor = standardBackgroundColor.withAlphaComponent(0.7)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .blue
            renderer.lineWidth = 10
            return renderer
        }
        
        if overlay is MKCircle {
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.strokeColor = .red
            renderer.fillColor = .red
            renderer.alpha = 0.5
            return renderer
        }
        return MKOverlayRenderer()
    }
}
