//
//  AppButton.swift
//  MetabolicCompass
//
//  Created by Anna Tkach on 5/17/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit


class AppButton: UIButton {

    private let defaultFontSize: CGFloat = 14.0
    
    var fontSize: CGFloat = 14.0 {
        didSet {
            setupFontSize(fontSize)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupFont()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupFont()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupFont()
    }
    
    private func setupFont() {
        fontSize = self.titleLabel?.font.pointSize ?? defaultFontSize
        setupFontSize(fontSize)
    }
    
    func setupFontSize(size: CGFloat) {
        self.titleLabel?.font = ScreenManager.appFontOfSize(fontSize)
    }

}
