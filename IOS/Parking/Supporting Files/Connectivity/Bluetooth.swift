//
//  Bluetooth.swift
//  Theory Parking
//
//  Created by Omar on 6/7/20.
//  Copyright © 2020 Theory Parking. All rights reserved.
//

import Foundation
import CoreBluetooth
import BLTNBoard

class BLE: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    // BLTNBoard START
    let backgroundStyles = BackgroundStyles()
    var currentBackground = (name: "Dimmed", style: BLTNBackgroundViewStyle.dimmed)
    var errorMessage = String()
    
    lazy var bulletinManagerError: BLTNItemManager = {
        let page = BulletinDataSource.makeErrorPage(message: errorMessage)
        return BLTNItemManager(rootItem: page)
    }()
    // BLTNBoard END
    
    private var manager: CBCentralManager!
    private var peripheral: CBPeripheral?
   
    required override init() {
        super.init()
        manager = CBCentralManager.init(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            case .poweredOff:
                errorMessage = "BLE is powered off"
            case .poweredOn:
                errorMessage = "BLE is poweredOn"
            case .resetting:
                errorMessage = "BLE is resetting"
            case .unauthorized:
                errorMessage = "BLE is unauthorized"
            case .unknown:
                errorMessage = "BLE is unknown"
            case .unsupported:
                errorMessage = "BLE is unsupported"
            default:
                errorMessage = "default"
        }
        print(errorMessage)
        self.bulletinManagerError.allowsSwipeInteraction = false
//        self.bulletinManagerError.showBulletin(above: self)
    }
    
   //Connecting to device
   func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
      self.peripheral = peripheral
      self.peripheral?.delegate = self
      manager?.connect(peripheral, options: nil)
      manager?.stopScan()
   }
}
