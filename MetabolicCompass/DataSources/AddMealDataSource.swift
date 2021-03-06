//
//  AddMealDataSource.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 6/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

public let typeCellIdentifier = "typeCellIdentifier"
public let whenCellIdentifier = "whenCellIdentifier"
public let durationCellIdentifier = "durationCellIdentifier"
public let pickerCellIdentifier = "pickerCellIdentifier"
public let datePickerCellIdentifier = "datePickerCellIdentifier"
public let startSleepCellIdentifier = "startSleepCellIdentifier"
public let endSleepCellIdentifier = "endSleepCellIdentifier"

class AddMealDataSource: NSObject, UITableViewDataSource, UITableViewDelegate, PickerTableViewCellDelegate, DatePickerTableViewCellDelegate {
    
    var addEventModel: AddEventModel? = nil
    var dataSourceCells: [String] = [typeCellIdentifier, whenCellIdentifier, durationCellIdentifier]//default cells types
    var sleepMode = false
    
    private var typeCell: TypeTableViewCell? = nil
    private var whenCell: WhenTableViewCell? = nil
    private var durationCell: DurationTableViewCell? = nil
    private var startSleepCell: StartSleepTableViewCell? = nil
    private var endSleepCell: EndSleepTableViewCell? = nil

    private var pickerIndexPath: NSIndexPath? = nil
    private let defaultCellHeight: CGFloat = 80.0
    private let defaultPickerHeight: CGFloat = 216.0
    
    //MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSourceCells.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = nil
        let cellIdentifier = dataSourceCells[indexPath.row]
        cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        
        switch cellIdentifier {
            case startSleepCellIdentifier:
                self.startSleepCell = cell as? StartSleepTableViewCell
                self.startSleepCell?.timeLabel.text = addEventModel?.getStartSleepTimeString()
                self.startSleepCell?.dayLabel.text = addEventModel?.getStartSleepForDayLabel()
            case endSleepCellIdentifier:
                self.endSleepCell = cell as? EndSleepTableViewCell
                self.endSleepCell?.timeLabel.text = addEventModel?.getSleepEndTimeString()
                self.endSleepCell?.dayLabel.text = addEventModel?.getEndSleepForDayLabel()
            case typeCellIdentifier:
                self.typeCell = cell as? TypeTableViewCell
                self.typeCell?.typeLabel.text = addEventModel?.mealType.rawValue
            case whenCellIdentifier:
                self.whenCell = cell as? WhenTableViewCell
                self.whenCell?.timeLabel.text = addEventModel?.getTextForTimeLabel()
                self.whenCell?.dayLabel.text = addEventModel?.getTextForDayLabel()
            case durationCellIdentifier:
                self.durationCell = cell as? DurationTableViewCell
                self.durationCell?.durationLabel.attributedText = addEventModel?.getTextForTimeInterval()
            case pickerCellIdentifier:
                let pickerCell = cell as! PickerTableViewCell
                pickerCell.pickerCellDelegate = self
                let row = pickerCell.components.indexOf((addEventModel?.mealType.rawValue)!)
                pickerCell.pickerView.selectRow(row!, inComponent: 0, animated: false)
            case datePickerCellIdentifier:
                let datePickerCell = cell as! DatePickerTableViewCell
                datePickerCell.delegate = self
                if addEventModel!.datePickerRow(indexPath.row) {//date and time
                    datePickerCell.datePicker.datePickerMode = .DateAndTime
                    datePickerCell.datePicker.minuteInterval = 5
                    datePickerCell.datePicker.tag = indexPath.row
                    if sleepMode {
                        let startSleepPickerTag = addEventModel?.datePickerTags.first
                        switch indexPath.row {
                            case startSleepPickerTag!:
                                datePickerCell.datePicker.date = (addEventModel?.sleepStartDate)!
                            default:
                                datePickerCell.datePicker.date = (addEventModel?.sleepEndDate)!
                        }
                    } else {
                        datePickerCell.datePicker.date = (addEventModel?.eventDate)!
                    }
                } else if addEventModel!.countDownPickerRow(indexPath.row)  {//countdoun
                    datePickerCell.datePicker.datePickerMode = .CountDownTimer
                    datePickerCell.datePicker.minuteInterval = 5
                    datePickerCell.datePicker.tag = indexPath.row
                    datePickerCell.datePicker.countDownDuration = (addEventModel?.duration)!
                }
            default:
                break
        }
        
