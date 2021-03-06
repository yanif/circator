//
//  DashboardMetricsAppearanceProvider.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit
import MetabolicCompassKit

class DashboardMetricsAppearanceProvider: NSObject {
    
    func attributedText(text: String, forSampleType sampleType: String, active: Bool) -> NSAttributedString
    {
        return NSAttributedString(string: text, attributes: [NSForegroundColorAttributeName: self.colorForSampleType(sampleType, active: active)])
    }
    
    func colorForSampleType(sampleType: String, active: Bool) -> UIColor
    {
        return self.getColorForSampleType(sampleType, active: active) ?? UIColor.whiteColor()
    }
    
    enum SampleGroupColor: UInt32 {
        case sgBlue = 0x388CFB
        case sgRed = 0xE2472C
        case sgYelow = 0xB68F14
        case sgMagenta = 0x8627B5
    }
    
    
    private func getColorForSampleType(sampleType: String, active: Bool) -> UIColor?
    {
        if (!active) {
            return UIColor.lightGrayColor()
        }
        
        switch sampleType {
        case HKQuantityTypeIdentifierBodyMass,
             HKQuantityTypeIdentifierBodyMassIndex,
             HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return UIColor.colorWithHexString("#388CFB")
            
        case HKQuantityTypeIdentifierHeartRate,
             HKQuantityTypeIdentifierStepCount,
             HKQuantityTypeIdentifierBasalEnergyBurned,
             HKQuantityTypeIdentifierActiveEnergyBurned:
            return UIColor.colorWithHex(SampleGroupColor.sgRed.rawValue)
            
        case HKCategoryTypeIdentifierSleepAnalysis,
             HKQuantityTypeIdentifierUVExposure:
            return UIColor.colorWithHex(SampleGroupColor.sgYelow.rawValue)
        
        case HKQuantityTypeIdentifierDietarySugar,
             HKQuantityTypeIdentifierDietarySodium,
             HKQuantityTypeIdentifierDietaryCholesterol,
             HKQuantityTypeIdentifierDietaryCaffeine:
            return UIColor.colorWithHexString("#8627B5")
        
        case HKQuantityTypeIdentifierDietaryProtein,
             HKQuantityTypeIdentifierDietaryFatTotal,
             HKQuantityTypeIdentifierDietaryCarbohydrates:
            return UIColor.colorWithHexString("#138F16")
        
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated,
             HKQuantityTypeIdentifierDietaryFatMonounsaturated,
             HKQuantityTypeIdentifierDietaryFatSaturated,
             HKQuantityTypeIdentifierDietaryFiber:
            return UIColor.colorWithHexString("#A57B55")
        
        case HKQuantityTypeIdentifierDietaryWater,
             HKCorrelationTypeIdentifierBloodPressure:
            return UIColor.colorWithHexString("#BA1075")

        default:
            return UIColor.whiteColor()
            
        }
    }
    
    func typeFromString(string:String) -> String {
        switch string {
        case NSLocalizedString("Weight", comment: "user weight"):
            return HKQuantityTypeIdentifierBodyMass
        case NSLocalizedString("Heart rate", comment: "Heartrate"):
            return HKQuantityTypeIdentifierHeartRate
            
        case NSLocalizedString("Sleep", comment: "Sleep") :
            return HKCategoryTypeIdentifierSleepAnalysis
        case NSLocalizedString("BMI", comment: "Body Mass Index") :
            return HKQuantityTypeIdentifierBodyMassIndex
        case NSLocalizedString("Active Energy", comment: "energy burned") :
            return HKQuantityTypeIdentifierActiveEnergyBurned
        case NSLocalizedString("Resting Energy", comment: "Basal Energy") :
            return HKQuantityTypeIdentifierBasalEnergyBurned
        case NSLocalizedString("UV Exposure", comment: "UV Exposure") :
            return HKQuantityTypeIdentifierUVExposure
        case NSLocalizedString("Caffeine", comment: "Caffeine") :
            return HKQuantityTypeIdentifierDietaryCaffeine
        case NSLocalizedString("Sugar", comment: "Sugar") :
            return HKQuantityTypeIdentifierDietarySugar
        case NSLocalizedString("Cholesterol", comment: "Cholesterol") :
            return HKQuantityTypeIdentifierDietaryCholesterol
        case NSLocalizedString("Salt", comment: "Sodium") :
            return HKQuantityTypeIdentifierDietarySodium
        case NSLocalizedString("Protein", comment: "Protein") :
            return HKQuantityTypeIdentifierDietaryProtein
        case NSLocalizedString("Fiber", comment: "Fiber") :
            return HKQuantityTypeIdentifierDietaryFiber
        case NSLocalizedString("Fat", comment: "Fat") :
            return HKQuantityTypeIdentifierDietaryFatTotal
        case NSLocalizedString("Carbohydrates", comment: "Carbohydrates") :
            return HKQuantityTypeIdentifierDietaryCarbohydrates
        case NSLocalizedString("Polyunsaturated fat", comment: "Polyunsaturated Fat") :
            return HKQuantityTypeIdentifierDietaryFatPolyunsaturated
        case NSLocalizedString("Saturated fat", comment: "Saturated Fat") :
            return HKQuantityTypeIdentifierDietaryFatSaturated
        case NSLocalizedString("Monosaturated fat", comment: "Monosaturated Fat") :
            return HKQuantityTypeIdentifierDietaryFatMonounsaturated
        case NSLocalizedString("Water", comment: "Water") :
            return HKQuantityTypeIdentifierDietaryWater
        case NSLocalizedString("Dietary energy", comment: "Dietary Energy") :
            return HKQuantityTypeIdentifierDietaryEnergyConsumed
        case NSLocalizedString("Blood pressure", comment: "Blood pressure") :
            return HKCorrelationTypeIdentifierBloodPressure
        case NSLocalizedString("Step count", comment: "Step count") :
            return HKQuantityTypeIdentifierStepCount
        case NSLocalizedString("UV Exposure", comment: "UV Exposure") :
            return HKQuantityTypeIdentifierUVExposure
        case NSLocalizedString("Salt", comment: "Salt") :
            return HKQuantityTypeIdentifierDietarySodium
        case NSLocalizedString("Active Energy Burned", comment: " Active Energy Burned") :
            return HKQuantityTypeIdentifierActiveEnergyBurned
        default:
            return ""
        }
    }
    
