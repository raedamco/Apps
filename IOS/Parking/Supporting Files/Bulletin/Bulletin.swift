/**
 *  BulletinBoard
 *  Copyright (c) 2017 - present Alexis Aubry. Licensed under the MIT license.
 */

import UIKit
import BLTNBoard
import SafariServices
import Firebase

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
        page.appearance.actionButtonColor = standardContrastColor
        page.appearance.actionButtonTitleColor = standardBackgroundColor
        page.appearance.actionButtonFontSize = 22
        
        page.appearance.titleTextColor = standardContrastColor
        
        page.appearance.alternativeButtonTitleColor = standardContrastColor
        page.appearance.alternativeButtonFontSize = 20
        
        page.actionButtonTitle = "More Info"
        page.alternativeButtonTitle = "Close"
        page.descriptionText = "Time: \(RouteData[indexPath.row].Time) \n Distance: \(RouteData[indexPath.row].Distance)"
        page.requiresCloseButton = false
        
        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
            NotificationCenter.default.post(name: NSNotification.Name("moreInfo"), object: nil)
        }
        
        page.alternativeHandler = { item in
            item.manager?.dismissBulletin(animated: true)
        }
        
        return page
    }
    
    static func startRoute() -> FeedbackPageBLTNItem {
        let page = FeedbackPageBLTNItem(title: "Confirm")

        page.appearance.actionButtonColor = standardContrastColor
        page.appearance.actionButtonTitleColor = standardBackgroundColor
        page.appearance.actionButtonFontSize = 22
        
        page.appearance.titleTextColor = standardContrastColor
        
        page.appearance.alternativeButtonTitleColor = standardContrastColor
        page.appearance.alternativeButtonFontSize = 20
        
        page.descriptionLabel?.textAlignment = .left
        
        page.actionButtonTitle = "Start"
        page.alternativeButtonTitle = "Cancel"
        page.descriptionText = "\(SelectedParkingData[indexPath.row].Organization) \n \(SelectedParkingData[indexPath.row].Name) \n \(SelectedParkingData[indexPath.row].Floor) - \(SelectedParkingData[indexPath.row].Spot) \n $\(SelectedParkingData[indexPath.row].Price)/min"
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
        let page = FeedbackPageBLTNItem(title: "Confirm")

        page.appearance.actionButtonColor = standardContrastColor
        page.appearance.actionButtonTitleColor = standardBackgroundColor
        page.appearance.actionButtonFontSize = 22
        
        page.appearance.titleTextColor = standardContrastColor
        
        page.appearance.alternativeButtonTitleColor = standardContrastColor
        page.appearance.alternativeButtonFontSize = 20
        
        page.descriptionLabel?.textAlignment = .left
        
        page.actionButtonTitle = "Cancel"
        page.alternativeButtonTitle = "Continue"
        page.descriptionText = "Confirm route cancelation"
        page.requiresCloseButton = false
        
        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
            NotificationCenter.default.post(name: NSNotification.Name("cancelRoute"), object: nil)
        }
        
        page.alternativeHandler = { item in
            item.manager?.dismissBulletin(animated: true)
        }
        
        return page
        
    }
    
    
    
    
 //PREFERENCES START//
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
    
    static func NotitificationsPage() -> FeedbackPageBLTNItem {
        let page = FeedbackPageBLTNItem(title: "Push Notifications")
        page.image = UIImage(named: "Notification")
        page.descriptionText = "Receive notifications regarding parking statuses, feautres, etc."
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
 //PREFERENCES END//
    
//SEARCH START//
    static func makeNoResults() -> BLTNPageItem {
        let page = BLTNPageItem(title: "No Results")
        page.image = UIImage(named: "Error")?.withTintColor(.red)
        page.appearance.actionButtonColor = UIColor.white
        page.appearance.actionButtonTitleColor = UIColor.black
        page.appearance.titleTextColor = standardContrastColor
        
        page.actionButtonTitle = "Dismiss"
        page.descriptionText = "We could not find any available parking spots near \(destinationName) at the time."
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
        let page = BLTNPageItem(title: "Confirm Location")
        page.image = UIImage(named: "Info")?.withTintColor(standardContrastColor)
        
        page.appearance.actionButtonColor = standardContrastColor
        page.appearance.actionButtonTitleColor = standardBackgroundColor
        page.appearance.actionButtonFontSize = 22
        
        page.appearance.titleTextColor = standardContrastColor
        
        page.appearance.alternativeButtonTitleColor = standardContrastColor
        page.appearance.alternativeButtonFontSize = 20
        
        page.descriptionLabel?.textAlignment = .left
        
        page.actionButtonTitle = "Yes"
        page.alternativeButtonTitle = "No"
        
//        if (NearByParking[indexPath.row].Organization == SelectedParkingData[indexPath.row].Organization) && NearByParking[indexPath.row].Spot == SelectedParkingData[indexPath.row].Spot {
//            page.descriptionText = "\(NearByParking[indexPath.row].Organization) \n \(NearByParking[indexPath.row].Name) \n \(NearByParking[indexPath.row].Floor)-\(NearByParking[indexPath.row].Spot)"
//        }
        page.descriptionText = "\(NearByParking[indexPath.row].Organization) \n \(NearByParking[indexPath.row].Name) \n \(NearByParking[indexPath.row].Floor) - \(NearByParking[indexPath.row].Spot)"
        page.requiresCloseButton = false
        

        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
            NotificationCenter.default.post(name: NSNotification.Name("startPayment"), object: nil)
        }
        
        page.alternativeHandler = { item in
            item.manager?.dismissBulletin(animated: true)
            NotificationCenter.default.post(name: NSNotification.Name("enterLocation"), object: nil)
        }
        
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
        
        page.actionButtonTitle = "Dimiss"
        page.alternativeButtonTitle = "Enter Location Manually"
        page.descriptionText = "You are not currently parked near a location we can detect"
        page.requiresCloseButton = false
        

        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
        }
        
        page.alternativeHandler = { item in
            item.manager?.dismissBulletin(animated: true)
            NotificationCenter.default.post(name: NSNotification.Name("enterLocation"), object: nil)
        }
        
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
        
        page.actionButtonTitle = "Dimiss"

        page.descriptionText = "\(NearByParking[indexPath.row].Organization) \n \(NearByParking[indexPath.row].Name) \n \(NearByParking[indexPath.row].Floor) - \(NearByParking[indexPath.row].Spot) \n Rate: $\(NearByParking[indexPath.row].Prices)/min"
        page.requiresCloseButton = false
        
        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
        }

        return page
    }
    
    static func paymentSuccessful() -> BLTNPageItem {
        let page = BLTNPageItem(title: "Success")
        
        page.image = UIImage(named: "Completion")?.withTintColor(.green)
        
        page.appearance.actionButtonColor = .green
        page.appearance.actionButtonTitleColor = standardBackgroundColor
        page.appearance.actionButtonFontSize = 22
        page.appearance.titleTextColor = standardContrastColor
    
        page.actionButtonTitle = "Dimiss"

        page.descriptionText = "Transaction completed."
        page.requiresCloseButton = false
        
        page.actionHandler = { item in
            item.manager?.dismissBulletin(animated: true)
            NotificationCenter.default.post(name: NSNotification.Name("resetTimer"), object: nil)
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
        page.actionButtonTitle = "Get started"
        page.isDismissable = true
        
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
    
}

