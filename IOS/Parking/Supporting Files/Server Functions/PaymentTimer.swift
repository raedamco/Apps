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
import Alamofire

var Server = ServerTimer()

class ServerTimer: NSObject {
    var baseURLString: String? = "https://us-central1-theory-parking.cloudfunctions.net"
    var baseURL: URL {
        if let urlString = self.baseURLString, let url = URL(string: urlString) {
            return url
        } else {
            fatalError()
        }
    }
    
    
    func requestTimer(){
        let requiredInfo: [String: Any] = ["UID":UserData[indexPath.row].UID,
                                           "Organization": SelectedParkingData[indexPath.row].Organization,
                                           "Floor": SelectedParkingData[indexPath.row].Floor,
                                           "Spot": SelectedParkingData[indexPath.row].Spot,
                                           "Latitude": SelectedParkingData[indexPath.row].Location.latitude,
                                           "Longitude": SelectedParkingData[indexPath.row].Location.longitude,
                                           "Rate": SelectedParkingData[indexPath.row].Price
                                          ]
        
        let url = self.baseURL.appendingPathComponent("startPayment")
        AF.request(url, method: .post,parameters: requiredInfo).validate(statusCode: 200..<300).responseJSON { responseJSON in
            switch responseJSON.result {
                case .success(let json):
                    let responseJSON = json as? [String: AnyObject]
                    guard let Success = responseJSON?["Status"] as? Bool else { return }

                    if Success == true {
                        print("Server timer succesfully started")
                        NotificationCenter.default.post(name: NSNotification.Name("startPayment"), object: nil)
                    }
                case .failure(let error): print(error.localizedDescription)
            }
        }
    }

    func requestTotal() {
        let url = self.baseURL.appendingPathComponent("getTotal")
        AF.request(url, method: .post,parameters: ["UID": UserData[indexPath.row].UID]).validate(statusCode: 200..<300).responseJSON { responseJSON in
            switch responseJSON.result {
                case .success(let json):
                    let responseJSON = json as? [String: AnyObject]
                    guard let Amount = responseJSON?["Amount"] as? Double else { return }
                    guard let DocumentID = responseJSON?["Document"] as? String else { return }
                
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
                case .failure(let error): print(error.localizedDescription)
            }
        }
    }

}

