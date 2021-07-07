//
//  BetaSignup.swift
//  Theory Parking
//
//  Created by Omar Waked on 7/6/21.
//  Copyright © 2021 Raedam. All rights reserved.
//

import Foundation
import Firebase
import UIKit
import Alamofire


//func betaReserveSpot(Email: String){
//    database.collection("UsersBeta").document(Email).setData(["Email": Email, "Time": Firebase.Timestamp.init(date: Date())]){ error in
//        if let error = error?.localizedDescription {
//            let errorPage = self.makeErrorPage(message: error)
//            page.manager?.push(item: errorPage)
//            item.manager?.dismissBulletin(animated: true)
//        }else{
//            let completionPage = self.reservedSpotPage(email: text)
//            item.manager?.push(item: completionPage)
//            item.manager?.dismissBulletin(animated: true)
//            if Database.reservedSpot(Email: text!, DateSignedUp: Firebase.Timestamp.init(date: Date())){
//                print("done")
//            }
//        }
//    }
//}
