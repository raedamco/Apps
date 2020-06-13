//
//  PaymentTimer.swift
//  Theory Parking
//
//  Created by Omar on 6/10/20.
//  Copyright © 2020 Theory Parking. All rights reserved.
//

import Foundation
import Firebase
import CoreLocation

var Server = ServerTimer()

class ServerTimer: NSObject {
    
    func requestTimer(){
        let requiredInfo: [String: Any] = ["UID":UserData[indexPath.row].UID,
                                           "Organization": SelectedParkingData[indexPath.row].Organization,
                                           "Floor": SelectedParkingData[indexPath.row].Floor,
                                           "Spot": SelectedParkingData[indexPath.row].Spot,
                                           "Latitude": SelectedParkingData[indexPath.row].Location.latitude,
                                           "Longitude": SelectedParkingData[indexPath.row].Location.longitude,
                                           "Rate": SelectedParkingData[indexPath.row].Price
                                          ]
        
        functions.httpsCallable("startPayment").call(requiredInfo) { (result, error) in
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let code = FunctionsErrorCode(rawValue: error.code)
                    let message = error.localizedDescription
                    let details = error.userInfo[FunctionsErrorDetailsKey]
                    print(code as Any, message as Any, details as Any)
                }
                //show BLTN as an error why timer could not start
            }
                
            if let success = (result?.data as? [String: Any])?["Status"] as? Bool {
                if success == true {
                    print("Server timer succesfully started")
                    NotificationCenter.default.post(name: NSNotification.Name("startPayment"), object: nil)
                }
            }
        }
    }
    
    func requestCharge(idempotencyKey: String){
        functions.httpsCallable("createCharge").call(["UID": UserData[indexPath.row].UID,"idempotencyKey": idempotencyKey]) { (result, error) in
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let message = error.localizedDescription
                    errorMessage = "\(message)"
                    print(errorMessage)
                }
            }
            
            guard let Completed = (result?.data as? [String: Any])?["Completed"] as? Bool else { return }
            
            if Completed {
               NotificationCenter.default.post(name: NSNotification.Name("endTransaction"), object: nil)
           }
        }
    }

}

