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
                getParkingLocations(location: location, swGeopoint: swGeopoint, neGeopoint: neGeopoint, latitude: latitude, longitude: longitude)
            }
        }
    }
}

func getParkingLocations(location: String, swGeopoint: GeoPoint, neGeopoint: GeoPoint, latitude: Double, longitude: Double){
    database.collection("Companies").document(location).collection("Data").whereField("Location", isGreaterThan: swGeopoint).whereField("Location", isLessThan: neGeopoint).getDocuments { snapshot, error in
        if let error = error {
            print("Error getting documents: \(error)")
        }else{
            for document in snapshot!.documents {
                if document.exists {
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
                    
                    let distance = String(describing: convertToMiles(Value: CLLocation(latitude: location.latitude, longitude: location.longitude).distance(from: CLLocation(latitude: latitude, longitude: longitude)))) + " from destination"
                    
                    ParkingData.append(Parking(Location: location, Distance: distance, Name: name, Types: types, Organization: organization, Prices: rate, Capacity: capacity, Available: available, Floors: [], Spots: [], CompanyStripeID: CompanyStripeID))
                }
                
                if ParkingData.isEmpty == false {
                    getLocationData(location: location, facility: document.documentID)
                }
            }
            NotificationCenter.default.post(name: NSNotification.Name("reloadResultTable"), object: nil)
        }
    }
}

func getLocationData(location: String, facility: String){
    database.collection("Companies").document(location).collection("Data").document(facility).getDocument { (document, error) in
        if let document = document, document.exists {
            let spotStatus = document.data()?["Spot Status"] as! [String: Any]
            let unoccupiedSpots = spotStatus["Unoccupied"] as! [NSNumber]
            
            if !unoccupiedSpots.isEmpty {
                ParkingData[indexPath.row].Spots.sort {$0.localizedStandardCompare($1) == .orderedAscending}
                ParkingData[indexPath.row].Spots.append(String(describing: unoccupiedSpots.first!.stringValue))
                ParkingData[indexPath.row].Floors.append(String(describing: "2"))
            }else{
                //all spots are occupied
            }
        }
    }
}

func ParkingDataUpdates(){
    database.collection("Companies").document("Portland State University").collection("Data").document("Parking Structure 1").collection("Floor 2").addSnapshotListener { querySnapshot, error in
        guard let snapshot = querySnapshot else {
            print("Error fetching snapshots: \(error!)")
            return
        }

        snapshot.documentChanges.forEach { diff in
            if (diff.type == .modified) {
                guard let occupancy = diff.document.data()["Occupancy"] as? [String: Any] else { return }
                guard let occupied = occupancy["Occupied"] as? Bool else { return }
                guard let info = diff.document.data()["Info"] as? [String: Any] else { return }
                guard let spotID = info["Spot ID"] as? NSNumber else { return }

                if !ParkingData.isEmpty {
                    if (ParkingData[indexPath.row].Spots.contains(diff.document.documentID) && occupied) {
                        if let index = ParkingData[indexPath.row].Spots.firstIndex(of: diff.document.documentID) {
                            ParkingData[indexPath.row].Spots.remove(at: index)

                        }
                    }else if (ParkingData[indexPath.row].Spots.contains(diff.document.documentID) == false && !occupied){
                        ParkingData[indexPath.row].Spots.append(String(describing: spotID))

                    }else if (SelectedParkingData[indexPath.row].Spot.contains(diff.document.documentID) && occupied == true){
                        print("PARKING TAKEN")
                        //direct them to next available spot
                    }
                    NotificationCenter.default.post(name: NSNotification.Name("reloadResultTable"), object: nil)
                }
            }
        }

        if !ParkingData.isEmpty {
            ParkingData[indexPath.row].Floors.append(String(describing: "2"))
            ParkingData[indexPath.row].Spots.sort {$0.localizedStandardCompare($1) == .orderedAscending}
        }
    }
}

func ParkingDataUpdates1(location: String){
    database.collection("Companies").document(location).collection("Data").addSnapshotListener { querySnapshot, error in
        guard let snapshot = querySnapshot else {
            print("Error fetching snapshots: \(error!)")
            return
        }
        
        snapshot.documentChanges.forEach { diff in
            if (diff.type == .modified) {
                guard let spotStatus = diff.document.data()["Spot Status"] as? [String: Any] else { return }
                guard let occupiedSpots = spotStatus["Occupied"] as? [NSNumber] else { return }
                guard let unoccupiedSpots = spotStatus["Unoccupied"] as? [NSNumber] else { return }
                
                
                print("occupied spots", occupiedSpots)
                print("unoccupied spots", unoccupiedSpots)
            }
        }
        
        if !ParkingData.isEmpty {
            ParkingData[indexPath.row].Floors.append(String(describing: "2"))
            ParkingData[indexPath.row].Spots.sort {$0.localizedStandardCompare($1) == .orderedAscending}
        }
    }
}
