//
//  TableViewController.swift
//  Parking
//
//  Created by Omar on 9/8/19.
//  Copyright © 2019 WAKED. All rights reserved.
//

import UIKit
import LocalAuthentication
import Firebase
import BLTNBoard

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let tableView = UITableView()
    var sections = ["Account","Preferences","Payments","Help","About"]
    
    // BLTNBoard START
       let backgroundStyles = BackgroundStyles()
       var currentBackground = (name: "Dimmed", style: BLTNBackgroundViewStyle.dimmed)

       var errorMessageBLTN = String()
       lazy var bulletinManagerError: BLTNItemManager = {
           let page = BulletinDataSource.makeErrorPage(message: errorMessageBLTN)
           return BLTNItemManager(rootItem: page)
       }()
    // BLTNBoard END
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.reloadInputViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setNeedsStatusBarAppearanceUpdate()
        checkConnection()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationbarAttributes(Hidden: false, Translucent: false)
        createViewLayout()
    }
    
    func createViewLayout(){
        view.backgroundColor = standardBackgroundColor
        setupNavigationBar(LargeText: true, Title: "Settings", SystemImageR: false, ImageR: false, ImageTitleR: "", TargetR: nil, ActionR: nil, SystemImageL: false, ImageL: false, ImageTitleL: "", TargetL: nil, ActionL: nil)
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "settingsCell")
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
        tableView.tableHeaderView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.frame = CGRect(x: 0, y: 20, width: view.frame.width, height: self.view.frame.height - (UITabBar.appearance().frame.height + (navigationController?.navigationBar.frame.height)!))
        view.addSubview(tableView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath as IndexPath)
        cell.textLabel?.font = UIFont(name: font, size: 20)
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        cell.textLabel!.text = self.sections[indexPath.row]
        cell.accessoryType = UITableViewCell.AccessoryType.none
        cell.backgroundColor = standardBackgroundColor
        cell.textLabel?.textColor = standardContrastColor
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if sections[indexPath.row] == "Account"{
            showView(ViewController: AccountViewController())
        }else if sections[indexPath.row] == "Payments"{
            showView(ViewController: PaymentViewController())
        }else if sections[indexPath.row] == "Preferences"{
            showView(ViewController: PreferencesViewController())
        }else if sections[indexPath.row] == "Help"{
            showView(ViewController: HelpViewController())
        }else if sections[indexPath.row] == "About"{
            showView(ViewController: AboutViewController())
        }
    }
    
    func showView(ViewController: UIViewController){
        
        if Auth.auth().currentUser == nil {
            self.logout()
            self.errorMessageBLTN = "We hit a snag. Please sign in again."
            self.bulletinManagerError.allowsSwipeInteraction = false
            self.bulletinManagerError.showBulletin(above: self)
        }else{
            self.navigationController?.pushViewController(ViewController, animated: false)
            self.tabBarController?.tabBar.isHidden = true
       }
    }
    
    @objc func logout(){
        try! Auth.auth().signOut()
        self.navigationController?.pushViewController(StartView(), animated: false)
        self.tabBarController?.tabBar.isHidden = true
        UserData.removeAll()
        TransactionsData.removeAll()
    }

}
