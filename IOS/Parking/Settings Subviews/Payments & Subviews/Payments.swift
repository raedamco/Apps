//
//  PaymentViewController.swift
//  Parking
//
//  Created by Omar on 9/10/19.
//  Copyright © 2019 WAKED. All rights reserved.
//

import UIKit
import Firebase
import BLTNBoard
import Stripe


class PaymentViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
        
    let tableView = UITableView()
    var sections = ["Transaction History", "Payment Methods", "Rewards"]
    
    // BLTNBoard START
    let backgroundStyles = BackgroundStyles()
    var currentBackground = (name: "Dimmed", style: BLTNBackgroundViewStyle.dimmed)

    var errorMessageBLTN = String()
    lazy var bulletinManagerError: BLTNItemManager = {
       let page = BulletinDataSource.makeErrorPage(message: errorMessageBLTN)
       return BLTNItemManager(rootItem: page)
    }()
    
    lazy var bulletinManagerComingSoon: BLTNItemManager = {
       let page = BulletinDataSource.comingSoon()
       return BLTNItemManager(rootItem: page)
    }()
    
    // BLTNBoard END
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createViewLayout()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setNeedsStatusBarAppearanceUpdate()
        checkConnection()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationbarAttributes(Hidden: false, Translucent: false)
    }

    func createViewLayout(){
        view.backgroundColor = standardBackgroundColor
        setupNavigationBar(LargeText: true, Title: "Payments", SystemImageR: false, ImageR: false, ImageTitleR: "", TargetR: nil, ActionR: nil, SystemImageL: true, ImageL: true, ImageTitleL: "xmark", TargetL: self, ActionL: #selector(self.closeView(gesture:)))

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "paymentCell")
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
        
        view = tableView
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "paymentCell", for: indexPath as IndexPath)
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
        if sections[indexPath.row] == "Payment Methods"{
            showView(ViewController: PaymentMethod())
        }else if sections[indexPath.row] == "Transaction History"{
            showView(ViewController: TransactionHistory())
        }else if sections[indexPath.row] == "Rewards"{
            self.bulletinManagerComingSoon.allowsSwipeInteraction = false
            self.bulletinManagerComingSoon.showBulletin(above: self)
        }
    }
    
    @objc func closeView(gesture: UISwipeGestureRecognizer) {
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.pushViewController(SettingsViewController(), animated: false)
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
    }
    
}


