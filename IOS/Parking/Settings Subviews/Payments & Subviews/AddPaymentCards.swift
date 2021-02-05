//
//  AddPaymentCards.swift
//  Theory Parking
//
//  Created by Omar on 6/16/20.
//  Copyright © 2020 Theory Parking. All rights reserved.
//

import UIKit
import Stripe
import Alamofire
import BLTNBoard

class CheckoutViewController: UIViewController {
    
    var baseURLString: String? = "https://us-central1-theory-parking.cloudfunctions.net"
    var baseURL: URL {
        if let urlString = self.baseURLString, let url = URL(string: urlString) {
            return url
        } else {
            fatalError()
        }
    }
    
    // BLTNBoard START
    let backgroundStyles = BackgroundStyles()
    var currentBackground = (name: "Dimmed", style: BLTNBackgroundViewStyle.dimmed)
    var errorMessage = String()
    
    lazy var bulletinManagerError: BLTNItemManager = {
        let page = BulletinDataSource.makeErrorPage(message: errorMessage)
        return BLTNItemManager(rootItem: page)
    }()
    
    lazy var bulletinManagerCompleted: BLTNItemManager = {
        let page = BulletinDataSource.makeCompletionPage()
        return BLTNItemManager(rootItem: page)
    }()
    // BLTNBoard END
    
    var setupIntentClientSecret: String?

    lazy var cardTextField: STPPaymentCardTextField = {
        let cardTextField = STPPaymentCardTextField()
        return cardTextField
    }()
    
    lazy var payButton: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = 5
        button.backgroundColor = .systemBlue
        button.titleLabel?.font = UIFont.systemFont(ofSize: 22)
        button.setTitle("Save", for: .normal)
        button.addTarget(self, action: #selector(pay), for: .touchUpInside)
        return button
    }()

    lazy var mandateLabel: UILabel = {
        let mandateLabel = UILabel()
        // See https://stripe.com/docs/strong-customer-authentication/faqs#mandates
        mandateLabel.text = "I authorise Stripe Samples to send instructions to the financial institution that issued my card to take payments from my card account in accordance with the terms of my agreement with you."
        mandateLabel.numberOfLines = 0
        mandateLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        mandateLabel.textColor = .systemGray
        return mandateLabel
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = standardBackgroundColor
        let stackView = UIStackView(arrangedSubviews: [cardTextField, payButton, mandateLabel])
        stackView.axis = .vertical
        stackView.spacing = 25
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leftAnchor.constraint(equalToSystemSpacingAfter: view.leftAnchor, multiplier: 2),
            view.rightAnchor.constraint(equalToSystemSpacingAfter: stackView.rightAnchor, multiplier: 2),
            stackView.topAnchor.constraint(equalToSystemSpacingBelow: view.topAnchor, multiplier: 2.5),
        ])
        getSecret()
    }

    func getSecret() {
        let url = self.baseURL.appendingPathComponent("create_setup_intent")
        AF.request(url, method: .post,parameters: ["customer_id": UserData[indexPath.row].StripeID]).validate(statusCode: 200..<300).responseJSON { responseJSON in
            switch responseJSON.result {
                case .success(let json): print(json)
                    let responseJSON = json as? [String: AnyObject]
                    guard let clientSecret = responseJSON?["clientSecret"] as? String else { return }
                    self.setupIntentClientSecret = clientSecret
                case .failure(let error): print(error)
            }
        }
    }

    
    @objc func pay() {
        guard let setupIntentClientSecret = setupIntentClientSecret else { return }
        // Collect card details
        let cardParams = cardTextField.cardParams
        
        // Collect the customer's email to know which customer the PaymentMethod belongs to.
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.email = UserData[indexPath.row].Email
        
        // Create SetupIntent confirm parameters with the above
        let paymentMethodParams = STPPaymentMethodParams(card: cardParams, billingDetails: billingDetails, metadata: nil)
        let setupIntentParams = STPSetupIntentConfirmParams(clientSecret: setupIntentClientSecret)
        setupIntentParams.paymentMethodParams = paymentMethodParams

        // Complete the setup
        let paymentHandler = STPPaymentHandler.shared()
        paymentHandler.confirmSetupIntent(setupIntentParams, with: self) { status, setupIntent, error in
            switch (status) {
            case .failed:
                self.errorMessage = error?.localizedDescription ?? ""
                self.bulletinManagerError.allowsSwipeInteraction = false
                self.bulletinManagerError.showBulletin(above: self)
                break
            case .succeeded:
                self.bulletinManagerCompleted.allowsSwipeInteraction = false
                self.bulletinManagerCompleted.showBulletin(above: self)
                self.navigationController?.pushViewController(PaymentMethod(), animated: false)
                break
            case .canceled:
                self.errorMessage = "Canceled"
                self.bulletinManagerError.allowsSwipeInteraction = false
                self.bulletinManagerError.showBulletin(above: self)
                break
            @unknown default:
                fatalError()
                break
            }
        }
    }
}

extension CheckoutViewController: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return self
    }
}


