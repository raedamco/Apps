//
//  Payment.swift
//  Parking
//
//  Created by Omar on 3/28/20.
//  Copyright © 2020 Theory Parking. All rights reserved.
//

import Foundation
import PassKit
import Stripe
import Alamofire

extension ParkViewController: PKPaymentAuthorizationViewControllerDelegate {
    
    func proccessPayment(){
        let paymentNetworks = [PKPaymentNetwork.amex, .discover, .masterCard, .visa]
        let paymentItem = PKPaymentSummaryItem.init(label: "For PSU Parking", amount: NSDecimalNumber(value: Double(self.mainTimer.inInt) * Double(truncating: NearByParking[indexPath.row].Prices)))

        if PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: paymentNetworks) {
            let request = PKPaymentRequest()
            request.currencyCode = "USD"
            request.countryCode = "US"
            request.merchantIdentifier = "merchant.parking"
            request.merchantCapabilities = PKMerchantCapability.capability3DS
            request.supportedNetworks = paymentNetworks
            request.paymentSummaryItems = [paymentItem]
            
            guard let paymentVC = PKPaymentAuthorizationViewController(paymentRequest: request) else {
                self.bulletinManagerPaymentError.allowsSwipeInteraction = false
                self.bulletinManagerPaymentError.showBulletin(above: self)
            return
            }
            
            paymentVC.delegate = self
            self.present(paymentVC, animated: true, completion: nil)
        }
        isRunning = !isRunning
    }

    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        dismiss(animated: true, completion: nil)
        isRunning = !isRunning
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        
        STPAPIClient.shared().createToken(with: payment) { (stripeToken, error) in
            guard error == nil, let stripeToken = stripeToken else {
                print(error!)
                return
            }
            
            let amount = round((Double(self.mainTimer.inInt) * Double(truncating: NearByParking[indexPath.row].Prices)) * 100)
            print(amount)
            functions.httpsCallable("createCharge").call(["amount": amount,
                                                          "customer": UserData[indexPath.row].StripeID,
                                                          "name": UserData[indexPath.row].Name,
                                                          "idempotencyKey": stripeToken.tokenId,
                                                          "details": NearByParking[indexPath.row].Organization,
                                                          "currency": "usd"]) { (result, error) in
            }
        }
        
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))

        dismiss(animated: true, completion: nil)

        self.bulletinManagerPaymentComplete.allowsSwipeInteraction = false
        self.bulletinManagerPaymentComplete.showBulletin(above: self)
        self.transactionCompleted()
        endTimer()
    }

    func transactionCompleted(){
        setupNavigationBar(LargeText: true, Title: "Pay", SystemImageR: true, ImageR: true, ImageTitleR: "ellipsis", TargetR: self, ActionR: #selector(moreInfo), SystemImageL: false, ImageL: false, ImageTitleL: "", TargetL: nil, ActionL: nil)
        timeLabel.removeFromSuperview()
        currentLocation.removeFromSuperview()
        paymentButton.removeFromSuperview()
        
        self.view.addSubview(checkInButton)
        
        checkInButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        checkInButton.centerYAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -125).isActive = true
        checkInButton.widthAnchor.constraint(equalToConstant: self.view.frame.width - 110).isActive = true
        checkInButton.heightAnchor.constraint(equalToConstant: (self.view.frame.width - 60)/5.5).isActive = true
    }
    
    func saveTransaction(){
        // MARK: SAVE TRANSACTION TO FIREBASE
    }
    
    
    @objc func resetTimer(notification: NSNotification){
        mainTimer.reset()
    }
    
    func createStripeCharge(){
        
    }
    
}

