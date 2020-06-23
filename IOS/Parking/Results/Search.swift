//
//  Search.swift
//  Parking
//
//  Created by Omar on 11/11/19.
//  Copyright © 2019 Theory Parking. All rights reserved.
//

import UIKit
import Firebase
import GooglePlaces

protocol LocateOnTheMap{
    func locateWithLongitude(_ lon:Double, andLatitude lat:Double, andTitle title: String)
}

class SearchView: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var tableView = UITableView()
    var sections = [["Near by Parking"]]
    let textField = UITextField()

    var placesClient : GMSPlacesClient?
    var searchResults: [String]!
    var delegate: LocateOnTheMap!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createViewLayout()
        self.placesClient = GMSPlacesClient()
        self.searchResults = Array()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTable(notification:)), name: NSNotification.Name(rawValue: "reloadTable"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationbarAttributes(Hidden: false, Translucent: false)
    }
    
    func createViewLayout(){
        view.backgroundColor = standardBackgroundColor
        setupNavigationBar(LargeText: true, Title: destinationName, SystemImageR: true, ImageR: true, ImageTitleR: "line.horizontal.3.decrease.circle", TargetR: self, ActionR: #selector(self.filterResults), SystemImageL: true, ImageL: true, ImageTitleL: "xmark", TargetL: self, ActionL: #selector(self.closeView(gesture:)))

        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "accountCell")
        tableView.isScrollEnabled = true
        tableView.allowsSelection = true
        tableView.rowHeight = 50
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
        
        
        textField.font = UIFont(name: font, size: 20)
        textField.keyboardType = .default
        textField.returnKeyType = .search
        textField.isSecureTextEntry = false
        textField.textAlignment = NSTextAlignment.left
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.backgroundColor = standardBackgroundColor
        textField.adjustsFontSizeToFitWidth = true
        textField.autocorrectionType = UITextAutocorrectionType.no
        textField.autocapitalizationType = UITextAutocapitalizationType.none
        textField.attributedPlaceholder = NSAttributedString(string: "Enter your Destination", attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray, NSAttributedString.Key.font: UIFont(name: font, size: 20)!])
        textField.textColor = standardContrastColor
        textField.keyboardAppearance = UIKeyboardAppearance.default
        textField.setLeftPaddingPoints(10)
        textField.setRightPaddingPoints(10)
        textField.setBottomBorderSelected()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchResults.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = standardBackgroundColor
        headerView.addSubview(textField)
        textField.centerXAnchor.constraint(equalTo: headerView.centerXAnchor).isActive = true
        textField.widthAnchor.constraint(equalToConstant: self.view.frame.width - 80).isActive = true
        textField.frame = CGRect(x: 15, y: -1, width: tableView.frame.width, height: 25)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "\(sections[section][indexPath.row])"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "accountCell", for: indexPath as IndexPath)
        cell.textLabel?.font = UIFont(name: font, size: 18)
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        cell.textLabel!.text = self.searchResults[indexPath.row]
        cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        cell.backgroundColor = standardBackgroundColor
        cell.textLabel?.textColor = standardContrastColor
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 1
        self.dismiss(animated: true, completion: nil)
        // 2
        let urlpath = "https://maps.googleapis.com/maps/api/geocode/json?address=\(self.searchResults[indexPath.row])&sensor=false".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        let url = URL(string: urlpath!)
        // print(url!)
        let task = URLSession.shared.dataTask(with: url! as URL) { (data, response, error) -> Void in
            // 3
            
            do {
                if data != nil{
                    let dic = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableLeaves) as! NSDictionary
                    
                    let lat = (((((dic.value(forKey: "results") as! NSArray).object(at: 0) as! NSDictionary).value(forKey: "geometry") as! NSDictionary).value(forKey: "location") as! NSDictionary).value(forKey: "lat")) as! Double
                    
                    let lon = (((((dic.value(forKey: "results") as! NSArray).object(at: 0) as! NSDictionary).value(forKey: "geometry") as! NSDictionary).value(forKey: "location") as! NSDictionary).value(forKey: "lng")) as! Double
                    // 4
                    self.delegate.locateWithLongitude(lon, andLatitude: lat, andTitle: self.searchResults[indexPath.row])
                }
                
            }catch {
                print("Error")
            }
        }
        // 5
        task.resume()
    }
    
    func reloadDataWithArray(_ array:[String]){
        self.searchResults = array
        self.tableView.reloadData()
    }
    
    @objc func filterResults(){
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.pushViewController(FilterView(), animated: false)
    }
    
    @objc func closeView(gesture: UISwipeGestureRecognizer) {
        self.tabBarController?.tabBar.isHidden = false
        //ParkingData.removeAll()
        self.dismiss(animated: true, completion: nil)
    }
    
    func showResults(string:String){
//        var input = GInput()
//        input.keyword = string
//        GoogleApi.shared.callApi(input: input) { (response) in
//            if response.isValidFor(.autocomplete) {
//                DispatchQueue.main.async {
//                    self.autocompleteResults = response.data as! [GApiResponse.Autocomplete]
//                    self.tableView.reloadData()
//                }
//            }
//        }
    }
    
    @objc func reloadTable(notification: NSNotification) {
        tableView.reloadData()
        tableView.reloadInputViews()
    }
    
    @objc func searchLocation(){
       
    }

}

