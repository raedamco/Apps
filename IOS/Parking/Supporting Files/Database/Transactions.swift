//
//  Transactions.swift
//  Parking
//
//  Created by Omar on 4/3/20.
//  Copyright © 2020 Theory Parking. All rights reserved.
//

import Foundation
import Firebase
import UIKit

var TransactionsData = [Transactions]()

func getTransactionHistory(){
    if UserData.isEmpty != true {
        database.collection("Users").document("Commuters").collection("Users").document(UserData[indexPath.row].UID).collection("History").order(by: "Duration.Start", descending: true).getDocuments { (snapshot, error) in
            if error != nil {
                print(error as Any)
            }else{
                for document in (snapshot?.documents)! {
                    guard let TID = document.data()["Transaction ID"] as? String else { return }
                    guard let Time = document.data()["Duration"] as? [String: Firebase.Timestamp] else { return }
                    guard let Info = document.data()["Data"] as? [String: Any] else { return }

                    let Day = Date(timeIntervalSince1970: TimeInterval(Time["End"]!.seconds))
                    let StartTime = Date(timeIntervalSince1970: TimeInterval(Time["Start"]!.seconds))
                    let EndTime = Date(timeIntervalSince1970: TimeInterval(Time["End"]!.seconds))
                    let form = DateComponentsFormatter()
                    form.unitsStyle = .abbreviated
                    let Duration = form.string(from: StartTime, to: EndTime)

                    let Organization = Info["Organization"] as! String
                    let Floor = Info["Floor"] as! String
                    let Spot = Info["Spot"] as! String
                    let Rate = Info["Rate"] as! NSNumber

                    TransactionsData.append(Transactions(Organization: Organization, Floor: Floor, Spot: Spot, TID: TID, Cost: Rate, Duration: Duration!, Day: Day))
                }
            }
        }
    }else{
        try! Auth.auth().signOut()
    }
    
    
}