    func stringForSampleType(sampleType: String) -> String
    {
        switch sampleType {
        case HKQuantityTypeIdentifierBodyMass:
            return NSLocalizedString("Weight", comment: "user weight")
        case HKQuantityTypeIdentifierHeartRate:
            return NSLocalizedString("Heart rate", comment: "Heartrate")
        case HKCategoryTypeIdentifierSleepAnalysis:
            return NSLocalizedString("Sleep", comment: "Sleep")
        case HKQuantityTypeIdentifierBodyMassIndex:
            return NSLocalizedString("BMI", comment: "Body Mass Index")
        case HKQuantityTypeIdentifierActiveEnergyBurned:
            return NSLocalizedString("Active Energy", comment: "energy burned")
        case HKQuantityTypeIdentifierBasalEnergyBurned:
            return NSLocalizedString("Resting Energy", comment: "Basal Energy")
        case HKQuantityTypeIdentifierUVExposure:
            return NSLocalizedString("UV Exposure", comment: "UV Exposure")
        case HKQuantityTypeIdentifierDietaryCaffeine:
            return NSLocalizedString("Caffeine", comment: "Caffeine")
        case HKQuantityTypeIdentifierDietarySugar:
            return NSLocalizedString("Sugar", comment: "Sugar")
        case HKQuantityTypeIdentifierDietaryCholesterol:
            return NSLocalizedString("Cholesterol", comment: "Cholesterol")
        case HKQuantityTypeIdentifierDietarySodium:
            return NSLocalizedString("Salt", comment: "Sodium")
        case HKQuantityTypeIdentifierDietaryProtein:
            return NSLocalizedString("Protein", comment: "Protein")
        case HKQuantityTypeIdentifierDietaryFiber:
            return NSLocalizedString("Fiber", comment: "Fiber")
        case HKQuantityTypeIdentifierDietaryFatTotal:
            return NSLocalizedString("Fat", comment: "Fat")
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return NSLocalizedString("Carbohydrates", comment: "Carbohydrates")
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return NSLocalizedString("Polyunsaturated fat", comment: "Polyunsaturated Fat")
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return NSLocalizedString("Saturated fat", comment: "Saturated Fat")
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return NSLocalizedString("Monosaturated fat", comment: "Monosaturated Fat")
        case HKQuantityTypeIdentifierDietaryWater:
            return NSLocalizedString("Water", comment: "Water")
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return NSLocalizedString("Dietary energy", comment: "Dietary Energy")
        case HKCorrelationTypeIdentifierBloodPressure:
            return NSLocalizedString("Blood pressure", comment: "Blood pressure")
        case HKQuantityTypeIdentifierStepCount:
            return NSLocalizedString("Step count", comment: "Step count")
        case HKQuantityTypeIdentifierUVExposure:
            return NSLocalizedString("UV Exposure", comment: "UV Exposure")
        case HKQuantityTypeIdentifierDietarySodium:
            return NSLocalizedString("Salt", comment: "Salt")
        case HKQuantityTypeIdentifierActiveEnergyBurned:
            return NSLocalizedString("Active Energy Burned", comment: " Active Energy Burned")
        default:
            return ""
        }
    }
    
