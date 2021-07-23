//
//
//     override func viewWillAppear(_ animated: Bool) {
//
//
//  if destinationTextField.isHidden {
//            navigationbarAttributes(Hidden: false, Translucent: false)
//
//            if DirectionsData.count > 0 {
//                let directionTitle = SelectedParkingData[indexPath.row].Name
//                    //DirectionsData[indexPath.row].Manuver
//
//                self.setupNavigationBar(LargeText: true, Title: directionTitle, SystemImageR: true, ImageR: true, ImageTitleR: "ellipsis", TargetR: self, ActionR: #selector(self.showRouteInfo), SystemImageL: false, ImageL: false, ImageTitleL: "", TargetL: self, ActionL: nil)
//                let DirectionsTitleAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: standardContrastColor, NSAttributedString.Key.font: UIFont(name: font, size: 28)!]
//                self.navigationController?.navigationBar.largeTitleTextAttributes = DirectionsTitleAttributes
//            }
//        }else{
//            navigationbarAttributes(Hidden: true, Translucent: false)
//            destinationTextField.isEnabled = true
//        }
//     }
//
//}
//
//
//    @objc func createRoute(notification: NSNotification){
//        destinationLocation = CLLocation(latitude: SelectedParkingData[indexPath.row].Location.latitude, longitude: SelectedParkingData[indexPath.row].Location.longitude)
//
//        let destinationLocation2D = CLLocationCoordinate2D(latitude: SelectedParkingData[indexPath.row].Location.latitude, longitude: SelectedParkingData[indexPath.row].Location.longitude)
//
//        dismiss(animated: true, completion: {
//            self.mapView.settings.compassButton = true
//            self.mapView.settings.myLocationButton = true
//            self.addMarker(position: destinationLocation2D)
//            self.getRouteSteps(source: self.userLocation.coordinate, destination: self.destinationLocation.coordinate)
//
//        })
//    }
//
//    @objc func startRoute(notification: NSNotification){
//        destinationLocation = CLLocation(latitude: SelectedParkingData[indexPath.row].Location.latitude, longitude: SelectedParkingData[indexPath.row].Location.longitude)
//
//        let destinationLocation2D = CLLocationCoordinate2D(latitude:  SelectedParkingData[indexPath.row].Location.latitude, longitude: SelectedParkingData[indexPath.row].Location.longitude)
//
//        dismiss(animated: true, completion: {
//            self.addMarker(position: destinationLocation2D)
//            self.getRouteSteps(source: self.userLocation.coordinate, destination: self.destinationLocation.coordinate)
//            self.destinationTextField.isHidden = true
//        })
//    }
//
//    @objc func cancelRoute(notification: NSNotification){
//        self.mapView.camera = GMSCameraPosition(target: userLocation.coordinate, zoom: 17, bearing: 0, viewingAngle: 0)
//        SelectedParkingData.removeAll()
//        self.navigationbarAttributes(Hidden: true, Translucent: true)
//        self.destinationTextField.isHidden = false
//        self.mapView.clear()
//        self.reloadInputViews()
//    }
//
//    @objc func loadMap(notification: NSNotification) {
//        if !SelectedParkingData.isEmpty {
//            destinationTextField.isEnabled = false
//            destinationTextField.isHidden = true
//            destinationLocation = CLLocation(latitude: SelectedParkingData[indexPath.row].Location.latitude, longitude: SelectedParkingData[indexPath.row].Location.longitude)
//            if DirectionsData.isEmpty {
//                self.getRouteSteps(source: self.userLocation.coordinate, destination: self.destinationLocation.coordinate)
//            }
//        }else{
//            destinationTextField.isEnabled = true
//            destinationTextField.isHidden = false
//        }
//    }
//
