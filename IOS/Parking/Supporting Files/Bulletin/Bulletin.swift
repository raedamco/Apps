/**
 *  BulletinBoard
 *  Copyright (c) 2017 - present Alexis Aubry. Licensed under the MIT license.
 */

import UIKit
import BLTNBoard
import SafariServices
import Firebase
import Lottie
import Alamofire


enum BulletinDataSource {

    static func makeItemInfoPage() -> BLTNPageItem {
        let page = FeedbackPageBLTNItem(title: "title")
        page.descriptionText = "text"
        page.requiresCloseButton = true
        page.isDismissable = true
        page.appearance.titleTextColor = standardContrastColor
        
        return page
    }
    
    static func routeInfo() -> BLTNPageItem {
        let page = FeedbackPageBLTNItem(title: "Route Info")
        page.requiresCloseButton = true
        page.isDismissable = true
        page.appearance.actionButtonColor = standardContrastColor
        page.appearance.actionButtonTitleColor = standardBackgroundColor
        page.appearance.actionButtonFontSize = 22
    
        page.appearance.titleTextColor = standardContrastColor
        page.appearance.alternativeButtonTitleColor = .red
        page.appearance.alternativeButtonFontSize = 20
        
        page.actionButtonTitle = "More Info"
        page.alternativeButtonTitle = "Cancel Route"
        page.descriptionText = "Time: \(RouteData[indexPath.row].Time) \n Distance: \(RouteData[indexPath.row].Distance) \n \(SelectedParkingData[indexPath.row].Floor) - Spot: \(SelectedParkingData[indexPath.row].Spot) \n $\(convertToString(Number: SelectedParkingData[indexPath.row].Price))/min"
        
        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
            NotificationCenter.default.post(name: NSNotification.Name("moreInfo"), object: nil)
        }
        
        page.alternativeHandler = { item in
            let confrimCancel = self.cancelRoute()
            page.manager?.push(item: confrimCancel)
        }
        
        return page
    }
    
    static func startRoute() -> FeedbackPageBLTNItem {
        let page = FeedbackPageBLTNItem(title: "Confirm Route")
        page.appearance.titleTextColor = standardContrastColor
        page.appearance.actionButtonColor = standardContrastColor
        page.appearance.actionButtonTitleColor = standardBackgroundColor
        page.appearance.actionButtonFontSize = 22
        page.appearance.alternativeButtonTitleColor = standardContrastColor
        page.appearance.alternativeButtonFontSize = 20
        
        page.actionButtonTitle = "Start"
        page.alternativeButtonTitle = "Cancel"
        page.descriptionText = "\(SelectedParkingData[indexPath.row].Organization) \n \(SelectedParkingData[indexPath.row].Name) \n \(SelectedParkingData[indexPath.row].Floor) - Spot: \(SelectedParkingData[indexPath.row].Spot) \n $\(convertToString(Number: SelectedParkingData[indexPath.row].Price))/min"
        page.requiresCloseButton = false
        
        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
            NotificationCenter.default.post(name: NSNotification.Name("startRoute"), object: nil)
        }
        
        page.alternativeHandler = { item in
            item.manager?.dismissBulletin(animated: true)
            NotificationCenter.default.post(name: NSNotification.Name("cancelRoute"), object: nil)
        }
        
        return page
        
    }
    
    static func cancelRoute() -> FeedbackPageBLTNItem {
        let page = FeedbackPageBLTNItem(title: "Confirm Cancelation")
        page.appearance.titleTextColor = standardContrastColor
        page.appearance.actionButtonColor = .red
        page.appearance.actionButtonTitleColor = standardBackgroundColor
        page.appearance.actionButtonFontSize = 22
        page.appearance.alternativeButtonTitleColor = standardContrastColor
        page.appearance.alternativeButtonFontSize = 20
        page.descriptionLabel?.textAlignment = .left
        page.alternativeButtonTitle = "Continue Route"
        page.actionButtonTitle = "End Route"
        page.requiresCloseButton = false
        
        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
            NotificationCenter.default.post(name: NSNotification.Name("cancelRoute"), object: nil)
            SelectedParkingData.removeAll()
        }
        
        page.alternativeHandler = { item in
            item.manager?.dismissBulletin(animated: true)
        }
        
        return page
    }
    
    static func updateLocationSettings() -> FeedbackPageBLTNItem {
        let page = FeedbackPageBLTNItem(title: "Location Required")
        page.appearance.titleTextColor = standardContrastColor
        page.appearance.actionButtonColor = standardContrastColor
        page.appearance.actionButtonTitleColor = standardBackgroundColor
        page.appearance.actionButtonFontSize = 22
        page.actionButtonTitle = "Enable Location Services"
        page.requiresCloseButton = false
        
        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
            UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
        }

        return page
    }
    
