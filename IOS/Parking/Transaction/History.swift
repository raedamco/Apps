//
//  TransactionHistory.swift
//  Parking
//
//  Created by Omar on 3/29/20.
//  Copyright © 2020 Theory Parking. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import Stripe
import BLTNBoard

class TransactionHistory: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let tableView = UITableView()
    
    // BLTNBoard START
    let backgroundStyles = BackgroundStyles()
    var currentBackground = (name: "Dimmed", style: BLTNBackgroundViewStyle.dimmed)
    
    lazy var emptyAlert: BLTNItemManager = {
        let page = BulletinDataSource.noHistory()
        return BLTNItemManager(rootItem: page)
    }()
    // BLTNBoard END
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createViewLayout()
        tableView.setNeedsUpdateConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setNeedsStatusBarAppearanceUpdate()
        checkConnection()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationbarAttributes(Hidden: false, Translucent: false)
        NotificationCenter.default.addObserver(self, selector: #selector(closeView(notification:)), name: NSNotification.Name(rawValue: "closeTView"), object: nil)
        if TransactionsData.isEmpty {
            self.emptyAlert.allowsSwipeInteraction = false
            self.emptyAlert.showBulletin(above: self)
        }
    }

    func createViewLayout(){
        view.backgroundColor = standardBackgroundColor
        setupNavigationBar(LargeText: true, Title: "History", SystemImageR: false, ImageR: false, ImageTitleR: "", TargetR: nil, ActionR: nil, SystemImageL: true, ImageL: true, ImageTitleL: "xmark", TargetL: self, ActionL: #selector(self.closeView(gesture:)))

        tableView.register(transactionHistoryCell.self, forCellReuseIdentifier: "paymentCell")
        tableView.isScrollEnabled = true
        tableView.allowsSelection = true
        tableView.rowHeight = 150
        tableView.separatorColor = standardContrastColor.withAlphaComponent(0.5)
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
        return TransactionsData.count
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "paymentCell", for: indexPath) as! transactionHistoryCell
        cell.textLabel?.font = UIFont(name: font, size: 20)
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        cell.accessoryView?.tintColor = standardContrastColor
        cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        
        cell.LocationLabel.text = TransactionsData[indexPath.row].Organization
        cell.DateLabel.text = "Date: " + formatter.string(from: TransactionsData[indexPath.row].Day)
        cell.CostLabel.text = "Cost $" + String(format:"%.2f", Double(truncating: TransactionsData[indexPath.row].Cost)) + " | $" + String(format:"%.2f", Double(truncating: TransactionsData[indexPath.row].Cost)) + "/min"
        cell.DurationLabel.text = "Duration: " + String(describing: TransactionsData[indexPath.row].Duration)

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    @objc func closeView(gesture: UISwipeGestureRecognizer) {
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.pushViewController(PaymentViewController(), animated: false)
    }
    
    @objc func closeView(notification: NSNotification){
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.pushViewController(PaymentViewController(), animated: false)
    }
}