        return cell!
    }
    
    //MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        displayPickerForRowAtIndexPath(indexPath, inTable: tableView)
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var cellHeight:CGFloat = defaultCellHeight
        if dataSourceCells[indexPath.row] == pickerCellIdentifier || dataSourceCells[indexPath.row] == datePickerCellIdentifier {
            cellHeight = defaultPickerHeight
        }
        return cellHeight
    }
    
    //MARK: Working with picker
    
    func removePickerForIndexPath (indexPath: NSIndexPath, inTable tableView: UITableView) {
        tableView.beginUpdates()
        dataSourceCells.removeAtIndex(self.pickerIndexPath!.row)
        tableView.deleteRowsAtIndexPaths([self.pickerIndexPath!], withRowAnimation: .Middle)
        tableView.endUpdates()
        self.pickerIndexPath = nil
    }
    
    func displayPickerForRowAtIndexPath(indexPath: NSIndexPath, inTable tableView: UITableView) {
        var pickerIdentifier = ""
        let pickerRow = indexPath.row + 1
        
        if addEventModel!.datePickerRow(pickerRow) || addEventModel!.countDownPickerRow(pickerRow) {
            pickerIdentifier = datePickerCellIdentifier
        } else {
            pickerIdentifier = pickerCellIdentifier
        }
        
        tableView.beginUpdates()
        var before = false
        var sameCellSelected = false
        
        if hasPickerCell() {
            before = pickerIndexPath?.row < indexPath.row
            sameCellSelected = (pickerIndexPath?.row)! - 1 == indexPath.row
            removePickerForIndexPath(indexPath, inTable: tableView)
        }
        
        if !sameCellSelected {
            let row = before ? indexPath.row - 1 : indexPath.row
            self.pickerIndexPath = NSIndexPath(forRow: row+1, inSection: 0)
            dataSourceCells.insert(pickerIdentifier, atIndex: self.pickerIndexPath!.row)
            tableView.insertRowsAtIndexPaths([self.pickerIndexPath!], withRowAnimation: .Middle)            
            openDropDownImage(true, forCellAtIndexPath: indexPath, inTableView: tableView)
        } else {
            self.tableView(tableView, didDeselectRowAtIndexPath: indexPath)
        }
        
        tableView.endUpdates()
        if hasPickerCell() {
            tableView.scrollToRowAtIndexPath(self.pickerIndexPath!, atScrollPosition: .Middle, animated: true)
        }
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        openDropDownImage(false, forCellAtIndexPath: indexPath, inTableView: tableView)
    }
    
    func openDropDownImage(close: Bool, forCellAtIndexPath indexPath: NSIndexPath, inTableView table: UITableView) {
        let cell = table.cellForRowAtIndexPath(indexPath)
        if cell is BaseAddEventTableViewCell {
            let baseCell = cell as! BaseAddEventTableViewCell
            baseCell.toggleDropDownImage(close)
        }
    }
    
    func hasPickerCell () -> Bool {
        return pickerIndexPath != nil
    }
    
    //MARK: PickerTableViewCellDelegate
    
    func pickerSelectedRowWithTitle(title: String) {
        self.typeCell?.typeLabel.text = title
        switch title {
            case MealType.Breakfast.rawValue:
                addEventModel?.mealType = .Breakfast
            case MealType.Lunch.rawValue:
                addEventModel?.mealType = .Lunch
            case MealType.Dinner.rawValue:
                addEventModel?.mealType = .Dinner
            case MealType.Snack.rawValue:
                addEventModel?.mealType = .Snack
            default:
                addEventModel?.mealType = .Empty
        }
        
        if title != MealType.Empty.rawValue {//update when cell with usuall time of event
            self.whenCell?.timeLabel.text = addEventModel?.getTextForTimeLabel()
            self.whenCell?.dayLabel.text = addEventModel?.getTextForDayLabel()
        }
    }
    
    //MARK: DatePickerTableViewCellDelegate
    
    func picker(picker: UIDatePicker, didSelectDate date: NSDate) {
        if sleepMode {
            let startSleepPickerTag = addEventModel?.datePickerTags.first
            switch picker.tag {
                case startSleepPickerTag!://update end sleep date
                    addEventModel?.sleepStartDate = picker.date
                    self.startSleepCell?.timeLabel.text = addEventModel?.getStartSleepTimeString()
                    self.startSleepCell?.dayLabel.text = addEventModel?.getStartSleepForDayLabel()
                default://update end sleep date
                    addEventModel?.sleepEndDate = picker.date
                    self.endSleepCell?.timeLabel.text = addEventModel?.getSleepEndTimeString()
                    self.endSleepCell?.dayLabel.text = addEventModel?.getEndSleepForDayLabel()
            }            
        } else {
            if addEventModel!.datePickerRow(picker.tag) {
                addEventModel?.eventDate = date
                self.whenCell?.timeLabel.text = addEventModel?.getTextForTimeLabel()
                self.whenCell?.dayLabel.text = addEventModel?.getTextForDayLabel()
            } else if addEventModel!.countDownPickerRow(picker.tag) {
                addEventModel?.duration = picker.countDownDuration
                self.durationCell?.durationLabel.attributedText = addEventModel?.getTextForTimeInterval()
            }
        }
    }
}
