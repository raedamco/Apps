//
//  Server.swift
//  Theory Parking
//
//  Created by Omar on 6/21/20.
//  Copyright © 2020 Theory Parking. All rights reserved.
//

import Foundation
import Alamofire
import Firebase

var Server = ParkingServer()

class ParkingServer {
    var baseURLString: String? = "https://us-central1-theory-parking.cloudfunctions.net"
    var baseURL: URL {
        if let urlString = self.baseURLString, let url = URL(string: urlString) {
            return url
        } else {
            fatalError()
        }
    }
    
    func requestSpot(){
        let requiredInfo: [String: Any] = ["UID": UserData[indexPath.row].UID,
            "Latitude": ParkingData[indexPath.row].Location.latitude,
            "Longitude": ParkingData[indexPath.row].Location.longitude,
            "Organization": ParkingData[indexPath.row].Organization,
            "Name": ParkingData[indexPath.row].Name,
            // MARK: Add in selected filters, etc.
        ]
        
        let url = self.baseURL.appendingPathComponent("findParking")
        AF.request(url, method: .post,parameters: requiredInfo).validate(statusCode: 200..<300).responseJSON { responseJSON in
            switch responseJSON.result {
                case .success(let json):
                    let responseJSON = json as? [String: AnyObject]
                    guard let Location = responseJSON?["Location"] as? GeoPoint else { return }
                    guard let Name = responseJSON?["Name"] as? String else { return }
                    guard let Organization = responseJSON?["Organization"] as? String else { return }
                    guard let Type = responseJSON?["Types"] as? [String:Bool] else { return }
                    guard let Floor = responseJSON?["Floor"] as? String else { return }
                    guard let Spot = responseJSON?["Spot"] as? String else { return }
                    guard let Price = responseJSON?["Price"] as? NSNumber else { return }
                    guard let CompanyStripeID = responseJSON?["CompanyStripeID"] as? String else { return }
                    
                    SelectedParkingData.append(SelectedParking(Location: Location, Name: Name, Types: Type, Organization: Organization, Price: Price, Floor: Floor, Spot: Spot, CompanyStripeID: CompanyStripeID))
                case .failure(let error): print(error.localizedDescription)
                    //show buliten why it there was an issue
            }
        }
    }
    
    func cancelRequestSpot(){
        let requiredInfo: [String: Any] = ["UID": UserData[indexPath.row].UID,
            "Latitude": ParkingData[indexPath.row].Location.latitude,
            "Longitude": ParkingData[indexPath.row].Location.longitude,
            "Organization": ParkingData[indexPath.row].Organization,
            "Name": ParkingData[indexPath.row].Name,
//            "Spot": ParkingData[indexPath.row].Spot
            // MARK: Add in selected filters, etc.
        ]
        
        let url = self.baseURL.appendingPathComponent("cancelRequestParking")
        AF.request(url, method: .post,parameters: requiredInfo).validate(statusCode: 200..<300).responseJSON { responseJSON in
            switch responseJSON.result {
                case .success(let json):
                    let responseJSON = json as? [String: AnyObject]
                    guard let Success = responseJSON?["Success"] as? Bool else { return }
                    print(Success)
                case .failure(let error): print(error.localizedDescription)
                    //show buliten why it there was an issue
            }
        }
    }
}
