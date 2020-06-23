/**
 *  BulletinBoard
 *  Copyright (c) 2017 - present Alexis Aubry. Licensed under the MIT license.
 */

import UIKit
import CoreLocation
import UserNotifications
import CoreBluetooth
/**
 * Requests permission for system features.
 */

class PermissionsManager {
    static var centralManager: CBCentralManager?
    static var peripheral: CBPeripheral?
    static let shared = PermissionsManager()
    
    let locationManager = CLLocationManager()
    let bluetoothManager = CBCentralManager()
    
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
