//
//  TimerClass.swift
//  Parking
//
//  Created by Omar on 3/28/20.
//  Copyright © 2020 Theory Parking. All rights reserved.
//

import Foundation

var mainTimer = customTimer()
var mainNSTimer = Timer()


class customTimer {
    var startTime: TimeInterval?
    
    var currentTime: TimeInterval {
        return NSDate.timeIntervalSinceReferenceDate
    }
    
    var elapsedTime: TimeInterval {
        return currentTime - startTime!
    }
    
    var freezedTime: TimeInterval = 0.0
    
    var inString: String {
        return elapsedTime.asString(style: .abbreviated)
    }
    
    var inInt: Int {
        let time = elapsedTime
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60
        let totalDuration = (hours + minutes)
        return totalDuration
    }
    
    func start() {
        if (TransactionData.count > 0) && (TransactionData[indexPath.row].Current) {
            startTime = TransactionData[indexPath.row].Start.timeIntervalSinceReferenceDate
        }else if startTime == nil {
            startTime = currentTime
        } else {
            startTime = currentTime - freezedTime
        }
        
    }
    
    func reset() {
        startTime = nil
    }
    
    func pause() {
        freezedTime = elapsedTime
    }
}
