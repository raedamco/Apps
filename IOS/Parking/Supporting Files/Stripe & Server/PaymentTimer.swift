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
import BLTNBoard

var ServerTimer = ServerPayment()

class ServerPayment: NSObject {
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
                                           "StartLatitude": currentUserLocation.coordinate.latitude,
                                           "StartLongitude": currentUserLocation.coordinate.longitude,
                                           "Rate": SelectedParkingData[indexPath.row].Price,
                                           "CompanyStripeID": SelectedParkingData[indexPath.row].CompanyStripeID
                                          ]
        
        let url = self.baseURL.appendingPathComponent("startPayment")
        AF.request(url, method: .post,parameters: requiredInfo).validate(statusCode: 200..<300).responseJSON { responseJSON in
            switch responseJSON.result {
                case .success(let json):
                    let responseJSON = json as? [String: AnyObject]
                    guard let Success = responseJSON?["Status"] as? Bool else { return }
                    if Success == true {
                        NotificationCenter.default.post(name: NSNotification.Name("startPayment"), object: nil)
                        TransactionData.append(Payment(Current: true, Start: Date(), Amount: 0))
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
                        } else {
                            print("Document does not exist")
                        }
                    }
                case .failure(let error): print(error.localizedDescription)
            }
        }
    }
    

    func addVehicle() {
        let url = self.baseURL.appendingPathComponent("addVehicle")
        let requiredParameters: [String:Any] = ["UID": UserData[indexPath.row].UID]
        
        AF.request(url, method: .post,parameters: requiredParameters).validate(statusCode: 200..<300).responseJSON { responseJSON in
            switch responseJSON.result {
                case .success(let json):
                    let responseJSON = json as? [String: AnyObject]
                    guard let Status = responseJSON?["Status"] as? Bool else { return }
                    
                    if Status {
                        //Show user data was added animation
                    }
                case .failure(let error): print(error.localizedDescription)
            }
        }
    }
    
    func addPermit() {
        let url = self.baseURL.appendingPathComponent("addPermit")
        let requiredParameters: [String:Any] = ["UID": UserData[indexPath.row].UID]
        
        AF.request(url, method: .post,parameters: requiredParameters).validate(statusCode: 200..<300).responseJSON { responseJSON in
            switch responseJSON.result {
                case .success(let json):
                    let responseJSON = json as? [String: AnyObject]
                    guard let Status = responseJSON?["Status"] as? Bool else { return }
                    
                    if Status {
                        //Show user data was added animation
                    }
                case .failure(let error): print(error.localizedDescription)
            }
        }
    }

}

