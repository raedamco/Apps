//
//  FilterViewController.swift
//  Parking
//
//  Created by Omar on 11/10/19.
//  Copyright © 2019 Theory Parking. All rights reserved.
//

import UIKit
import Firebase

struct CellData {
    var opened = Bool()
    var title = String()
    var text = Bool()
    var sectionData = [Any]()
}

class FilterView: UITableViewController {
    
    var tableViewData = [CellData]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createViewLayout()
        
        tableViewData = [
                        CellData(opened: false, title: "Sort",text: true, sectionData: ["Price: Low to High","Price: High to Low","Distance: Near to Far","Distance: Far to Near"]),
                        CellData(opened: false, title: "Distance",text: false, sectionData: ["10ft or Less", "50ft or Less", "100ft or Less"]),
                        CellData(opened: false, title: "Price",text: false, sectionData: ["$2/hr or Less","$3-4/hr","$5-9/hr"]),
                        CellData(opened: false, title: "Duration",text: false, sectionData: ["1hr Max","2hr Max","4hr Max","No Constraint"]),
                        CellData(opened: false, title: "Features",text: true, sectionData: ["EV","ADA","Security"])
                        ]
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
        setupNavigationBar(LargeText: true, Title: "Filter", SystemImageR: false, ImageR: false, ImageTitleR: "", TargetR: nil, ActionR: nil, SystemImageL: true, ImageL: true, ImageTitleL: "xmark", TargetL: self, ActionL: #selector(self.closeView(gesture:)))
        

        tableView.register(filterCell.self, forCellReuseIdentifier: "filterCell")
        tableView.isScrollEnabled = true
        tableView.allowsSelection = true
        tableView.rowHeight = 70
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
        if tableViewData[section].opened == true {
            return tableViewData[section].sectionData.count + 1
        }else{
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "filterCell", for: indexPath) as! filterCell
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        cell.backgroundColor = standardBackgroundColor
        cell.textLabel?.textColor = standardContrastColor
        cell.accessoryView?.tintColor = standardContrastColor
        
        
        if (indexPath.row == 0 && tableViewData[indexPath.section].opened) {
            cell.textLabel?.text = tableViewData[indexPath.section].title
            cell.textLabel?.font = UIFont(name: font, size: 18)
            cell.indentationLevel = 0
            cell.accessoryView = UIImageView.init(image: UIImage(systemName: "chevron.down")?.withRenderingMode(.alwaysTemplate))
            cell.accessoryView?.tintColor = standardContrastColor
            
        }else if (indexPath.row == 0 && tableViewData[indexPath.section].opened == false){
            cell.textLabel?.text = tableViewData[indexPath.section].title
            cell.textLabel?.font = UIFont(name: font, size: 18)
            cell.indentationLevel = 0
            cell.accessoryView = UIImageView.init(image: UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate))
            cell.accessoryView?.tintColor = standardContrastColor
            
        }else if (indexPath.row != 0 && tableViewData[indexPath.section].text == true){
            cell.textLabel?.text = tableViewData[indexPath.section].sectionData[indexPath.row - 1] as? String
            cell.textLabel?.font = UIFont(name: font, size: 15)
            cell.indentationLevel = 2
            cell.accessoryView?.isHidden = true
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)

        if (indexPath.row == 0 && tableViewData[indexPath.section].opened == true) {
            tableViewData[indexPath.section].opened = false
            let sections = IndexSet(integer: indexPath.section)
            tableView.reloadSections(sections, with: .none)
        }else if (indexPath.row == 0 && tableViewData[indexPath.section].opened == false){
            tableViewData[indexPath.section].opened = true
            let sections = IndexSet(integer: indexPath.section)
            tableView.reloadSections(sections, with: .none)
        }else if (indexPath.row != 0 && cell?.isSelected == false){
            cell?.accessoryView?.isHidden = false
            cell?.accessoryView = UIImageView.init(image: UIImage(systemName: "checkmark")?.withRenderingMode(.alwaysTemplate))
            cell?.accessoryView?.tintColor = standardContrastColor
        }
        tableView.beginUpdates()
        tableView.endUpdates()
        
    }
    
    @objc func closeView(gesture: UISwipeGestureRecognizer) {
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.popViewController(animated: false)
    }
    
}
