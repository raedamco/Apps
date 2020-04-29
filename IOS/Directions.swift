//
//  Directions.swift
//  Parking
//
//  Created by Omar on 4/5/20.
//  Copyright © 2020 Theory Parking. All rights reserved.
//

import Foundation
import Firebase

class DirectionsTable: UITableViewController {
    
    var tableViewData = DirectionsData
    
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
        setupNavigationBar(LargeText: true, Title: "Directions", SystemImageR: false, ImageR: false, ImageTitleR: "", TargetR: nil, ActionR: nil, SystemImageL: true, ImageL: true, ImageTitleL: "xmark", TargetL: self, ActionL: #selector(self.closeView(gesture:)))
        
        tableView.register(filterCell.self, forCellReuseIdentifier: "directionsCell")
        tableView.isScrollEnabled = true
        tableView.allowsSelection = true
        tableView.rowHeight = 90
        tableView.separatorColor = .darkGray
        let adjustForTabbarInsets: UIEdgeInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: UITabBar.appearance().frame.height, right: 0)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        tableView.indicatorStyle = UIScrollView.IndicatorStyle.black
        tableView.contentMode = .scaleAspectFit
        tableView.backgroundColor = standardBackgroundColor
        tableView.contentInset = adjustForTabbarInsets
        tableView.scrollIndicatorInsets = adjustForTabbarInsets
        
        tableView.tableFooterView = UIView()
        tableView.tableHeaderView = UIView()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return tableViewData.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DirectionsData.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "directionsCell")
        cell.textLabel?.font = UIFont(name: font, size: 17)
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        cell.textLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.textLabel?.numberOfLines = 2
        cell.detailTextLabel?.numberOfLines = 3
        cell.detailTextLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.detailTextLabel?.textColor = standardContrastColor
        cell.detailTextLabel?.font = UIFont(name: font, size: 15)
        
        cell.textLabel!.text = DirectionsData[indexPath.row].Manuver
        cell.detailTextLabel?.text = "Distance: \(DirectionsData[indexPath.row].Distance)"
//Time: \(DirectionsData[indexPath.row].Time) \n
        cell.backgroundColor = standardBackgroundColor
        cell.textLabel?.textColor = standardContrastColor

        return cell
    }
    
    @objc func closeView(gesture: UISwipeGestureRecognizer) {
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.popViewController(animated: false)
    }
    
}
