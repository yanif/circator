//
//  DashboardComparisonCell.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit
import MetabolicCompassKit

class DashboardComparisonCell: UITableViewCell {

    @IBOutlet weak var sampleName: UILabel!
    @IBOutlet weak var sampleIcon: UIImageView!
    @IBOutlet weak var localSampleValueTextField: UILabel!
    @IBOutlet weak var populationSampleValueTextField: UILabel!
    
    static let healthFormatter = SampleFormatter()
    
    
    var sampleType: HKSampleType? {
        didSet {
            guard sampleType != nil else {
                sampleIcon.image = nil
                return
            }
            
            sampleIcon.image = appearanceProvider.imageForSampleType(sampleType!.identifier, active: true)
            sampleName.attributedText = appearanceProvider.titleForSampleType(sampleType!.identifier, active: true)
        }
    }
    
    private let appearanceProvider = DashboardMetricsAppearanceProvider()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    /// loading both User and Population samples
    func setUserData(userData: [MCSample], populationAverageData: [MCSample], stalePopulation: Bool = false) {
        loadUserSamples(userData)
        loadPopSamples(populationAverageData, stale: stalePopulation)
    }
    
    private let defaultTextColor  = UIColor(red: 62.0/255.0, green: 84.0/255.0, blue: 117.0/255.0, alpha: 1.0)
    private let defaultDigitColor = UIColor.whiteColor()
    
    private func loadUserSamples( results: [MCSample]) {
        let text = DashboardComparisonCell.healthFormatter.stringFromSamples(results)

        let formatAttrs = [NSForegroundColorAttributeName: defaultDigitColor,
                           NSFontAttributeName : ScreenManager.appFontOfSize(16)]

        let defaultFormatAttrs = [NSForegroundColorAttributeName: defaultTextColor,
                                  NSFontAttributeName : ScreenManager.appFontOfSize(16)]

        localSampleValueTextField.attributedText =
            text.formatTextWithRegex("[-+]?(\\d*[.,/])?\\d+", format: formatAttrs, defaultFormat: defaultFormatAttrs)
    }
    
    /// note setUserData above that uses this call
    private func loadPopSamples(results: [MCSample], stale: Bool) {
        
        let text = DashboardComparisonCell.healthFormatter.stringFromSamples(results)

        let formatAttrs = [NSForegroundColorAttributeName: defaultDigitColor,
                           NSFontAttributeName : ScreenManager.appFontOfSize(16)]

        let defaultFormatAttrs = [NSForegroundColorAttributeName: defaultTextColor,
                                  NSFontAttributeName : ScreenManager.appFontOfSize(16)]

        populationSampleValueTextField.attributedText =
            text.formatTextWithRegex("[-+]?(\\d*[.,/])?\\d+", format: formatAttrs, defaultFormat: defaultFormatAttrs)
    }
    
    
}
