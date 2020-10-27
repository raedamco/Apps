//
//  Database Functions.swift
//  Theory Parking
//
//  Created by Omar on 6/21/20.
//  Copyright © 2020 Theory Parking. All rights reserved.
//

import Foundation
import Alamofire
import Firebase

var Database = DatabaseCalls()
//Append user input to vehicles array in their database document
class DatabaseCalls {
    var baseURLString: String? = "https://us-central1-theory-parking.cloudfunctions.net"
    var baseURL: URL {
        if let urlString = self.baseURLString, let url = URL(string: urlString) {
            return url
        } else {
            fatalError()
        }
    }
    
    func updateUserData(Data: [String:Any]) -> Bool{
        var Success = Bool()
        let url = self.baseURL.appendingPathComponent("updateAccount")
        AF.request(url, method: .post,parameters: Data).validate(statusCode: 200..<300).responseJSON { responseJSON in
            switch responseJSON.result {
                case .success(let json):
                    let responseJSON = json as? [String: AnyObject]
                    guard let Sucess = responseJSON?["Success"] as? Bool else { return }
                    
                    if Sucess {
                        Success = true
                    }else{
                        Success = false
                    }
                case .failure(let error): print(error.localizedDescription)
                    Success = false
            }
        }
        return Success
    }
    
    func addVehicleData(Vehicle: String) -> Bool{
        var Success = Bool()
        let url = self.baseURL.appendingPathComponent("addVehicleData")
        AF.request(url, method: .post,parameters: ["UID": UserData[indexPath.row].UID, "VehicleData": Vehicle]).validate(statusCode: 200..<300).responseJSON { responseJSON in
            switch responseJSON.result {
                case .success(let json):
                    let responseJSON = json as? [String: AnyObject]
                    guard let Sucess = responseJSON?["Success"] as? Bool else { return }
                    
                    if Sucess {
                        Success = true
                    }else{
                        Success = false
                    }
                case .failure(let error): print(error.localizedDescription)
                    Success = false
            }
        }
        return Success
    }
    
    func addPermitData(Permit: String, PermitNumber: String){
        let url = self.baseURL.appendingPathComponent("addPermitData")
        AF.request(url, method: .post,parameters: ["UID": UserData[indexPath.row].UID, "Permit": Permit, "PermitNumber": PermitNumber]).validate(statusCode: 200..<300).responseJSON { responseJSON in
            switch responseJSON.result {
                case .success(let json):
                    let responseJSON = json as? [String: AnyObject]
                    guard let Sucess = responseJSON?["Success"] as? Bool else { return }
                    
                    if Sucess {
                        
                    }
                case .failure(let error): print(error.localizedDescription)
                    
            }
        }
    }
    
}