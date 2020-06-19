//
//  Payment.swift
//  Parking
//
//  Created by Omar on 3/28/20.
//  Copyright © 2020 Theory Parking. All rights reserved.
//

import Foundation
import Stripe
import PassKit
import Alamofire
import Firebase

extension ParkViewController: PKPaymentAuthorizationViewControllerDelegate, STPApplePayContextDelegate {
    
    func proccessPayment(){
        Server.requestTotal()
        isRunning = !isRunning
    }
    
    @objc func finishProcessing(notification: NSNotification){
        let merchantIdentifier = "merchant.parking"
        let paymentRequest = Stripe.paymentRequest(withMerchantIdentifier: merchantIdentifier, country: "US", currency: "USD")

        let paymentItem = PKPaymentSummaryItem.init(label: "For Parking at \(SelectedParkingData[indexPath.row].Organization)", amount: NSDecimalNumber(value: TransactionData[indexPath.row].Amount))
        paymentRequest.paymentSummaryItems = [paymentItem]
        
        if let applePayContext = STPApplePayContext(paymentRequest: paymentRequest, delegate: self) {
            applePayContext.presentApplePay(on: self)
        }
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        STPAPIClient.shared().createToken(with: payment) { (stripeToken, error) in
            guard error == nil, let stripeToken = stripeToken else {
               return print(error!)
            }
            self.idempotencyKey = stripeToken.tokenId
        }
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
    }
    
    func applePayContext(_ context: STPApplePayContext, didCreatePaymentMethod paymentMethod: STPPaymentMethod, paymentInformation: PKPayment, completion: @escaping STPIntentClientSecretCompletionBlock) {
        var clientSecret = String()
        
        DispatchQueue.main.async {
            let url = self.baseURL.appendingPathComponent("createCharge")
            let requiredParameters = ["UID": UserData[indexPath.row].UID,
                                      "IdempotencyKey": self.idempotencyKey,
                                      "Details": "Parking at \(SelectedParkingData[indexPath.row].Organization)"
                                     ]
            
            AF.request(url, method: .post, parameters:requiredParameters).validate(statusCode: 200..<300).responseJSON { responseJSON in
                switch responseJSON.result {
                    case .success(let json):
                        let responseJSON = json as? [String: AnyObject]
                        guard let Completed = responseJSON?["Completed"] as? Bool else { return }
                        clientSecret = responseJSON?["ClientSecret"] as! String
                        print("SECRET", clientSecret)
                        completion(clientSecret, nil)
                        if Completed {
                             NotificationCenter.default.post(name: NSNotification.Name("endTransaction"), object: nil)
                             NotificationCenter.default.post(name: NSNotification.Name("cancelRoute"), object: nil)
                             NotificationCenter.default.post(name: NSNotification.Name("resetTimer"), object: nil)
                        }
                    case .failure(let error): print(error.localizedDescription)
                    completion(clientSecret, error)
                }
            }
        }
    }

    func applePayContext(_ context: STPApplePayContext, didCompleteWith status: STPPaymentStatus, error: Error?) {
        switch status {
            case .success:
                print("successful transaction")
                break
            case .error:
                print(error?.localizedDescription as Any)
                break
            case .userCancellation:
                print("user stopped transaction")
                isRunning = !isRunning
                break
            @unknown default:
                fatalError()
        }
    }
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        //verify transaction before dimissing
//        dismiss(animated: true, completion: nil)
    }
    
    @objc func transactionCompleted(notification: NSNotification){
        self.bulletinManagerPaymentComplete.allowsSwipeInteraction = false
        self.bulletinManagerPaymentComplete.showBulletin(above: self)
    }
    
    @objc func resetTimer(notification: NSNotification){
        mainTimer.reset()
        dismiss(animated: true, completion: nil)
        setupNavigationBar(LargeText: true, Title: "Pay", SystemImageR: true, ImageR: true, ImageTitleR: "ellipsis", TargetR: self, ActionR: #selector(moreInfo), SystemImageL: false, ImageL: false, ImageTitleL: "", TargetL: nil, ActionL: nil)
        timeLabel.removeFromSuperview()
        currentLocation.removeFromSuperview()
        paymentButton.removeFromSuperview()
                
        self.view.addSubview(checkInButton)
        
        checkInButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        checkInButton.centerYAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -180).isActive = true
        checkInButton.widthAnchor.constraint(equalToConstant: self.view.frame.width - 110).isActive = true
        checkInButton.heightAnchor.constraint(equalToConstant: (self.view.frame.width - 60)/5.5).isActive = true
        TransactionData.removeAll()
        self.view.reloadInputViews()
    }
    
    
    
}