// MARK: ACCOUNT BLTN START
    static func AddDataPage() -> FeedbackPageBLTNItem {
        let page = FeedbackPageBLTNItem(title: "Add Data")
        page.appearance.titleTextColor = standardContrastColor
        page.appearance.actionButtonColor = standardContrastColor
        page.appearance.actionButtonTitleColor = standardBackgroundColor
        page.appearance.actionButtonFontSize = 22
        page.appearance.alternativeButtonTitleColor = standardContrastColor
        page.appearance.alternativeButtonFontSize = 20
        page.descriptionLabel?.textAlignment = .left
        page.actionButtonTitle = "Vehicle"
        page.alternativeButtonTitle = "Permit"
        page.requiresCloseButton = false
        
        page.actionHandler = { item in
            let nextPage = self.AddVehicleData()
            page.manager?.push(item: nextPage)
        }
        
        page.alternativeHandler = { item in
            let nextPage = self.AddPermitData()
            page.manager?.push(item: nextPage)
        }
        
        return page
        
    }
    
    static func AddVehicleData() -> TextFieldAddDataBulletinPage {
        let page = TextFieldAddDataBulletinPage(title: "Add Vehicle")
        page.descriptionText = "Enter your vehicle's licence plate"
        page.appearance.titleTextColor = standardContrastColor
        page.isDismissable = true
        page.requiresCloseButton = false
        page.actionButtonTitle = "Continue"

        page.actionHandler = { item in
            if functionError == true {
                let errorPage = self.makeErrorPage(message: "Vehicle already in database")
                page.manager?.push(item: errorPage)
            }else if functionError == false{
                let completionPage = self.successPage(text: "Vehicle successfully added")
                item.manager?.push(item: completionPage)
            }
        }
        
        return page
    }
    
    static func AddPermitData() -> TextFieldAddDataBulletinPage {
        let page = TextFieldAddDataBulletinPage(title: "Add Permit")
        page.descriptionText = "Enter your permit number"
        page.appearance.titleTextColor = standardContrastColor
        page.isDismissable = true
        page.requiresCloseButton = false
        page.actionButtonTitle = "Continue"

        page.actionHandler = { item in
            if functionError == true {
                let errorPage = self.makeErrorPage(message: "Error")
                page.manager?.push(item: errorPage)
            }else{
                let completionPage = self.successPage(text: "Permit Successfully Added")
                item.manager?.push(item: completionPage)
            }
        }

        return page
    }
    
    static func successPage(text: String) -> BLTNPageItem {
        let page = BLTNPageItem(title: text)
        page.image = UIImage(named: "Completion")
        page.appearance.titleTextColor = standardContrastColor
        page.appearance.actionButtonColor = UIColor.green
        page.appearance.imageViewTintColor = UIColor.green
        page.appearance.actionButtonTitleColor = UIColor.white
        page.actionButtonTitle = "Close"
        page.isDismissable = true
        page.requiresCloseButton = false
        
        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
        }
        
        return page
    }
    
// MARK: ACCOUNT BLTN END

