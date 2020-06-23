//
//  AppDelegate.swift
//  Parking
//
//  Created by Omar on 9/8/19.
//  Copyright © 2019 WAKED. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import Firebase
import Siren
import UserNotifications
import Stripe
import ZendeskCoreSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var handle: AuthStateDidChangeListenerHandle?
    let gcmMessageIDKey = "192548003681"
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        delegateFunctions()
        return true
    }
    
    @objc func tokenRefreshNotification(notification: NSNotification) {
        //Messaging.messaging().shouldEstablishDirectChannel = true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
      if let messageID = userInfo[gcmMessageIDKey] {
        print("Message ID: \(messageID)")
      }
      print(userInfo)
    }
     
     func applicationDidBecomeActive(application: UIApplication) {
         //Messaging.messaging().shouldEstablishDirectChannel = true
     }
     
     func applicationDidEnterBackground(_ application: UIApplication) {
         //Messaging.messaging().shouldEstablishDirectChannel = true
     }
     
     func applicationWillEnterForeground(_ application: UIApplication) {
         UIApplication.shared.applicationIconBadgeNumber = 0
     }
     
     func applicationDidBecomeActive(_ application: UIApplication) {
         UIApplication.shared.applicationIconBadgeNumber = 0
     }
    
 
}


extension AppDelegate {
    
    func style() {
        UITableView.appearance().backgroundColor = standardBackgroundColor
        
        UITabBar.appearance().backgroundColor = standardBackgroundColor.withAlphaComponent(0.8)
        UITabBar.appearance().barTintColor = standardBackgroundColor
        UITabBar.appearance().tintColor = standardContrastColor
        UITabBar.appearance().clipsToBounds = true
        UITabBar.appearance().isOpaque = false
        UITabBar.appearance().isTranslucent = true
        UITabBar.appearance().backgroundImage = UIImage()
        UITabBar.appearance().shadowImage = UIImage()
    }

    func delegateFunctions(){
        Siren.shared.wail()
        FirebaseApp.configure()
        authAccountConnection()
        GMSServices.provideAPIKey("AIzaSyDONTZJEYMYC0tXKKdXt8RiO0n4lbIG9RM")
        GMSPlacesClient.provideAPIKey("AIzaSyDONTZJEYMYC0tXKKdXt8RiO0n4lbIG9RM")
        Stripe.setDefaultPublishableKey("pk_test_OSJOLg8IC2NbnY9opPzWoPSG00teCAN94U")
        style()
    }
    
    func authAccountConnection(){
        DispatchQueue.main.async {
            if Connectivity.isConnectedToInternet {
                self.handle = Auth.auth().addStateDidChangeListener { (auth, user) in
                    if (user != nil){
                        getUserData(Email: (user?.email)!)
                        self.window = UIWindow(frame: UIScreen.main.bounds)
                        self.window?.makeKeyAndVisible()
                        self.window!.rootViewController = TabBarViewController()
                    }else{
                        let navigationController = UINavigationController(rootViewController: StartView())
                        let window = UIWindow(frame: UIScreen.main.bounds)
                        window.rootViewController = navigationController
                        window.makeKeyAndVisible()
                        self.window = window
                    }
                }
            }else{
                self.window = UIWindow(frame: UIScreen.main.bounds)
                self.window?.makeKeyAndVisible()
                self.window?.rootViewController = ConnectivityViewController()
            }
        }
    }
}
