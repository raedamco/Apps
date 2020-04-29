/**
 *  BulletinBoard
 *  Copyright (c) 2017 - present Alexis Aubry. Licensed under the MIT license.
 */

import UIKit
import CoreLocation
import UserNotifications
/**
 * Requests permission for system features.
 */

class PermissionsManager {
    
    static let shared = PermissionsManager()
    
    let locationManager = CLLocationManager()
    
    func requestLocalNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            print(error?.localizedDescription ?? "Error")
        }
    }
    
    func requestWhenInUseLocation() {
        locationManager.requestWhenInUseAuthorization()
    }
    
}