// MARK: PREFERENCES BLTN START
    static func LocationPage() -> FeedbackPageBLTNItem {
        let page = FeedbackPageBLTNItem(title: "Location Services")
        page.image = UIImage(named: "Location")
        page.descriptionText = "Location services required to improve results"
        page.actionButtonTitle = "Enable"
        page.isDismissable = false
        page.appearance.titleTextColor = standardContrastColor
        
        if userDefaults.bool(forKey: "LOCATION") == true {
            page.alternativeButtonTitle = "Disable"
        }else{
            page.alternativeButtonTitle = "Not now"
        }
        
        page.actionHandler = { item in
            userDefaults.set(true, forKey: "LOCATION")
            PermissionsManager.shared.requestWhenInUseLocation()
            item.manager?.dismissBulletin(animated: true)
        }
        
        page.alternativeHandler = { item in
            userDefaults.set(false, forKey: "LOCATION")
            item.manager?.dismissBulletin(animated: true)
        }
        
        return page
        
    }
    
    static func BluetoothPage() -> FeedbackPageBLTNItem {
        let page = FeedbackPageBLTNItem(title: "Bluetooth")
        page.image = UIImage(named: "Bluetooth")
        page.descriptionText = "Bluetooth services required to improve experience"
        page.actionButtonTitle = "Enable"
        page.isDismissable = false
        page.appearance.titleTextColor = standardContrastColor
        
        if userDefaults.bool(forKey: "BLUETOOTH") == true {
            page.alternativeButtonTitle = "Disable"
        }else{
            page.alternativeButtonTitle = "Not now"
        }
        
        page.actionHandler = { item in
            userDefaults.set(true, forKey: "BLUETOOTH")
            NotificationCenter.default.post(name: NSNotification.Name("bluetoothPermission"), object: nil)
            item.manager?.dismissBulletin(animated: true)
        }
        
        page.alternativeHandler = { item in
            userDefaults.set(false, forKey: "BLUETOOTH")
            item.manager?.dismissBulletin(animated: true)
        }
        
        return page
        
    }
    
    static func NotitificationsPage() -> FeedbackPageBLTNItem {
        let page = FeedbackPageBLTNItem(title: "Push Notifications")
        page.image = UIImage(named: "Notification")
        page.descriptionText = "Receive notifications regarding parking statuses, new feautres, etc."
        page.actionButtonTitle = "Enable"
        page.isDismissable = false
        page.appearance.titleTextColor = standardContrastColor
        
        if userDefaults.bool(forKey: "NOTIFICATIONS") == true {
            page.alternativeButtonTitle = "Disable"
        }else{
            page.alternativeButtonTitle = "Not now"
        }

        page.actionHandler = { item in
            PermissionsManager.shared.requestLocalNotifications()
            userDefaults.set(true, forKey: "NOTIFICATIONS")
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in })
            UIApplication.shared.registerForRemoteNotifications()
            item.manager?.dismissBulletin(animated: true)
        }
        
        page.alternativeHandler = { item in
            userDefaults.set(false, forKey: "NOTIFICATIONS")
            UIApplication.shared.unregisterForRemoteNotifications()
            item.manager?.dismissBulletin(animated: true)
        }
        
        return page
        
    }
    
    static func AutoCheckInPage() -> FeedbackPageBLTNItem {
        let page = FeedbackPageBLTNItem(title: "Auto Check-In")
        page.image = UIImage(named: "CheckIn")
        page.descriptionText = "Automatically start the check in process when you arrive at your destination"
        page.actionButtonTitle = "Enable"
        page.isDismissable = false
        page.appearance.titleTextColor = standardContrastColor
        
        if userDefaults.bool(forKey: "AUTO-CHECKIN") == true {
            page.alternativeButtonTitle = "Disable"
        }else{
            page.alternativeButtonTitle = "Not now"
        }
        
        page.actionHandler = { item in
            userDefaults.set(true, forKey: "AUTO-CHECKIN")
            item.manager?.dismissBulletin(animated: true)
        }
        
        page.alternativeHandler = { item in
            userDefaults.set(false, forKey: "AUTO-CHECKIN")
            item.manager?.dismissBulletin(animated: true)
        }
        return page
    }
    
// MARK: PREFERENCES BLTN END
    
