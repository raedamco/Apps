//
//  Public Variables.swift
//  Parking
//
//  Created by Omar on 9/8/19.
//  Copyright © 2019 WAKED. All rights reserved.
//

import Foundation
import Alamofire
import Firebase
import UIKit

let userDefaults = UserDefaults.standard
let indexPath = IndexPath(row: Int(), section: Int())
let database = Firestore.firestore()
let settings = database.settings
var reference: DocumentReference? = nil
var storageReference = Storage.storage().reference()
var parkingAreas = [String]()
var destinationName = String()
var functions = Functions.functions()
var errorMessage = String()
var functionError = Bool()
let currentDay = DateFormatter.localizedString(from: NSDate() as Date, dateStyle: .medium, timeStyle: .short)

//WEBSITE LINKS
var webLink = String()
var webViewLabel = String()

//COLORS

var standardBackgroundColor = UIColor(named: "color")!
var standardContrastColor = UIColor(named: "contrastColor")!

//FONTS
var font = "VarelaRound-Regular"
var fontBold = "VarelaRound-Regular"
var standardFont = "VarelaRound-Regular"
var standardTintColor = UIColor(red:0.00, green:0.48, blue:1.00, alpha:1.0)
var standardClearColor = UIColor.clear

//NAVIGATION CONTROLLER
let titleAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: standardContrastColor, NSAttributedString.Key.font: UIFont(name: font, size: 17)!]
let buttonAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: standardContrastColor, NSAttributedString.Key.font: UIFont(name: font, size: 17)!]
let largeTitleAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: standardContrastColor, NSAttributedString.Key.font: UIFont(name: font, size: 35)!]

//DISTANCES (METERS)
let blockDistance = 0.012427423844747
let nearByDistance = Double(1000000)
