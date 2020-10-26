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

var TransactionsHistory = [Transactions]()
var TransactionData = [Payment]()
var FinalTransactionAmount = [FinalPayment]()

func getTransactionHistory(){
    database.collection("Users").document("Commuters").collection("Users").document(UserData[indexPath.row].UID).collection("History").order(by: "Duration.Begin", descending: true).getDocuments { (snapshot, error) in
        if error != nil {
            print(error as Any)
        }else{
            for document in (snapshot?.documents)! {
                guard let isTransactionCurrent = document.data()["Current"] as? Bool else { return }
                
                //Discard current transactions for transaction history log
                if !isTransactionCurrent {
                    //Transaction Details
                    guard let TransactionData = document.data()["Transaction"] as? [String: Any] else { return }
                    guard let TID = TransactionData["TransactionID"] as? String else { return }
                    guard let Amount = TransactionData["Amount"] as? NSNumber else { return }
                    
                    //Location & Organization Info
                    guard let Info = document.data()["Data"] as? [String: Any] else { return }
                    guard let Floor = Info["Floor"] as? String else { return }
                    guard let Organization = Info["Organization"] as? String else { return }
                    guard let Spot = Info["Spot"] as? String else { return }
                    guard let Rate = Info["Rate"] as? NSNumber else { return }
                    
                    //Date & Time info
                    guard let Time = document.data()["Duration"] as? [String: Any] else { return }
                    guard let Duration = Time["Minutes"] as? NSNumber else { return }
                    guard let EndDay = Time["End"] as? Firebase.Timestamp else { return }
                    TransactionsHistory.append(Transactions(Organization: Organization, Floor: Floor, Spot: Spot, TID: TID, Rate: Rate, Cost: Amount, Duration: Duration, Day: EndDay.dateValue()))
                }
            }
        }
    }
    
    database.collection("Users").document("Commuters").collection("Users").document(UserData[indexPath.row].UID).collection("History").order(by: "Duration.Begin", descending: true).limit(to: 1).addSnapshotListener { querySnapshot, error in
        guard let snapshot = querySnapshot else {
            print("Error fetching snapshots: \(error!)")
            return
        }

        snapshot.documentChanges.forEach { diff in
            if (diff.type == .added){
                for document in (snapshot.documents) {
                    guard let isTransactionCurrent = document.data()["Current"] as? Bool else { return }
                    guard let TransactionData = document.data()["Transaction"] as? [String: Any] else { return }
                    guard let TID = TransactionData["TransactionID"] as? String else { return }
                    
                    if !isTransactionCurrent && TransactionsHistory.contains(where: {$0.TID != TID}) {
                        guard let Amount = TransactionData["Amount"] as? NSNumber else { return }
                        
                        //Location & Organization Info
                        guard let Info = document.data()["Data"] as? [String: Any] else { return }
                        guard let Floor = Info["Floor"] as? String else { return }
                        guard let Organization = Info["Organization"] as? String else { return }
                        guard let Spot = Info["Spot"] as? String else { return }
                        guard let Rate = Info["Rate"] as? NSNumber else { return }
                        
                        //Date & Time info
                        guard let Time = document.data()["Duration"] as? [String: Any] else { return }
                        guard let Duration = Time["Minutes"] as? NSNumber else { return }
                        guard let EndDay = Time["End"] as? Firebase.Timestamp else { return }
                        TransactionsHistory.insert(Transactions(Organization: Organization, Floor: Floor, Spot: Spot, TID: TID, Rate: Rate, Cost: Amount, Duration: Duration, Day: EndDay.dateValue()), at: 0)
                    }
                }
            }
            
            if (diff.type == .modified) {
                for document in (snapshot.documents) {
                    guard let isTransactionCurrent = document.data()["Current"] as? Bool else { return }
                    guard let TransactionData = document.data()["Transaction"] as? [String: Any] else { return }
                    guard let TID = TransactionData["TransactionID"] as? String else { return }
                    
                    if !isTransactionCurrent && TransactionsHistory.contains(where: {$0.TID != TID}) {
                        guard let Amount = TransactionData["Amount"] as? NSNumber else { return }
                        print("MODIFIED TRANSACTION: ", Amount)
                        //Location & Organization Info
                        guard let Info = document.data()["Data"] as? [String: Any] else { return }
                        guard let Floor = Info["Floor"] as? String else { return }
                        guard let Organization = Info["Organization"] as? String else { return }
                        guard let Spot = Info["Spot"] as? String else { return }
                        guard let Rate = Info["Rate"] as? NSNumber else { return }
                        
                        //Date & Time info
                        guard let Time = document.data()["Duration"] as? [String: Any] else { return }
                        guard let Duration = Time["Minutes"] as? NSNumber else { return }
                        guard let EndDay = Time["End"] as? Firebase.Timestamp else { return }
                        TransactionsHistory.insert(Transactions(Organization: Organization, Floor: Floor, Spot: Spot, TID: TID, Rate: Rate, Cost: Amount, Duration: Duration, Day: EndDay.dateValue()), at: 0)
                    }
                }
            }
        }
    }
}

func checkCurrentTransaction(){
    database.collection("Users").document("Commuters").collection("Users").document(UserData[indexPath.row].UID).collection("History").order(by: "Duration.Begin", descending: true).limit(to: 1).getDocuments { (snapshot, error) in
        if error != nil {
            print(error as Any)
        }else{
            for document in (snapshot?.documents)! {
                guard let Current = document.data()["Current"] as? Bool else { return }
                
                if Current {
                    guard let Info = document.data()["Data"] as? [String: Any] else { return }
                    guard let Floor = Info["Floor"] as? String else { return }
                    guard let Organization = Info["Organization"] as? String else { return }
                    guard let Spot = Info["Spot"] as? String else { return }
                    guard let Rate = Info["Rate"] as? NSNumber else { return }
                    guard let Location = Info["Location"] as? GeoPoint else { return }
                    guard let Time = document.data()["Duration"] as? [String: Firebase.Timestamp] else { return }
//                    guard let StartLocation = Info["Start Location"] as? GeoPoint else { return }
                    let Start = Time["Begin"]!.dateValue()
                    let difference = Calendar.current.dateComponents([.minute], from: Start, to: Date())
                    
                    let Amount = Double(difference.minute!) * Double(truncating: Rate)
                    
                    TransactionData.append(Payment(Current: true, Start: Start, Amount: Amount))
                    getCurrentParkingData(Location: Location, Organization: Organization, Spot: Spot, Floor: Floor, Rate: Rate)
                    
                    mainTimer.start()
                }
            }
        }
    }
}

func getCurrentParkingData(Location: GeoPoint, Organization: String, Spot: String, Floor: String, Rate: NSNumber){
    database.collection("PSU").whereField("Location", isEqualTo: Location).getDocuments { snapshot, error in
        if let error = error {
            print("Error getting documents: \(error)")
        }else{
            for document in snapshot!.documents {
                if document.exists {
                    let name = document.data()["Name"] as! String
                    let types = document.data()["Spot Types"] as! [String: Bool]
                    let CompanyStripeID = document.data()["CompanyStripeID"] as! String
                    SelectedParkingData.append(SelectedParking(Location: Location, Name: name, Types: types, Organization: Organization, Price: Rate, Floor: Floor, Spot: Spot, CompanyStripeID: CompanyStripeID))
                }
            }
        }
    }
}
