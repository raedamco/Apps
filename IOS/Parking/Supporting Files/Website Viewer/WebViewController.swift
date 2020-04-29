//
//  WebViewController.swift
//  Parking
//
//  Created by Omar on 9/23/19.
//  Copyright © 2019 Theory Parking. All rights reserved.
//


import Foundation
import UIKit
import WebKit

class webViewScreen: UIViewController, UIWebViewDelegate{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createScreenLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.largeTitleTextAttributes = largeTitleAttributes
        self.navigationController?.navigationBar.titleTextAttributes = titleAttributes
        self.navigationItem.leftBarButtonItem?.setTitleTextAttributes(buttonAttributes, for: UIControl.State())
        self.navigationItem.rightBarButtonItem?.setTitleTextAttributes(buttonAttributes, for: UIControl.State())
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setNeedsStatusBarAppearanceUpdate()
        checkConnection()
    }
    
    func createScreenLayout(){
        self.navigationItem.title = webViewLabel
        self.navigationItem.rightBarButtonItem = createBarButtonItem(SystemImage: false, Image: false, Title: "", Target: nil, Action: nil)
        self.navigationItem.leftBarButtonItem = createBarButtonItem(SystemImage: true, Image: true, Title: "xmark", Target: self, Action: #selector(self.closeView(gesture:)))
        self.navigationController?.navigationBar.prefersLargeTitles = false
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.view.backgroundColor = standardBackgroundColor
        self.navigationController?.navigationBar.barTintColor = standardBackgroundColor
        self.navigationController?.navigationBar.tintColor = standardContrastColor
        
        let webView: WKWebView = {
            let view = WKWebView()
            view.scrollView.contentInset = UIEdgeInsets.zero
            view.backgroundColor = standardBackgroundColor
            view.load(URLRequest(url: NSURL(string: webLink)! as URL))
            return view
        }()
        
        webView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height - (UITabBar.appearance().frame.height + Screen.statusBarHeight))
        view.addSubview(webView)
    }
    
    @objc func openWebsite(){
        let url = NSURL(string: webLink)!
        UIApplication.shared.open(url as URL, options:convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
    }
    
    @objc func closeView(gesture: UISwipeGestureRecognizer) {
        UIView.animate(withDuration: 0.10, animations: {
            self.view.alpha = 0
        }, completion: { (false) in
            self.tabBarController?.tabBar.isHidden = false
            self.dismiss(animated: false, completion: nil)
        })
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
