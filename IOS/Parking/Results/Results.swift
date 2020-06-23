//
//  ResultView.swift
//  Parking
//
//  Created by Omar on 11/9/19.
//  Copyright © 2019 Theory Parking. All rights reserved.
//

import UIKit
import Firebase
import BLTNBoard

class ResultView: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var tableView = UITableView()
    var sections = [["Near by Parking"]]
    
    // BLTNBoard START
    let backgroundStyles = BackgroundStyles()
    var currentBackground = (name: "Dimmed", style: BLTNBackgroundViewStyle.dimmed)
    
    lazy var bulletinManagerNotifyNoResults: BLTNItemManager = {
        let page = BulletinDataSource.makeNoResults()
        return BLTNItemManager(rootItem: page)
    }()
    // BLTNBoard END
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createViewLayout()
        NotificationCenter.default.addObserver(self, selector: #selector(removeView(notification:)), name: NSNotification.Name(rawValue: "closeView"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationbarAttributes(Hidden: false, Translucent: false)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTable(notification:)), name: NSNotification.Name(rawValue: "reloadResultTable"), object: nil)
    }
    
    func createViewLayout(){
        view.backgroundColor = standardBackgroundColor
        setupNavigationBar(LargeText: true, Title: destinationName, SystemImageR: true, ImageR: true, ImageTitleR: "line.horizontal.3.decrease.circle", TargetR: self, ActionR: #selector(self.filterResults), SystemImageL: true, ImageL: true, ImageTitleL: "xmark", TargetL: self, ActionL: #selector(self.closeView(gesture:)))
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "resultCell")
        
        tableView.isScrollEnabled = true
        tableView.allowsSelection = true
        tableView.rowHeight = 170
        tableView.separatorColor = .darkGray
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
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ParkingData.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = standardBackgroundColor
        let headerLabel = UILabel(frame: CGRect(x: 15, y: -1, width: tableView.frame.width, height: 25))
        headerLabel.font = UIFont(name: font, size: 20)
        headerLabel.textColor = standardContrastColor
        headerLabel.text = self.tableView(tableView, titleForHeaderInSection: section)
        headerLabel.sizeToFit()
        headerView.addSubview(headerLabel)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "\(sections[section][indexPath.row])"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let PName = ParkingData[indexPath.row].Name
        let PAvailable = String(describing: ParkingData[indexPath.row].Available) + "/" + String(describing: ParkingData[indexPath.row].Capacity) + " Spots Available"
        let PPrice = "$" + String(describing: ParkingData[indexPath.row].Prices) + "/min"
        let PDistance = "Distance from parking structure to intended destination"
        let CTextDetil = PName + "\n" + PAvailable + "\n" + PPrice
        
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "resultCell")
        cell.textLabel?.font = UIFont(name: font, size: 18)
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        cell.textLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.textLabel?.numberOfLines = 3
        cell.detailTextLabel?.numberOfLines = 4
        cell.textLabel!.text = ParkingData[indexPath.row].Organization
        cell.detailTextLabel?.text = CTextDetil
        cell.detailTextLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.detailTextLabel?.textColor = standardContrastColor
        cell.detailTextLabel?.font = UIFont(name: font, size: 17)
        cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        cell.backgroundColor = standardBackgroundColor
        cell.textLabel?.textColor = standardContrastColor
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true) {
            self.tabBarController?.tabBar.isHidden = false
            self.navigationController?.popViewController(animated: true)
            let selectedRow = ParkingData[indexPath.row]
//            Server.requestSpot()
            SelectedParkingData.append(SelectedParking(Location: selectedRow.Location, Name: selectedRow.Name, Types: selectedRow.Types, Organization: selectedRow.Organization, Price: selectedRow.Prices, Floor: "Floor " + ParkingData[indexPath.row].Floors.first!, Spot: "Spot " + ParkingData[indexPath.row].Spots.first!, CompanyStripeID: selectedRow.CompanyStripeID))
        }
        ParkingData.removeAll()
        NotificationCenter.default.post(name: NSNotification.Name("confirmRoute"), object: nil)
    }
    
    @objc func filterResults(){
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.pushViewController(FilterView(), animated: false)
    }
    
    @objc func closeView(gesture: UISwipeGestureRecognizer) {
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: {
            ParkingData.removeAll()
        })
    }
    
    @objc func reloadTable(notification: NSNotification) {
        self.tableView.reloadData()
        self.tableView.reloadInputViews()
        self.tableView.setNeedsUpdateConstraints()
        self.reloadInputViews()
        self.view.needsUpdateConstraints()
        self.tableView.cellForRow(at: indexPath)?.reloadInputViews()
        setNeedsFocusUpdate()
        
        if ParkingData.count == 0 {
            self.bulletinManagerNotifyNoResults.allowsSwipeInteraction = false
            self.bulletinManagerNotifyNoResults.showBulletin(above: self)
        }
        
    }

    @objc func removeView(notification: NSNotification) {
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: {
            ParkingData.removeAll()
        })
    }
    
}
