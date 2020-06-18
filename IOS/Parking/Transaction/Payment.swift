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

extension ParkViewController: PKPaymentAuthorizationViewControllerDelegate { //, STPApplePayContextDelegate //
    
    func proccessPayment(){
        Server.requestTotal()
        isRunning = !isRunning
    }
    
    @objc func finishProcessing(notification: NSNotification){
        let paymentNetworks = [PKPaymentNetwork.amex, .discover, .masterCard, .visa]
        let paymentItem = PKPaymentSummaryItem.init(label: "For Parking at \(SelectedParkingData[indexPath.row].Organization)", amount: NSDecimalNumber(value: TransactionData[indexPath.row].Amount))
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
    }
    
//    func applePayContext(_ context: STPApplePayContext, didCreatePaymentMethod paymentMethod: STPPaymentMethod, paymentInformation: PKPayment, completion: @escaping STPIntentClientSecretCompletionBlock) {
//        let clientSecret = ... // Retrieve the PaymentIntent client secret from your backend (see Server-side step above)
//        // Call the completion block with the client secret or an error
//        completion(clientSecret, error);
//    }
//
//    func applePayContext(_ context: STPApplePayContext, didCompleteWith status: STPPaymentStatus, error: Error?) {
//          switch status {
//        case .success:
//            // Payment succeeded, show a receipt view
//            break
//        case .error:
//            // Payment failed, show the error
//            break
//        case .userCancellation:
//            // User cancelled the payment
//            break
//        @unknown default:
//            fatalError()
//        }
//    }

    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        STPAPIClient.shared().createToken(with: payment) { (stripeToken, error) in
            guard error == nil, let stripeToken = stripeToken else {
               return print(error!)
            }
            Server.requestCharge(idempotencyKey: stripeToken.tokenId)
        }
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
    }
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        //verify transaction before dimissing
        dismiss(animated: true, completion: nil)
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

