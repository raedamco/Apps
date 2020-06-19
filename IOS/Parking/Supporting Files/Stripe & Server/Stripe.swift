//
//  Stripe.swift
//  Theory Parking
//
//  Created by Omar on 6/16/20.
//  Copyright © 2020 Theory Parking. All rights reserved.
//

import Foundation
import Stripe
import Alamofire

class MyAPIClient: NSObject, STPCustomerEphemeralKeyProvider {
    enum APIError: Error {
        case unknown
        
        var localizedDescription: String {
            switch self {
            case .unknown:
                return "Unknown error"
            }
        }
    }

    static let sharedClient = MyAPIClient()
    var baseURLString: String? = "https://us-central1-theory-parking.cloudfunctions.net"
    var baseURL: URL {
        if let urlString = self.baseURLString, let url = URL(string: urlString) {
            return url
        } else {
            fatalError()
        }
    }

    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        let url = self.baseURL.appendingPathComponent("ephemeral_keys")
        AF.request(url, method: .post, parameters: ["apiVersion": apiVersion,"customer_id":UserData[indexPath.row].StripeID]).validate(statusCode: 200..<300).responseJSON { responseJSON in
            switch responseJSON.result {
            case .success(let json): completion(json as? [String: AnyObject], nil)
//                print(json)
            case .failure(let error): completion(nil, error)
//                print(error)
            }
        }
    }

}

