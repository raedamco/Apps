//
//  Structs.swift
//  Parking
//
//  Created by Omar on 11/4/19.
//  Copyright © 2019 Theory Parking. All rights reserved.
//

import Foundation
import Firebase
import UIKit


struct User {
    var BetaAccess: Bool
    var Name: String
    var Email: String
    var UID: String
    var License: [String]
    var Permit: [String:String]
    var StripeID: String
    var Phone: String
    
    init(BetaAccess: Bool, Name: String!, Email: String!, Phone: String!, UID: String!, License: [String], Permit: [String:String], StripeID: String) {
        self.BetaAccess = BetaAccess
        self.Name = Name
        self.Email = Email
        self.UID = UID
        self.License = License
        self.Permit = Permit
        self.StripeID = StripeID
        self.Phone = Phone
    }
}

struct Payment {
    var Current: Bool
    var Start: Date
    var Amount: Double
    
    init(Current: Bool, Start: Date, Amount: Double){
        self.Current = Current
        self.Start = Start
        self.Amount = Amount
    }
}

struct FinalPayment {
    var Amount: Double
    
    init(Amount: Double){
        self.Amount = Amount
    }
}


struct Transactions {
    var TID: String
    var Cost: NSNumber
    var Duration: NSNumber
    var Day: Date
    var Organization: String
    var Floor: String
    var Spot: String
    var Rate: NSNumber
    
    init(Organization: String, Floor: String, Spot: String, TID: String,Rate: NSNumber, Cost: NSNumber, Duration: NSNumber, Day: Date) {
        self.Organization = Organization
        self.Floor = Floor
        self.Spot = Spot
        self.TID = TID
        self.Rate = Rate
        self.Cost = Cost
        self.Duration = Duration
        self.Day = Day
    }
    
}

struct Parking {
    var Location: GeoPoint
    var Name: String
    var Types: [String:Bool]
    var Organization: String
    var Prices: NSNumber
    var Available: NSNumber
    var Capacity: NSNumber
    var Floors: [String]
    var Spots: [String]
    var CompanyStripeID: String
    var Distance: String
    
    init(Location: GeoPoint, Distance: String, Name: String!, Types: [String:Bool], Organization: String!, Prices: NSNumber, Capacity: NSNumber, Available: NSNumber,Floors: [String], Spots: [String], CompanyStripeID: String) {
        self.Location = Location
        self.Distance = Distance
        self.Name = Name
        self.Types = Types
        self.Organization = Organization
        self.Prices = Prices
        self.Capacity = Capacity
        self.Available = Available
        self.Floors = Floors
        self.Spots = Spots
        self.CompanyStripeID = CompanyStripeID
    }
}

struct SelectedParking {
    var Location: GeoPoint
    var Name: String
    var Types: [String:Bool]
    var Organization: String
    var Price: NSNumber
    var Floor: String
    var Spot: String
    var CompanyStripeID: String
    
    init(Location: GeoPoint, Name: String!, Types: [String:Bool], Organization: String!, Price: NSNumber, Floor: String, Spot: String, CompanyStripeID: String) {
        self.Location = Location
        self.Name = Name
        self.Types = Types
        self.Organization = Organization
        self.Price = Price
        self.Floor = Floor
        self.Spot = Spot
        self.CompanyStripeID = CompanyStripeID
    }
}

struct RouteInfo {
    var Distance: String
    var Time: String

    init(Time: String, Distance: String) {
        self.Time = Time
        self.Distance = Distance
    }
}


struct DirectionsInfo {
    var Distance: String
    var Time: String
    var Manuver: String
    
    init(Time: String, Distance: String, Manuver: String) {
        self.Time = Time
        self.Distance = Distance
        self.Manuver = Manuver
    }
}


struct Screen {
    static var width: CGFloat {
        return UIScreen.main.bounds.width
    }
    static var height: CGFloat {
        return UIScreen.main.bounds.height
    }
    static var statusBarHeight: CGFloat {
        let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        return window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
    }
}