//SEARCH START//
    static func makeNoResults() -> BLTNPageItem {
        let page = BLTNPageItem(title: "No Results")
        
        page.appearance.actionButtonColor = standardContrastColor
        page.appearance.actionButtonTitleColor = standardBackgroundColor
        page.appearance.titleTextColor = standardContrastColor
        page.actionButtonTitle = "Dismiss"
        page.descriptionText = "No available parking near \(destinationName) at this time."
        page.requiresCloseButton = false
        
        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
            NotificationCenter.default.post(name: NSNotification.Name("closeView"), object: nil)
        }
        
        return page
    }
//SEARCH END//
    
    
//CHECKIN START//
    static func parkingProviderInfo() -> BLTNPageItem {
        let page = BLTNPageItem(title:"Confirm Location")
        page.appearance.actionButtonColor = standardContrastColor
        page.appearance.actionButtonTitleColor = standardBackgroundColor
        page.appearance.actionButtonFontSize = 22
        page.appearance.titleTextColor = standardContrastColor
        page.appearance.alternativeButtonTitleColor = standardContrastColor
        page.appearance.alternativeButtonFontSize = 20
        page.descriptionLabel?.textAlignment = .left
        
        if SelectedParkingData.count > 0 {
            page.actionButtonTitle = "Yes"
            page.alternativeButtonTitle = "No"
            
            page.descriptionText = "\(SelectedParkingData[indexPath.row].Organization) \n \(SelectedParkingData[indexPath.row].Name) \n \(SelectedParkingData[indexPath.row].Floor) - Spot: \(SelectedParkingData[indexPath.row].Spot)"
            
            page.actionHandler = { item in
                item.manager?.dismissBulletin(animated: true)
                ServerTimer.requestTimer()
                NotificationCenter.default.post(name: NSNotification.Name("presentLoadingAnimation"), object: nil)
            }
            
            page.alternativeHandler = { item in
                item.manager?.dismissBulletin(animated: true)
                NotificationCenter.default.post(name: NSNotification.Name("enterLocation"), object: nil)
            }
        }else if SelectedParkingData.count == 0{
            page.actionButtonTitle = "Dismiss"
            
            page.descriptionText = "You must enter your destination and arrive prior to starting payment"
            
            page.actionHandler = { item in
                item.manager?.dismissBulletin(animated: true)
            }

        }
        page.requiresCloseButton = false
    
        return page
    }
    
    static func noParkingProviderInfo() -> BLTNPageItem {
        let page = BLTNPageItem(title: "Location Not Found")
        
        page.image = UIImage(named: "Error")?.withTintColor(standardContrastColor)
        
        page.appearance.actionButtonColor = standardContrastColor
        page.appearance.actionButtonTitleColor = standardBackgroundColor
        page.appearance.actionButtonFontSize = 22
        
        page.appearance.titleTextColor = standardContrastColor
        
        page.appearance.alternativeButtonTitleColor = standardContrastColor
        page.appearance.alternativeButtonFontSize = 18
        
        page.actionButtonTitle = "Dismiss"
//        page.alternativeButtonTitle = "Enter Location Manually"
        page.descriptionText = "You are not currently parked near a location we can detect"
        page.requiresCloseButton = false
        

        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
        }
        
