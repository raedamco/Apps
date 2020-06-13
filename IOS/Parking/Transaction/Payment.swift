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
import Firebase
import FirebaseFunctions

extension ParkViewController: PKPaymentAuthorizationViewControllerDelegate {
    
    func proccessPayment(){
        let paymentNetworks = [PKPaymentNetwork.amex, .discover, .masterCard, .visa]

        if PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: paymentNetworks) {
            let request = PKPaymentRequest()
            request.currencyCode = "USD"
            request.countryCode = "US"
            request.merchantIdentifier = "merchant.parking"
            request.merchantCapabilities = PKMerchantCapability.capability3DS
            request.supportedNetworks = paymentNetworks
            
            if TransactionData.count > 0 {
                let paymentItem = PKPaymentSummaryItem.init(label: "Parking at \(SelectedParkingData[indexPath.row].Organization)", amount: NSDecimalNumber(value: Double(TransactionData[indexPath.row].Amount)))
                request.paymentSummaryItems = [paymentItem]
            }else{
                let totalAmount = NSDecimalNumber(value: Double(mainTimer.inInt) * Double(truncating: SelectedParkingData[indexPath.row].Price))
                let paymentItem = PKPaymentSummaryItem.init(label: "Parking at \(SelectedParkingData[indexPath.row].Organization)", amount: totalAmount)
                request.paymentSummaryItems = [paymentItem]
            }
            
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
            Server.requestCharge(idempotencyKey: stripeToken.tokenId)
            
        }
        
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
    }
    
    @objc func transactionCompleted(notification: NSNotification){
        TransactionData.removeAll()
        dismiss(animated: true, completion: nil)
        self.bulletinManagerPaymentComplete.allowsSwipeInteraction = false
        self.bulletinManagerPaymentComplete.showBulletin(above: self)
        
        setupNavigationBar(LargeText: true, Title: "Pay", SystemImageR: true, ImageR: true, ImageTitleR: "ellipsis", TargetR: self, ActionR: #selector(moreInfo), SystemImageL: false, ImageL: false, ImageTitleL: "", TargetL: nil, ActionL: nil)
        timeLabel.removeFromSuperview()
        currentLocation.removeFromSuperview()
        paymentButton.removeFromSuperview()
        
        // MARK: SHOW SCREEN TO USER INDICATING THEY HAVE FINISHED TRANSACTION -> BUTTON TO GO TO TRANSACTION DETAILS
        
        self.view.addSubview(checkInButton)
        
        checkInButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        checkInButton.centerYAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -180).isActive = true
        checkInButton.widthAnchor.constraint(equalToConstant: self.view.frame.width - 110).isActive = true
        checkInButton.heightAnchor.constraint(equalToConstant: (self.view.frame.width - 60)/5.5).isActive = true
    }
    
    @objc func resetTimer(notification: NSNotification){
        mainTimer.reset()
    }
    
}

