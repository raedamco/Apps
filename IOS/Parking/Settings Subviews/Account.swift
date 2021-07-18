//
//  AccountViewController.swift
//  Parking
//
//  Created by Omar on 9/8/19.
//  Copyright © 2019 WAKED. All rights reserved.
//

import UIKit
import Firebase
import BLTNBoard

class AccountViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var tableView = UITableView()
    var itemsInSections = [[""],[""],[""],[""]]
    //"\(UserData[indexPath.row].Phone.converToPhoneFormat(pattern: "###-###-####", replacmentCharacter: "#"))
    //[UserData[indexPath.row].License[indexPath.row]
    var sections = ["","Vehicles","Permits",""]
    
    // BLTNBoard START
       let backgroundStyles = BackgroundStyles()
       var currentBackground = (name: "Dimmed", style: BLTNBackgroundViewStyle.dimmed)
       
       lazy var bulletinManagerAddData: BLTNItemManager = {
           let page = BulletinDataSource.AddDataPage()
           return BLTNItemManager(rootItem: page)
        }()
    
        lazy var bulletinManagerComingSoon: BLTNItemManager = {
           let page = BulletinDataSource.comingSoon()
           return BLTNItemManager(rootItem: page)
        }()
    // BLTNBoard END
    
    override func viewDidLoad() {
        super.viewDidLoad()
        itemsInSections = [["\(UserData[indexPath.row].Email)",""],["None",""],["None",""],["Logout"]]
        createViewLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationbarAttributes(Hidden: false, Translucent: false)
    }
    
    func createViewLayout(){
        view.backgroundColor = standardBackgroundColor
        setupNavigationBar(LargeText: true, Title: UserData[indexPath.row].Name, SystemImageR: true, ImageR: true, ImageTitleR: "plus", TargetR: self, ActionR: #selector(self.tempView), SystemImageL: true, ImageL: true, ImageTitleL: "xmark", TargetL: self, ActionL: #selector(self.closeView(gesture:)))

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "accountCell")
        tableView.isScrollEnabled = true
        tableView.allowsSelection = true
        tableView.rowHeight = 70
        tableView.separatorColor = UIColor.clear.withAlphaComponent(0.5)
        let adjustForTabbarInsets: UIEdgeInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: UITabBar.appearance().frame.height, right: 0)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        tableView.indicatorStyle = UIScrollView.IndicatorStyle.default
        tableView.contentMode = .scaleAspectFit
        tableView.backgroundColor = standardBackgroundColor
        tableView.contentInset = adjustForTabbarInsets
        tableView.scrollIndicatorInsets = adjustForTabbarInsets
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 780)
        view.addSubview(tableView)

    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return itemsInSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sections[section] == "Vehicles"{
            return itemsInSections[section].count//UserData[indexPath.row].License.count
        }else{
            return itemsInSections[section].count
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = standardBackgroundColor
        let headerLabel = UILabel(frame: CGRect(x: 15, y: -1, width: tableView.frame.width, height: 25))
        headerLabel.font = UIFont(name: font, size: 24)
        headerLabel.textColor = standardContrastColor
        headerLabel.text = self.tableView(tableView, titleForHeaderInSection: section)
        headerLabel.sizeToFit()
        headerView.addSubview(headerLabel)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section < sections.count {
            return sections[section]
        }
        return nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "accountCell", for: indexPath as IndexPath)
        cell.textLabel?.font = UIFont(name: font, size: 18)
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        cell.textLabel!.text = self.itemsInSections[indexPath.section][indexPath.row]
        cell.accessoryType = UITableViewCell.AccessoryType.none
        cell.backgroundColor = standardBackgroundColor
        cell.textLabel?.textColor = standardContrastColor

        if cell.textLabel!.text == "Logout" {
            cell.textLabel?.textAlignment = .center
        }

        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if itemsInSections[indexPath.section][indexPath.row] == "Logout" {
            logout()
        }
       
    }
    
    @objc func tempView(){
        self.bulletinManagerComingSoon.allowsSwipeInteraction = false
        self.bulletinManagerComingSoon.showBulletin(above: self)
    }
    
    @objc func addData() {
        self.bulletinManagerAddData.allowsSwipeInteraction = false
        self.bulletinManagerAddData.showBulletin(above: self)
    }
    
    @objc func closeView(gesture: UISwipeGestureRecognizer) {
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.pushViewController(SettingsViewController(), animated: false)
    }
    
    @objc func logout(){
        UserData.removeAll()
        TransactionsHistory.removeAll()
        SelectedParkingData.removeAll()
        try! Auth.auth().signOut()
        self.navigationController?.pushViewController(StartViewController(), animated: false)
        self.tabBarController?.tabBar.isHidden = true
    }

}

class accountCell: UITableViewCell {
    //design account table cell
    
}
