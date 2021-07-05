//
//  TabBarsController.swift
//  Parking
//
//  Created by Omar on 9/23/19.
//  Copyright © 2019 Theory Parking. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let homeTab = HomeViewController()
//        let parkTab = ParkViewController()
        let settingsTab = SettingsViewController()
        
        homeTab.tabBarItem = UITabBarItem(title: "", image: UIImage(systemName: "magnifyingglass"), tag: 0)
//        parkTab.tabBarItem = UITabBarItem(title: "", image: UIImage(systemName: "timer"), tag: 1)
        settingsTab.tabBarItem = UITabBarItem(title: "", image: UIImage(systemName: "person"), tag: 1)
        homeTab.tabBarItem.selectedImage = UIImage(systemName: "magnifyingglass.fill")
//        parkTab.tabBarItem.selectedImage = UIImage(systemName: "timer")
        settingsTab.tabBarItem.selectedImage = UIImage(systemName: "person.fill")
        
        let views = [homeTab,settingsTab] //parkTab
        setViewControllers(views, animated: false)
        
        let vc1 = UINavigationController(rootViewController: homeTab)
//        let vc2 = UINavigationController(rootViewController: parkTab)
        let vc3 = UINavigationController(rootViewController: settingsTab)
        viewControllers = [vc1,vc3] //vc2
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setNeedsStatusBarAppearanceUpdate()
        self.view.reloadInputViews()
        setNeedsFocusUpdate()
        checkConnection()
    }
    

}

