//
//  Classes.swift
//  Parking
//
//  Created by Omar on 11/11/19.
//  Copyright © 2019 Theory Parking. All rights reserved.
//

import Foundation
import UIKit

class filterCell: UITableViewCell {
    let slider = createSlider(Min: 0,Max: 100, Color: standardContrastColor)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class transactionHistoryCell: UITableViewCell {
    let TIDLabel = createLabel(LabelText: "", TextColor: standardContrastColor, FontName: standardFont, FontSize: 19, TextAlignment: .left, TextBreak: .byWordWrapping, NumberOfLines: 0)
    let CostLabel = createLabel(LabelText: "", TextColor: standardContrastColor, FontName: standardFont, FontSize: 19, TextAlignment: .left, TextBreak: .byWordWrapping, NumberOfLines: 0)
    let DurationLabel = createLabel(LabelText: "", TextColor: standardContrastColor, FontName: standardFont, FontSize: 19, TextAlignment: .left, TextBreak: .byWordWrapping, NumberOfLines: 0)
    let DateLabel = createLabel(LabelText: "", TextColor: standardContrastColor, FontName: standardFont, FontSize: 19, TextAlignment: .left, TextBreak: .byWordWrapping, NumberOfLines: 0)
    let LocationLabel = createLabel(LabelText: "", TextColor: standardContrastColor, FontName: standardFont, FontSize: 19, TextAlignment: .left, TextBreak: .byWordWrapping, NumberOfLines: 0)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.addSubview(LocationLabel)
        self.addSubview(DateLabel)
        self.addSubview(CostLabel)
        self.addSubview(DurationLabel)
        self.addSubview(TIDLabel)
        
        LocationLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 15).isActive = true
        LocationLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 15).isActive = true
        
        DateLabel.topAnchor.constraint(equalTo: self.LocationLabel.bottomAnchor, constant: 5).isActive = true
        DateLabel.leftAnchor.constraint(equalTo: self.LocationLabel.leftAnchor).isActive = true
        
        CostLabel.topAnchor.constraint(equalTo: self.DateLabel.bottomAnchor, constant: 5).isActive = true
        CostLabel.leftAnchor.constraint(equalTo: self.DateLabel.leftAnchor).isActive = true
        
        DurationLabel.topAnchor.constraint(equalTo: self.CostLabel.bottomAnchor, constant: 5).isActive = true
        DurationLabel.leftAnchor.constraint(equalTo: self.CostLabel.leftAnchor).isActive = true
        
        TIDLabel.topAnchor.constraint(equalTo: self.DurationLabel.bottomAnchor, constant: 5).isActive = true
        TIDLabel.leftAnchor.constraint(equalTo: self.DurationLabel.leftAnchor).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


