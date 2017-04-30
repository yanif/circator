//
//  PickerTableViewCell.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 6/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MCCircadianQueries

class PickerTableViewCell: UITableViewCell, UIPickerViewDataSource, UIPickerViewDelegate {
    @available(iOS 2.0, *)
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 5
    }


    @IBOutlet weak var pickerView: UIPickerView!
    
    var pickerCellDelegate: PickerTableViewCellDelegate? = nil
    var components: [String] = [MealType.Empty.rawValue, MealType.Breakfast.rawValue, MealType.Lunch.rawValue, MealType.Dinner.rawValue, MealType.Snack.rawValue]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        self.contentView.isUserInteractionEnabled = false
        self.pickerView.dataSource = self
        self.pickerView.delegate = self
        // Initialization code
    }
    
    //MARK: UIPickerViewDataSource
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return components.count
    }
    
    //MARK: UIPickerViewDelegate
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return components[row]
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.pickerCellDelegate?.pickerSelectedRowWithTitle(title: components[row])
    }
}

protocol PickerTableViewCellDelegate {
    func pickerSelectedRowWithTitle(title: String)
}
