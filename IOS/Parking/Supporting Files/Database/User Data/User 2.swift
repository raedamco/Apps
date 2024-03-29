//
//  User.swift
//  Parking
//
//  Created by Omar on 4/3/20.
//  Copyright © 2020 Theory Parking. All rights reserved.
//

import Foundation
import Firebase
import UIKit
import Alamofire

var UserData = [User]()

////Get user data from database
func getUserData(UID: String, completion: @escaping (_ success: Bool) -> Void) {
    database.collection("Users").document("Commuters").collection("Users").document(UID).getDocument { (document, error) in
        if let document = document, document.exists {
            let data = document.data()!
            let Name = data["Name"] as? String
            let Email = data["Email"] as? String
            let UID = data["UUID"] as? String
            var License = data["Vehicles"] as! [String]
            var Permit = data["Permits"] as? [String:String]
            let StripeID = data["StripeID"] as? String ?? ""
            let Phone = data["Phone"] as? String ?? ""
            
            if License.isEmpty {
                License = ["None"]
            }
            
            if Permit!.isEmpty {
                Permit = ["None":" "]
            }

            UserData.append(User(Name: Name, Email: Email, Phone: Phone, UID: UID, License: License, Permit: Permit!, StripeID: StripeID))
            checkCurrentTransaction()
            getTransactionHistory()
            
            completion(true)
        } else {
            try! Auth.auth().signOut()
            UserData.removeAll()
            TransactionsHistory.removeAll()
            completion(false)
        }
    }
 }
