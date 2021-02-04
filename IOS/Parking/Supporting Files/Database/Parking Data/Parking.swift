//
//  Parking Data.swift
//  Parking
//
//  Created by Omar on 4/3/20.
//  Copyright © 2020 Theory Parking. All rights reserved.
//

import Foundation
import Firebase
import UIKit
import CoreLocation

var ParkingData = [Parking]()
var SelectedParkingData = [SelectedParking]()

var RouteData = [RouteInfo]()
var DirectionsData = [DirectionsInfo]()



func getDocumentNearBy(latitude: Double, longitude: Double, meters: Double) {
    let r_earth : Double = 6378137

    let kLat = (2 * Double.pi / 360) * r_earth
    let kLon = (2 * Double.pi / 360) * r_earth * __cospi(latitude/180.0)

    let deltaLat = meters / kLat
    let deltaLon = meters / kLon

    let swGeopoint = GeoPoint(latitude: latitude - deltaLat, longitude: longitude - deltaLon)
    let neGeopoint = GeoPoint(latitude: latitude + deltaLat, longitude: longitude + deltaLon)

    var locationsArray = [String]()
    
    database.collection("Companies").getDocuments { (snapshot, error) in
        if let error = error {
            print("Error getting documents: \(error)")
        }else{
            for document in snapshot!.documents {
                if document.exists{
                    locationsArray.append(document.documentID)
                }
            }
            
            for location in locationsArray {
                getParkingLocations(location1: location, swGeopoint: swGeopoint, neGeopoint: neGeopoint, latitude: latitude, longitude: longitude)
            }
        }
        locationsArray.removeAll()
    }
}

func getParkingLocations(location1: String, swGeopoint: GeoPoint, neGeopoint: GeoPoint, latitude: Double, longitude: Double){
    database.collection("Companies").document(location1).collection("Data").whereField("Location", isGreaterThan: swGeopoint).whereField("Location", isLessThan: neGeopoint).getDocuments { snapshot, error in
        if let error = error {
            print("Error getting documents: \(error)")
        }else{
            for document in snapshot!.documents {
                if document.exists {
                    var floors = [String]()
                    var spots = [String]()
                    let organization = document.data()["Organization"] as! String
                    let price = document.data()["Pricing"] as! [String: Any]
                    let rate = price["Minute"]! as! NSNumber
                    let name = document.data()["Name"] as! String
                    let types = document.data()["Spot Types"] as! [String: Bool]
                    let location = document.data()["Location"] as! GeoPoint
                    let currentInfo = document.data()["Capacity"] as! [String: NSNumber]
                    let available = currentInfo["Available"]!
                    let capacity = currentInfo["Capacity"]!
                    let CompanyStripeID = document.data()["CompanyStripeID"] as! String
                    let floorDataMap = document.data()["Floor Data"] as! [String: Any]

                    for floor in floorDataMap.keys {
                        floors.append(floor)
                    }
                    
                    for floor in floors {
                        let floorData = floorDataMap[floor] as! [String: Any]
                        let unoccupiedSpots = floorData["Unoccupied"] as! [NSNumber]
                        spots.append(contentsOf: unoccupiedSpots.map {$0.stringValue})
                    }
                    
                    let distance = String(describing: convertToMiles(Value: CLLocation(latitude: location.latitude, longitude: location.longitude).distance(from: CLLocation(latitude: latitude, longitude: longitude)))) + " from destination"
                    
                    ParkingData.append(Parking(Location: location, Distance: distance, Name: name, Types: types, Organization: organization, Prices: rate, Capacity: capacity, Available: available, Floors: floors, Spots: spots, CompanyStripeID: CompanyStripeID))
                }
                NotificationCenter.default.post(name: NSNotification.Name("reloadResultTable"), object: nil)
            }
        }
    }
}

// MARK: FIX REALTIME UPDATES. IF SPOT IS TAKEN & USER IS BEING DIRECTED THERE, FIND THEM THE NEXT AVAILABLE SPOT
//func ParkingDataUpdates(location: String){
//    database.collection("Companies").document(location).collection("Data").addSnapshotListener { querySnapshot, error in
//        guard let snapshot = querySnapshot else {
//            print("Error fetching snapshots: \(error!)")
//            return
//        }
//
//        snapshot.documentChanges.forEach { diff in
//            if (diff.type == .modified) {
//                guard let floorDataMap = diff.document.data()["Floor Data"] as? [String: Any] else { return }
//            }
//        }
//    }
//}
