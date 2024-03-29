//
//  PreferencesViewController.swift
//  Parking
//
//  Created by Omar on 9/10/19.
//  Copyright © 2019 WAKED. All rights reserved.
//

import UIKit
import BLTNBoard

class PreferencesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var ble: BLE!
    var tableView = UITableView()
    var sections = ["Automation", "Bluetooth", "Notifications", "Location"]

    // BLTNBoard START
    let backgroundStyles = BackgroundStyles()
    var currentBackground = (name: "Dimmed", style: BLTNBackgroundViewStyle.dimmed)
    
    lazy var bulletinManagerLocation: BLTNItemManager = {
        let page = BulletinDataSource.LocationPage()
        return BLTNItemManager(rootItem: page)
    }()
    
    lazy var bulletinManagerBluetooth: BLTNItemManager = {
        let page = BulletinDataSource.BluetoothPage()
        return BLTNItemManager(rootItem: page)
    }()
    
    lazy var bulletinManagerNotification: BLTNItemManager = {
        let page = BulletinDataSource.NotitificationsPage()
        return BLTNItemManager(rootItem: page)
    }()

    lazy var bulletinManagerAutoCheckIn: BLTNItemManager = {
        let page = BulletinDataSource.AutoCheckInPage()
        return BLTNItemManager(rootItem: page)
    }()

    // BLTNBoard END
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createViewLayout()
        NotificationCenter.default.addObserver(self, selector: #selector(bluetoothPermission(notification:)), name: NSNotification.Name(rawValue: "bluetoothPermission"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationbarAttributes(Hidden: false, Translucent: false)
    }
    
    func createViewLayout(){
        view.backgroundColor = standardBackgroundColor
        setupNavigationBar(LargeText: true, Title: "Preferences", SystemImageR: false, ImageR: false, ImageTitleR: "", TargetR: nil, ActionR: nil, SystemImageL: true, ImageL: true, ImageTitleL: "xmark", TargetL: self, ActionL: #selector(self.closeView(gesture:)))

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "preferencesCell")
        tableView.isScrollEnabled = false
        tableView.allowsSelection = true
        tableView.rowHeight = 70
        tableView.separatorColor = UIColor.darkGray.withAlphaComponent(0.5)
        let adjustForTabbarInsets: UIEdgeInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: UITabBar.appearance().frame.height, right: 0)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        tableView.indicatorStyle = UIScrollView.IndicatorStyle.black
        tableView.contentMode = .scaleAspectFit
        tableView.backgroundColor = standardBackgroundColor
        tableView.contentInset = adjustForTabbarInsets
        tableView.scrollIndicatorInsets = adjustForTabbarInsets
        
        tableView.tableFooterView = UIView()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 700)
        view.addSubview(tableView)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = standardBackgroundColor
        let headerLabel = UILabel(frame: CGRect(x: 15, y: -1, width: tableView.frame.width, height: 25))
        headerLabel.text = ""
        headerView.addSubview(headerLabel)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "preferencesCell", for: indexPath as IndexPath)
        cell.textLabel?.font = UIFont(name: font, size: 20)
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        cell.textLabel!.text = self.sections[indexPath.row]
        cell.accessoryView?.tintColor = standardContrastColor
        cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        cell.backgroundColor = standardBackgroundColor
        cell.textLabel?.textColor = standardContrastColor
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if sections[indexPath.row] == "Location"{
            self.bulletinManagerLocation.allowsSwipeInteraction = false
            self.bulletinManagerLocation.showBulletin(above: self)
        }else if sections[indexPath.row] == "Bluetooth"{
            self.bulletinManagerBluetooth.allowsSwipeInteraction = false
            self.bulletinManagerBluetooth.showBulletin(above: self)
        }else if sections[indexPath.row] == "Notifications"{
            self.bulletinManagerNotification.allowsSwipeInteraction = false
            self.bulletinManagerNotification.showBulletin(above: self)
        }else if sections[indexPath.row] == "Automation"{
            self.bulletinManagerAutoCheckIn.allowsSwipeInteraction = false
            self.bulletinManagerAutoCheckIn.showBulletin(above: self)
        }
    }
    
    @objc func closeView(gesture: UISwipeGestureRecognizer) {
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.pushViewController(SettingsViewController(), animated: false)
    }

    @objc func bluetoothPermission(notification: NSNotification){
        ble = BLE()
    }
    
   

}
