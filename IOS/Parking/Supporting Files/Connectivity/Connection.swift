//
//  Connection.swift
//  Parking
//
//  Created by Omar on 9/8/19.
//  Copyright © 2019 WAKED. All rights reserved.
//

import Foundation
import Alamofire
import UIKit

class Connectivity {
    class var isConnectedToInternet:Bool {
        return NetworkReachabilityManager()!.isReachable
    }
}

func checkConnection(){
    if Connectivity.isConnectedToInternet == false{
        //UIApplication.shared.keyWindow!.rootViewController = ConnectivityViewController()
    }else{
        //Dismiss connectivity view
    }
}


extension UIView {
    private func addBorderUtility(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, color: UIColor) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: x, y: y, width: width, height: height)
        layer.addSublayer(border)
    }

}
