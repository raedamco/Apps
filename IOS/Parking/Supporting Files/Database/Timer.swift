//
//  ParkTimer.swift
//  Parking
//
//  Created by Omar on 4/18/20.
//  Copyright © 2020 Theory Parking. All rights reserved.
//

import Foundation
import Firebase
import UIKit


func startDatabaseTimer() {
    database.collection("Users").document("Commuters").collection("Users").whereField("UUID", isEqualTo: UserData[indexPath.row].UID).addSnapshotListener { querySnapshot, error in
        guard let snapshot = querySnapshot else {
            print("Error fetching snapshots: \(error!)")
            return
        }

        snapshot.documentChanges.forEach { diff in
            if (diff.type == .added) {
                let name = diff.document.data()["Name"] as! String

                print(name)
            }

            if (diff.type == .modified) {

            }

            if (diff.type == .removed) {
                print("Removed: \(diff.document.data())")
            }
        }

    }
    startTimer()
}

func startTimer(){
    if SelectedParkingData.isEmpty {
        print("Parking not selected")
    }else{
        let structData: [String: Any] = ["Duration": ["Start":Timestamp(date: Date()),"End":nil],
                                         "Data": ["Location": SelectedParkingData[indexPath.row].Location,
                                                "Organization": SelectedParkingData[indexPath.row].Organization,
                                                "Floor": SelectedParkingData[indexPath.row].Floor,
                                                "Spot": SelectedParkingData[indexPath.row].Spot,
                                                "Rate": SelectedParkingData[indexPath.row].Price
                                                ],
                                         "Transaction ID": "PLACEHOLDER"
                                        ]
        
        database.collection("Users").document("Commuters").collection("Users").document(UserData[indexPath.row].UID).collection("History").addDocument(data: structData) { error in
            if let error = error?.localizedDescription {
                print(error)
            }
        }
    }
    
    
}

func endTimer(){
    let structData: [String: Any] = ["Duration": ["End":Timestamp(date: Date())]]
    
    database.collection("Users").document("Commuters").collection("Users").document(UserData[indexPath.row].UID).collection("History").order(by: "Duration.Start", descending: true).limit(to: 1).getDocuments { (snapshot, error) in if error != nil {
        print(error as Any)
        }else{
            for document in (snapshot?.documents)! {
                database.collection("Users").document("Commuters").collection("Users").document(UserData[indexPath.row].UID).collection("History").document(document.documentID).setData(structData, merge: true) { error in
                    if let error = error?.localizedDescription {
                        print(error)
                    }
                }
            }
        }
    }
}
