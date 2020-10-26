//
//  AboutViewController.swift
//  Parking
//
//  Created by Omar on 11/10/19.
//  Copyright © 2019 Theory Parking. All rights reserved.
//

import UIKit
import Firebase

class AboutViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let tableView = UITableView()
    var sections = ["Privacy Policy","Terms of Use"]
    
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
        setupNavigationBar(LargeText: true, Title: "About", SystemImageR: false, ImageR: false, ImageTitleR: "", TargetR: nil, ActionR: nil, SystemImageL: true, ImageL: true, ImageTitleL: "xmark", TargetL: self, ActionL: #selector(self.closeView(gesture:)))

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "aboutCell")
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "aboutCell", for: indexPath as IndexPath)
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
        if sections[indexPath.row] == "Privacy Policy"{
            openWeb(Title: "Privacy Policy", URL: "https://raedam.co/privacy")
        }else if sections[indexPath.row] == "Terms of Use"{
            openWeb(Title: "Terms of Use", URL: "https://raedam.co/terms")
        }
    }
    
    @objc func closeView(gesture: UISwipeGestureRecognizer) {
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.pushViewController(SettingsViewController(), animated: false)
    }

}


