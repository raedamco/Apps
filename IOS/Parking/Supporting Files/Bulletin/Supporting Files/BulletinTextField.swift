/**
 *  BulletinBoard
 *  Copyright (c) 2017 - present Alexis Aubry. Licensed under the MIT license.
 */

import UIKit
import BLTNBoard
import Firebase

class TextFieldBulletinPage: FeedbackPageBLTNItem {
    
    @objc public var textField: UITextField!
    @objc public var textInputHandler: ((BLTNActionItem, String?) -> Void)? = nil
    
    override func makeViewsUnderDescription(with interfaceBuilder: BLTNInterfaceBuilder) -> [UIView]? {
        textField = interfaceBuilder.makeTextField(placeholder: "Email", returnKey: .done, delegate: self)
       
        textField.font = UIFont(name: font, size: 18)
        textField.keyboardType = .emailAddress
        textField.textAlignment = NSTextAlignment.left
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.backgroundColor = standardBackgroundColor
        textField.adjustsFontSizeToFitWidth = true
        textField.autocorrectionType = UITextAutocorrectionType.no
        textField.autocapitalizationType = UITextAutocapitalizationType.none
        textField.textColor = standardContrastColor
        textField.keyboardAppearance = UIKeyboardAppearance.default
        textField.setLeftPaddingPoints(10)
        textField.setRightPaddingPoints(10)
        
        textField.borderStyle = .none
        textField.layer.masksToBounds = false
        textField.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        textField.layer.shadowOpacity = 1.0
        textField.layer.shadowRadius = 0.0
        
        textField.layer.shadowColor = UIColor.white.cgColor
        textField.layer.backgroundColor = standardBackgroundColor.cgColor
        textField.layer.shadowColor = UIColor.darkGray.cgColor

        return [textField]
    }
    
    override func tearDown() {
        super.tearDown()
        textField?.delegate = nil
    }
    
    override func actionButtonTapped(sender: UIButton) {
        textField.resignFirstResponder()
        super.actionButtonTapped(sender: sender)
    }
    
}

extension TextFieldBulletinPage: UITextFieldDelegate {
    
    @objc open func isInputValid(text: String?) -> Bool {
        if text == nil || text!.isEmpty {
            return false
        }
        return true
    }
    
    func isValidEmail(text: String?) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: text)
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    

    func textFieldDidEndEditing(_ textField: UITextField) {
        if isInputValid(text: textField.text){
            if isValidEmail(text: textField.text){
                textInputHandler?(self, textField.text)
//                sendTransactionEmail(Email: textField.text)
            }else{
                descriptionLabel!.textColor = .red
                descriptionLabel!.text = "You must enter a valid email to continue."
                textField.backgroundColor = UIColor.red.withAlphaComponent(0.3)
            }
        }else{
            descriptionLabel!.textColor = .red
            descriptionLabel!.text = "You must enter an email to continue."
            textField.backgroundColor = UIColor.red.withAlphaComponent(0.3)
        }
    }
    
    func sendTransactionEmail(Email: String!){
        functions.httpsCallable("getUserData").call(["UUID": UserData[indexPath.row].UID, "EMAIL": Email, "NAME": UserData[indexPath.row].Name]) { (result, error) in
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    functionError = true
                    let message = error.localizedDescription
                    errorMessage = "\(message)"
                }
                functionError = true
            }else{
                functionError = false
            }
        }
    }

}
