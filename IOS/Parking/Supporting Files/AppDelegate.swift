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
import DropDown

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var handle: AuthStateDidChangeListenerHandle?
    let gcmMessageIDKey = "192548003681"
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        delegateFunctions()

        Messaging.messaging().delegate = self
        if #available(iOS 10.0, *) {
          UNUserNotificationCenter.current().delegate = self

          let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
          UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
        } else {
          let settings: UIUserNotificationSettings =
          UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
          application.registerUserNotificationSettings(settings)
        }

        application.registerForRemoteNotifications()
        
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        completionHandler(UIBackgroundFetchResult.newData)
    }
      
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }


    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
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
    
        UITabBar.appearance().backgroundColor = standardBackgroundColor //.withAlphaComponent(0.8)
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
        Stripe.setDefaultPublishableKey("pk_test_51H0FFyDtW0T37E4Pz0sYdXJePKCU232UipcIWTmXe41RrFI399to65b2L6rRP1qCpHspIe1Hw3utjYAIoONCT5ZI00ATVEgwEQ")
        style()
        DropDown.startListeningToKeyboard()
    }
    
    func authAccountConnection(){
        DispatchQueue.main.async {
            if Connectivity.isConnectedToInternet {
                self.handle = Auth.auth().addStateDidChangeListener { (auth, user) in
                    if (user != nil){
                        getUserData(UID: Auth.auth().currentUser!.uid) { (true) in
                            self.window = UIWindow(frame: UIScreen.main.bounds)
                            self.window?.makeKeyAndVisible()
                            self.window!.rootViewController = TabBarViewController()
                        }
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

@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {

  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([[.alert, .sound]])
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    completionHandler()
  }
}

extension AppDelegate : MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
    let dataDict:[String: String] = ["token": fcmToken]
    NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
  }
}
