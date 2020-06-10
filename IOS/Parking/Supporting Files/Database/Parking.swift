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

var ParkingData = [Parking]()
var SelectedParkingData = [SelectedParking]()
var NearByParking = [ParkingNearby]()

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

    database.collection("PSU").whereField("Location", isGreaterThan: swGeopoint).whereField("Location", isLessThan: neGeopoint).getDocuments { snapshot, error in
        if let error = error {
            print("Error getting documents: \(error)")
        }else{
            for document in snapshot!.documents {
                if document.exists {
                    let organization = "Portland State University"
                    let price = document.data()["Pricing"] as! [String: NSNumber]
                    let rate = price["Minute"]!
                    let name = document.data()["Name"] as! String
                    let types = document.data()["Spot Types"] as! [String: Bool]
                    let location = document.data()["Location"] as! GeoPoint
                    let currentInfo = document.data()["Capacity"] as! [String: NSNumber]
                    let available = currentInfo["Available"]!
                    let capacity = currentInfo["Capacity"]!
                    
                    ParkingData.append(Parking(Location: location, Name: name, Types: types, Organization: organization, Prices: rate, Capacity: capacity, Available: available, Floors: [], Spots: []))
                }
            }
            
            if ParkingData.isEmpty == false {
                getStructureData()
            }
            
            NotificationCenter.default.post(name: NSNotification.Name("reloadResultTable"), object: nil)
        }
    }
}

func getStructureData(){
    database.collection("PSU").document("Parking Structure 1").collection("Floor 2").getDocuments { snapshot, error in
        if let error = error {
            print("Error getting documents: \(error)")
        }else{
            for document in snapshot!.documents {
                if document.exists {
                    let info = document.data()["Info"] as! [String: Any]
                    let occupancy = document.data()["Occupancy"] as! [String: Any]
                    //let type = document.data()["Pricing"] as! [String: Any]

                    let spotID = info["Spot ID"] as! NSNumber
                    let occupied = occupancy["Occupied"] as! Bool

                    if occupied == false {
                        ParkingData[indexPath.row].Spots.append(String(describing: spotID))
                    }
                    ParkingData[indexPath.row].Floors.append(String(describing: "2"))
                }
            }
            ParkingDataUpdates()
            ParkingData[indexPath.row].Spots.sort {$0.localizedStandardCompare($1) == .orderedAscending}
        }
    }
}


func retrieveNearByParking(latitude: Double, longitude: Double, meters: Double) {
    let r_earth : Double = 6378137

    let kLat = (2 * Double.pi / 360) * r_earth
    let kLon = (2 * Double.pi / 360) * r_earth * __cospi(latitude/180.0)

    let deltaLat = meters / kLat
    let deltaLon = meters / kLon

    let swGeopoint = GeoPoint(latitude: latitude - deltaLat, longitude: longitude - deltaLon)
    let neGeopoint = GeoPoint(latitude: latitude + deltaLat, longitude: longitude + deltaLon)

    database.collection("PSU").whereField("Location", isGreaterThan: swGeopoint).whereField("Location", isLessThan: neGeopoint).getDocuments { snapshot, error in
        if let error = error {
            print("Error getting documents: \(error)")
        }else{
            for document in snapshot!.documents {
                if document.exists {
                    let organization = "Portland State University"
                    let price = document.data()["Pricing"] as! [String: NSNumber]
                    let rate = price["Minute"]!
                    let name = document.data()["Name"] as! String
                    let types = document.data()["Spot Types"] as! [String: Bool]
                    let location = document.data()["Location"] as! GeoPoint
                    let currentInfo = document.data()["Capacity"] as! [String: NSNumber]
                    let available = currentInfo["Available"]!
                    let capacity = currentInfo["Capacity"]!
                    let Floor = "Floor 2"
                    let spot = "Spot 2"
                    
                    NearByParking.append(ParkingNearby(Location: location, Name: name, Types: types, Organization: organization, Prices: rate, Capacity: capacity, Available: available, Floor: Floor, Spot: spot))
                }
            }
            NotificationCenter.default.post(name: NSNotification.Name("checkIn"), object: nil)
//            Server.requestTimer()
        }
    }
}


func ParkingDataUpdates(){
    database.collection("PSU").document("Parking Structure 1").collection("Floor 2").addSnapshotListener { querySnapshot, error in
        guard let snapshot = querySnapshot else {
            print("Error fetching snapshots: \(error!)")
            return
        }
        
        snapshot.documentChanges.forEach { diff in
            if (diff.type == .added) {
                let info = diff.document.data()["Info"] as! [String: Any]
                let occupancy = diff.document.data()["Occupancy"] as! [String: Any]
                let spotID = info["Spot ID"] as! NSNumber
                let occupied = occupancy["Occupied"] as! Bool
                
                if occupied == false {
                    ParkingData[indexPath.row].Spots.append(String(describing: spotID))
                }
            }
            
            if (diff.type == .modified) {
                let occupancy = diff.document.data()["Occupancy"] as! [String: Any]
                let occupied = occupancy["Occupied"] as! Bool
                let info = diff.document.data()["Info"] as! [String: Any]
                let spotID = info["Spot ID"] as! NSNumber
                
                if (ParkingData.isEmpty == false && ParkingData[indexPath.row].Spots.contains(diff.document.documentID) && occupied == true) {
                    if let index = ParkingData[indexPath.row].Spots.firstIndex(of: diff.document.documentID) {
                        ParkingData[indexPath.row].Spots.remove(at: index)
                    }
                }else if (ParkingData.isEmpty == false && ParkingData[indexPath.row].Spots.contains(diff.document.documentID) == false && occupied == false){
                    ParkingData[indexPath.row].Spots.append(String(describing: spotID))
                }else if (SelectedParkingData.isEmpty == false && SelectedParkingData[indexPath.row].Spot.contains(diff.document.documentID) && occupied == true){
                    print("PARKING TAKEN")
                }
                NotificationCenter.default.post(name: NSNotification.Name("reloadResultTable"), object: nil)
            }
            
            if (diff.type == .removed) {
                print("Removed: \(diff.document.data())")
            }
        }
        
        if ParkingData.isEmpty == false {
            ParkingData[indexPath.row].Floors.append(String(describing: "2"))
            ParkingData[indexPath.row].Spots.sort {$0.localizedStandardCompare($1) == .orderedAscending}
        }
    }
}
