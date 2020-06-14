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
    
    func requestTotal(){
        functions.httpsCallable("getTotal").call(["UID": UserData[indexPath.row].UID]) { (result, error) in
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let message = error.localizedDescription
                    errorMessage = "\(message)"
                    print(errorMessage)
                }
            }
            
            guard let Amount = (result?.data as? [String: Any])?["Amount"] as? Double else { return }
            guard let DocumentID = (result?.data as? [String: Any])?["Document"] as? String else { return }
            
            database.collection("Users").document("Commuters").collection("Users").document(UserData[indexPath.row].UID).collection("History").document(DocumentID).getDocument { (document, error) in
                if let document = document, document.exists {
                    guard let Time = document.data()!["Duration"] as? [String: Firebase.Timestamp] else { return }

                    let StartTime = Date(timeIntervalSince1970: TimeInterval(Time["Begin"]!.seconds))
                    TransactionData.removeAll()
                    TransactionData.append(Payment(Current: true, Start: StartTime, Amount: Amount))
                    NotificationCenter.default.post(name: NSNotification.Name("finishProcessing"), object: nil)
                    print(TransactionData)
                } else {
                    print("Document does not exist")
                }
            }
            
        }
        
        
        
    }

}

