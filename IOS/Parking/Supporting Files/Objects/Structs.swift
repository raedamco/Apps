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
    var Name: String
    var Email: String
    var UID: String
    var License: [String]
    var Permit: [String:String]
    var StripeID: String
    var Phone: String
    
    init(Name: String!, Email: String!,Phone: String!, UID: String!, License: [String], Permit: [String:String], StripeID: String) {
        self.Name = Name
        self.Email = Email
        self.UID = UID
        self.License = License
        self.Permit = Permit
        self.StripeID = StripeID
        self.Phone = Phone
    }
}

struct Transactions {
    var TID: String
    var Cost: NSNumber
    var Duration: String
    var Day: Date
    var Organization: String
    var Floor: String
    var Spot: String
    
    init(Organization: String, Floor: String, Spot: String, TID: String, Cost: NSNumber, Duration: String, Day: Date) {
        self.Organization = Organization
        self.Floor = Floor
        self.Spot = Spot
        self.TID = TID
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
    
    init(Location: GeoPoint, Name: String!, Types: [String:Bool], Organization: String!, Prices: NSNumber, Capacity: NSNumber, Available: NSNumber,Floors: [String], Spots: [String]) {
        self.Location = Location
        self.Name = Name
        self.Types = Types
        self.Organization = Organization
        self.Prices = Prices
        self.Capacity = Capacity
        self.Available = Available
        self.Floors = Floors
        self.Spots = Spots
    }
}


struct ParkingNearby {
    var Location: GeoPoint
    var Name: String
    var Types: [String:Bool]
    var Organization: String
    var Prices: NSNumber
    var Available: NSNumber
    var Capacity: NSNumber
    var Floor: String
    var Spot: String
    
    init(Location: GeoPoint, Name: String!, Types: [String:Bool], Organization: String!, Prices: NSNumber, Capacity: NSNumber, Available: NSNumber,Floor: String,Spot: String) {
        self.Location = Location
        self.Name = Name
        self.Types = Types
        self.Organization = Organization
        self.Prices = Prices
        self.Capacity = Capacity
        self.Available = Available
        self.Floor = Floor
        self.Spot = Spot
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
    
    init(Location: GeoPoint, Name: String!, Types: [String:Bool], Organization: String!, Price: NSNumber,Floor: String, Spot: String) {
        self.Location = Location
        self.Name = Name
        self.Types = Types
        self.Organization = Organization
        self.Price = Price
        self.Floor = Floor
        self.Spot = Spot
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
