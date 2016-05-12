//
//  TitledInputCollectionViewCell.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 4/28/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

class TitledInputCollectionViewCell: BaseCollectionViewCell {

    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var inputTxtField: UITextField!
    @IBOutlet weak var smallDescriptionLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        inputTxtField.contentVerticalAlignment = UIControlContentVerticalAlignment.Center

        inputTxtField.addTarget(self, action: #selector(InputCollectionViewCell.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        inputTxtField.delegate = self
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneBtn = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action:  #selector(TitledInputCollectionViewCell.doneAction(_:)))
        
        toolbar.setItems([doneBtn], animated: false)
        inputTxtField.inputAccessoryView = toolbar        

    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        titleLbl.text = nil
        inputTxtField.text = nil
        smallDescriptionLbl.text = nil
    }
    
    func doneAction(Sender: UIBarButtonItem) {
        self.endEditing(true)
    }
    

}