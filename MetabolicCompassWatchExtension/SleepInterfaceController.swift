//
//  SleepInterfaceController.swift
//  Circator
//
//  Created by Mariano Pennini on 3/9/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit
import SwiftDate

struct sleepTimesVariables {
    var sleepBegin: Int
}
var sleepTimesStruc = sleepTimesVariables(sleepBegin:2)

class SleepInterfaceController: WKInterfaceController {
    
    @IBOutlet var enterButton: WKInterfaceButton!
    @IBOutlet var sleepPicker: WKInterfacePicker!

    var sleep = 0
    func awakeWithContext(context: AnyObject?) {
        super.awake(withContext: context)
        var tempItems: [WKPickerItem] = []
        for i in 0...48 {
            let item = WKPickerItem()
            item.contentImage = WKImage(imageName: "Time\(i)")
            tempItems.append(item)
        }

        let thisRegion = DateInRegion()
        var beginTimePointer = 24
        let calendar = Calendar.current
        var beginDate = Date()
//        let beginComponents = calendar.components([.Year, .Month, .Day, .Hour, .Minute], fromDate: beginDate)
        let beginComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: beginDate)
        if beginComponents.minute! < 15 {
            beginTimePointer = 2*beginComponents.hour!
        } else {
            beginTimePointer = 2*beginComponents.hour! + 1
        }
        sleepPicker.setItems(tempItems)
        sleepPicker.setSelectedItemIndex(beginTimePointer-16)
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    @IBAction func onSleepEntry(value: Int) {
        sleep = value
    }
    @IBAction func sleepSaveButton() {
        sleepTimesStruc.sleepBegin = sleep
        pushController(withName: "SleepTimesInterfaceController", context: self)
    }
    }



