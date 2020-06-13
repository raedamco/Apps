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

var UserData = [User]()

func getUserData(Email: String){
    database.collection("Users").document("Commuters").collection("Users").whereField("Email", isEqualTo: Email).getDocuments { (snapshot, error) in
        if error != nil {
            try! Auth.auth().signOut()
            UserData.removeAll()
            TransactionsHistory.removeAll()
        }else{
            for document in (snapshot?.documents)! {
                guard let Name = document.data()["Name"] as? String else { return }
                guard let Email = document.data()["Email"] as? String else { return }
                guard let UID = document.data()["UUID"] as? String else { return }
                let License = document.data()["Vehicles"] as? [String] ?? [""]
                guard let Permit = document.data()["Permits"] as? [String:String] else { return }
                guard let StripeID = document.data()["StripeID"] as? String else { return }
                let Phone = document.data()["Phone"] as? String ?? ""
                
                UserData.append(User(Name: Name, Email: Email,Phone: Phone, UID: UID, License: License, Permit: Permit, StripeID: StripeID))
            }
            checkCurrentTransaction()
            getTransactionHistory()
        }
    }
    
}