//        page.alternativeHandler = { item in
//            item.manager?.dismissBulletin(animated: true)
//            NotificationCenter.default.post(name: NSNotification.Name("enterLocation"), object: nil)
//        }
        
        return page
    }
    
    static func parkingInfo() -> BLTNPageItem {
        let page = BLTNPageItem(title: "Details")
        
        //page.image = UIImage(named: "Info")?.withTintColor(standardContrastColor)
        
        page.appearance.actionButtonColor = standardContrastColor
        page.appearance.actionButtonTitleColor = standardBackgroundColor
        page.appearance.actionButtonFontSize = 22
        page.appearance.titleTextColor = standardContrastColor
        page.descriptionLabel?.textAlignment = .left
        
        page.actionButtonTitle = "Dismiss"

        if !SelectedParkingData.isEmpty {
           page.descriptionText = "\(SelectedParkingData[indexPath.row].Organization) \n \(SelectedParkingData[indexPath.row].Name) \n \(SelectedParkingData[indexPath.row].Floor) - Spot: \(SelectedParkingData[indexPath.row].Spot) \n Rate: $\(convertToString(Number: SelectedParkingData[indexPath.row].Price))/min"
        }else{
            page.descriptionText = "You are not currently parked near a location we can detect"
        }
        
        page.requiresCloseButton = false
        
        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
        }

        return page
    }
    
    static func paymentSuccessful() -> BLTNPageItem {
        let page = BLTNPageItem(title: "Success")
        
        page.image = UIImage(named: "Completion")?.withTintColor(standardContrastColor)
        
        page.appearance.actionButtonColor = standardContrastColor
        page.appearance.actionButtonTitleColor = standardBackgroundColor
        page.appearance.alternativeButtonTitleColor = standardContrastColor
        page.appearance.alternativeButtonFontSize = 18
        page.appearance.actionButtonFontSize = 22
        page.appearance.titleTextColor = standardContrastColor
        
    
        page.actionButtonTitle = "Dismiss"
        page.alternativeButtonTitle = "See details"
        
        page.descriptionText = "Transaction completed."
        page.requiresCloseButton = false
        
        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
        }
        
        page.alternativeHandler = { item in
            let detailPage = self.paymentDetails()
            item.manager?.push(item: detailPage)
        }

        return page
    }
    
    static func paymentDetails() -> BLTNPageItem {
        let page = BLTNPageItem(title: "Transaction Details")
        
        page.appearance.actionButtonColor = standardContrastColor
        page.appearance.actionButtonTitleColor = standardBackgroundColor
        page.appearance.alternativeButtonTitleColor = standardContrastColor
        page.appearance.alternativeButtonFontSize = 18
        page.appearance.actionButtonFontSize = 22
        page.appearance.titleTextColor = standardContrastColor
        
        page.actionButtonTitle = "Dismiss"
        page.alternativeButtonTitle = "Report error"
        
        page.descriptionText = "Date: \nLocation: \nDuration: \nAmount: "
        page.requiresCloseButton = false
        
        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
        }
        
        page.alternativeHandler = { item in
            //send to view to create support ticket
        }

        return page
    }
    