    func stringForSampleTypeOfCorrelate(sampleType: String) -> String
    {
        switch sampleType {
        case HKQuantityTypeIdentifierBodyMass:
            return NSLocalizedString("Weight", comment: "user weight")
        case HKQuantityTypeIdentifierHeartRate:
            return NSLocalizedString("Heart rate", comment: "Heartrate")
        case HKCategoryTypeIdentifierSleepAnalysis:
            return NSLocalizedString("Sleep", comment: "Sleep")
        case HKQuantityTypeIdentifierBodyMassIndex:
            return NSLocalizedString("BMI", comment: "Body Mass Index")
        case HKQuantityTypeIdentifierActiveEnergyBurned:
            return NSLocalizedString("Active En.", comment: "energy burned")
        case HKQuantityTypeIdentifierBasalEnergyBurned:
            return NSLocalizedString("Resting En.", comment: "Basal Energy")
        case HKQuantityTypeIdentifierDietaryCaffeine:
            return NSLocalizedString("Caffeine", comment: "Caffeine")
        case HKQuantityTypeIdentifierDietarySugar:
            return NSLocalizedString("Sugar", comment: "Sugar")
        case HKQuantityTypeIdentifierDietaryCholesterol:
            return NSLocalizedString("Cholesterol", comment: "Cholesterol")
        case HKQuantityTypeIdentifierDietarySodium:
            return NSLocalizedString("Salt", comment: "Sodium")
        case HKQuantityTypeIdentifierDietaryProtein:
            return NSLocalizedString("Protein", comment: "Protein")
        case HKQuantityTypeIdentifierDietaryFiber:
            return NSLocalizedString("Fiber", comment: "Fiber")
        case HKQuantityTypeIdentifierDietaryFatTotal:
            return NSLocalizedString("Fat", comment: "Fat")
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return NSLocalizedString("Carbohydrates", comment: "Carbohydrates")
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return NSLocalizedString("Polyunsat. Fat", comment: "Polyunsaturated Fat")
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return NSLocalizedString("Sat. Fat", comment: "Saturated Fat")
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return NSLocalizedString("Monosat. Fat", comment: "Monosaturated Fat")
        case HKQuantityTypeIdentifierDietaryWater:
            return NSLocalizedString("Water", comment: "Water")
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return NSLocalizedString("Dietary En.", comment: "Dietary Energy")
        case HKCorrelationTypeIdentifierBloodPressure:
            return NSLocalizedString("Blood pressure", comment: "Blood pressure")
        case HKQuantityTypeIdentifierStepCount:
            return NSLocalizedString("Steps", comment: "Step count")
        case HKQuantityTypeIdentifierUVExposure:
            return NSLocalizedString("UV", comment: "UV Exposure")
        case HKQuantityTypeIdentifierDietarySodium:
            return NSLocalizedString("Salt", comment: "Salt")
        default:
            return ""
        }
    }
    
    func titleForSampleType(sampleType: String, active: Bool) -> NSAttributedString
    {
        return self.attributedText(self.stringForSampleType(sampleType), forSampleType: sampleType, active: active)
    }
    
    func titleForAnalysisChartOfType(sampleType: String) -> NSAttributedString {
        return self.attributedText(self.stringForSampleTypeOfCorrelate(sampleType), forSampleType: sampleType, active: false)
    }
    
    private func imageNameWithState(baseName: String, active: Bool) -> String
    {
        return baseName + (active ? "-normal": "-unactive");
    }
    
    private func imageNameForSampleType(sampleType: String) -> String
    {
        switch sampleType {
        case HKQuantityTypeIdentifierBodyMass:
            return "icon-weight"
        case HKQuantityTypeIdentifierHeartRate:
            return "icon-heart-rate"
        case HKCategoryTypeIdentifierSleepAnalysis:
            return "icon-sleep"
        case HKQuantityTypeIdentifierBodyMassIndex:
            return "icon-bmi"
        case HKQuantityTypeIdentifierActiveEnergyBurned:
            return "icon-active-energy"
        case HKQuantityTypeIdentifierBasalEnergyBurned:
            return "icon-resting-energy"
        case HKQuantityTypeIdentifierUVExposure:
            return "icon-uv"
        case HKQuantityTypeIdentifierDietaryCaffeine:
            return "icon-caffeine"
        case HKQuantityTypeIdentifierDietarySugar:
            return "icon-sugar"
        case HKQuantityTypeIdentifierDietaryCholesterol:
            return "icon-cholesterol"
        case HKQuantityTypeIdentifierDietarySodium:
            return "icon-salt"
        case HKQuantityTypeIdentifierDietaryProtein:
            return "icon-protein"
        case HKQuantityTypeIdentifierDietaryFiber:
            return "icon-fiber"
        case HKQuantityTypeIdentifierDietaryFatTotal:
            return "icon-fat"
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return "icon-carbohydrates"
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return "icon-polyunsaturated-fat"
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return "icon-saturated-fat"
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return "icon-monosaturated-fat"
        case HKQuantityTypeIdentifierDietaryWater:
            return "icon-water"
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return "icon-calories"
        case HKCorrelationTypeIdentifierBloodPressure:
            return "icon-blood"
        case HKQuantityTypeIdentifierStepCount:
            return "icon-steps"
        case HKQuantityTypeIdentifierUVExposure:
            return "icon-uv"
        case HKQuantityTypeIdentifierDietarySodium:
            return "icon-salt"
        default:
            return ""
        }
    }

    func imageForSampleType(sampleType: String, active: Bool) -> UIImage?
    {
        let imageName = self.imageNameWithState(self.imageNameForSampleType(sampleType), active: active)
        let image = UIImage(named: imageName)
        return image
    }
    
}