//CHECKIN END//
    
    static func makeCompletionPage() -> BLTNPageItem {
        let page = BLTNPageItem(title: "Setup Completed")
        page.image = UIImage(named: "Completion")
        page.appearance.titleTextColor = standardContrastColor
        page.appearance.actionButtonColor = UIColor.green
        page.appearance.imageViewTintColor = UIColor.green
        page.appearance.actionButtonTitleColor = UIColor.white
        page.actionButtonTitle = "Login"
        page.isDismissable = false
        
        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
        }
        
        return page
    }
    
    static func makeEmailPage() -> TextFieldBulletinPage {
        let page = TextFieldBulletinPage(title: "Enter an Email")
        page.appearance.titleTextColor = standardContrastColor
        page.isDismissable = true
        page.requiresCloseButton = true
        page.descriptionText = "Enter the email address you wish to recieve a copy of your transaction history."
        page.actionButtonTitle = "Send"

        page.textInputHandler = { (item, text) in
            if functionError == true {
                let errorPage = self.makeErrorPage(message: "Error")
                page.manager?.push(item: errorPage)
            }else{
                let completionPage = self.makeSentPage(userName: text)
                item.manager?.push(item: completionPage)
            }
        }
        
        return page
    }
    
    static func makeForgotPasswordPage() -> TextFieldBulletinPage {
        let page = TextFieldBulletinPage(title: "Enter your Email")
        page.appearance.titleTextColor = standardContrastColor
        page.requiresCloseButton = false
        page.descriptionText = "Enter the email address you created the account with"
        page.actionButtonTitle = "Submit"

        page.textInputHandler = { (item, text) in
            if functionError == true {
                let errorPage = self.makeErrorPage(message: "Error")
                page.manager?.push(item: errorPage)
                item.manager?.dismissBulletin(animated: true)
            }else{
                let completionPage = self.makeSentPagePassword(email: text)
                item.manager?.push(item: completionPage)
                item.manager?.dismissBulletin(animated: true)
            }
        }
        
        return page
    }
    
    static func makeSentPagePassword(email: String?) -> BLTNPageItem {
        let page = BLTNPageItem(title: "Email Sent")
        page.image = UIImage(named: "Completion")
        page.appearance.titleTextColor = standardContrastColor
        page.appearance.actionButtonColor = UIColor.green
        page.appearance.actionButtonTitleColor = UIColor.white
        page.descriptionText = "An email will be sent to \(email!) with a link to reset your password."
        page.actionButtonTitle = "Finish"
        page.isDismissable = true
        page.requiresCloseButton = false
        
        page.actionHandler = { item in
            Auth.auth().fetchSignInMethods(forEmail: email!) { (stringArray, error) in
                if error != nil {
                    let errorPage = self.makeErrorPage(message: error?.localizedDescription ?? "Error")
                    page.manager?.push(item: errorPage)
                }else{
                   Auth.auth().sendPasswordReset(withEmail: email!) { (error) in
                        if error == nil {
                            let errorPage = self.makeErrorPage(message: error?.localizedDescription ?? "Error")
                            page.manager?.push(item: errorPage)
                            item.manager?.dismissBulletin(animated: true)
                       }else{
                           item.manager?.dismissBulletin(animated: true)
                       }
                   }
               }
                item.manager?.dismissBulletin(animated: true)
            }
        }
    
        return page
    }
    
    //MARK: THIS NEEDS TO BE CLEANEDUP
    static func reserveSpot() -> TextFieldBulletinPage {
        let page = TextFieldBulletinPage(title: "Reserve my Spot")
        page.appearance.titleTextColor = standardContrastColor
        page.requiresCloseButton = false
        page.descriptionText = "Enter your email address and we will notify you once Raedam is open for you to use."
        page.actionButtonTitle = "Submit"

        page.textInputHandler = { (item, text) in
            if functionError == true {
                let errorPage = self.makeErrorPage(message: "Error")
                page.manager?.push(item: errorPage)
                item.manager?.dismissBulletin(animated: true)
            }else{
                Auth.auth().fetchSignInMethods(forEmail: text!, completion: {(providers, error) in
                    if let error = error {
                        let errorPage = self.makeErrorPage(message: error.localizedDescription)
                        page.manager?.push(item: errorPage)
                        item.manager?.dismissBulletin(animated: true)
                    } else if providers != nil {
                        NotificationCenter.default.post(name: NSNotification.Name("pushBetaSignInView"), object: nil)
                        let successPage = self.makeSuccessPage(TitleText: "Welcome to Beta Access!", ButtonText: "Continue")
                        page.manager?.push(item: successPage)
                        item.manager?.dismissBulletin(animated: true)
                    }
                })
            }
        }
        
        return page
    }
    
    
    
    
    static func reservedSpotPage(email: String?) -> BLTNPageItem {
        let page = BLTNPageItem(title: "Spot reserved!")
        page.image = UIImage(named: "Completion")
        page.appearance.titleTextColor = standardContrastColor
        page.appearance.actionButtonColor = UIColor.green
        page.appearance.actionButtonTitleColor = UIColor.white
        page.descriptionText = "An email will be sent to \(email!) when you have beta access to the Raedam app!"
        page.actionButtonTitle = "Finish"
        page.isDismissable = true
        page.requiresCloseButton = false
        
        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
        }
        
        return page
    }

    static func makeSentPage(userName: String?) -> BLTNPageItem {
        let page = BLTNPageItem(title: "Sent")
        page.image = UIImage(named: "Completion")
        page.appearance.titleTextColor = standardContrastColor
        page.appearance.actionButtonColor = UIColor.green
        page.appearance.actionButtonTitleColor = UIColor.white
        page.descriptionText = "An email will be sent to \(userName!) with a copy of your transaction history."
        page.actionButtonTitle = "Finish"
        page.isDismissable = true
        page.requiresCloseButton = false
        
        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
        }
        
        return page
    }
    
    static func makeErrorPage(message: String) -> BLTNPageItem {
        let page = BLTNPageItem(title: "Error")
        page.image = UIImage(named: "Error")?.withTintColor(.red)
        page.appearance.titleTextColor = standardContrastColor
        page.appearance.actionButtonColor = UIColor.red
        page.appearance.actionButtonTitleColor = UIColor.white
        page.descriptionText = message
        page.actionButtonTitle = "Close"
        page.isDismissable = true
        page.requiresCloseButton = false
        
        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
        }
        
        return page
    }
    
    static func makeVerifyPage() -> BLTNPageItem {
        let page = BLTNPageItem(title: "Verify Email")
        page.image = UIImage(named: "Error")
        page.appearance.titleTextColor = standardContrastColor
        page.appearance.actionButtonColor = UIColor.darkGray
        page.appearance.actionButtonTitleColor = UIColor.white
        page.descriptionText = "Please verify your email through the link we sent you"
        page.actionButtonTitle = "Ok"
        page.isDismissable = true
        page.requiresCloseButton = false
        
        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
        }
        
        return page
    }
    
    
    //TRANSACTIONS START
    static func noHistory() -> BLTNPageItem {
        let page = BLTNPageItem(title: "You have no previous transactions.")
        page.appearance.titleTextColor = standardContrastColor
        page.appearance.actionButtonColor = UIColor.darkGray
        page.appearance.actionButtonTitleColor = UIColor.white
        page.actionButtonTitle = "Ok"
        page.isDismissable = true
        page.requiresCloseButton = false
        
        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
            NotificationCenter.default.post(name: NSNotification.Name("closeTView"), object: nil)
        }
        
        return page
    }
    

    static func TransactionData(Location: String, Duration: String, Amount: String, Date: Date, TransactionID: String) -> BLTNPageItem {
        let page = BLTNPageItem(title: "Transaction Details")
        
        page.appearance.actionButtonColor = standardContrastColor
        page.appearance.actionButtonTitleColor = standardBackgroundColor
        page.appearance.alternativeButtonTitleColor = standardContrastColor
        page.appearance.alternativeButtonFontSize = 18
        page.appearance.actionButtonFontSize = 22
        page.appearance.titleTextColor = standardContrastColor
        
        page.actionButtonTitle = "Dismiss"
        page.alternativeButtonTitle = "Report error"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        
        page.descriptionText = "Location: \(Location) \nDate: \(formatter.string(from: Date)) \nDuration: \(Duration) \nAmount: $\(Amount)"
        page.requiresCloseButton = false
        
        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
            SelectedTransactionCellData.removeAll()
            
        }
        
        page.alternativeHandler = { item in
            //send to view to create support ticket
        }

        return page
    }
    
    static func LoadingAnimation() -> BLTNPageItem {
        let page = BLTNPageItem(title: "Connecting")
        
        page.appearance.titleTextColor = standardContrastColor
//        page.imageView = AnimationView(name: "connectivity")
        page.descriptionText = "Verifying data"
        page.requiresCloseButton = false
        page.isDismissable = false
        return page
    }
    
    //TRANSACTIONS START
    static func comingSoon() -> BLTNPageItem {
        let page = BLTNPageItem(title: "Coming Soon")
        page.appearance.actionButtonColor = standardContrastColor
        page.appearance.actionButtonTitleColor = standardBackgroundColor
        page.appearance.actionButtonFontSize = 22
        page.appearance.titleTextColor = standardContrastColor
        page.appearance.alternativeButtonTitleColor = standardContrastColor
        page.appearance.alternativeButtonFontSize = 18
        
        page.actionButtonTitle = "Dismiss"
        page.isDismissable = true
        page.requiresCloseButton = false
        
        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
        }
        
        return page
    }
    
    //TRANSACTIONS END
    
    
    static func makeSuccessPage(TitleText: String, ButtonText: String) -> BLTNPageItem {
        let page = BLTNPageItem(title: TitleText)
        page.image = UIImage(named: "Completion")
        page.appearance.titleTextColor = standardContrastColor
        page.appearance.actionButtonColor = UIColor.green
        page.appearance.imageViewTintColor = UIColor.green
        page.appearance.actionButtonTitleColor = UIColor.white
        page.actionButtonTitle = ButtonText
        page.isDismissable = false
        
        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
        }
        
        return page
    }
}

