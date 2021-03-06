//
//  SampleFormatter.swift
//  MetabolicCompass
//
//  Created by Sihao Lu on 10/2/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit
import MCCircadianQueries

/**
 Controls the formatting and presentation style of all metrics.  Getting these units right and controlling their display is important for the user experience.  We use Apple's work with units in HealthKit to enable our population expressions to match up with those values from HealthKit

  -note:
  units and conversions are covered in Apple's HealthKit documentation
 
  -remark:
  stringFromSamples, stringFromDerivedQuantities, etc are all in this location

 */
public class SampleFormatter: NSObject {

    public static let bodyMassFormatter: NSMassFormatter = {
        let formatter = NSMassFormatter()
        formatter.forPersonMassUse = true
        formatter.unitStyle = .Medium
        formatter.numberFormatter = numberFormatter
        return formatter
    }()

    public static let foodMassFormatter: NSMassFormatter = {
        let formatter = NSMassFormatter()
        formatter.unitStyle = .Medium
        formatter.numberFormatter = numberFormatter
        return formatter
    }()

    public static let chartDateFormatter: NSDateFormatter = {
        let formatter: NSDateFormatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        formatter.timeStyle = .NoStyle
        return formatter
    }()

    public static let numberFormatter: NSNumberFormatter = {
        let formatter: NSNumberFormatter = NSNumberFormatter()
        formatter.numberStyle = .DecimalStyle
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    public static let integerFormatter: NSNumberFormatter = {
        let formatter: NSNumberFormatter = NSNumberFormatter()
        formatter.numberStyle = NSNumberFormatterStyle.NoStyle
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    public static let calorieFormatter: NSEnergyFormatter = {
        let formatter = NSEnergyFormatter()
        formatter.numberFormatter = SampleFormatter.numberFormatter
        formatter.unitStyle = NSFormattingUnitStyle.Medium
        return formatter
    }()

    public static let timeIntervalFormatter: NSDateComponentsFormatter = {
        let formatter = NSDateComponentsFormatter()
        formatter.unitsStyle = .Abbreviated
        formatter.allowedUnits = [.Hour, .Minute]
        return formatter
    }()

    private let emptyString: String

    public convenience override init() {
        self.init(emptyString: "--")
    }

    public init(emptyString: String) {
        self.emptyString = emptyString
        super.init()
    }

    public func numberFromSamples(samples: [MCSample]) -> Double {
        guard !samples.isEmpty else { return Double.quietNaN }
        if let _ = samples as? [HKStatistics] {
            var stat = samples.map { $0 as! HKStatistics }
            return numberFromStatistics(stat.removeLast())
        } else if let _ = samples as? [HKSample] {
            let hksamples = samples.map { $0 as! HKSample }
            return numberFromHKSamples(hksamples)
        } else {
            return numberFromMCSamples(samples)
        }
    }

    public func stringFromSamples(samples: [MCSample]) -> String {
        guard !samples.isEmpty else { return emptyString }
        if let _ = samples as? [HKStatistics] {
            var stat = samples.map { $0 as! HKStatistics }
            return stringFromStatistics(stat.removeLast())
        } else if let _ = samples as? [HKSample] {
            let hksamples = samples.map { $0 as! HKSample }
            return stringFromHKSamples(hksamples)
        } else  {
            return stringFromMCSamples(samples)
        }
    }

    public func numberFromStatistics(statistics: HKStatistics) -> Double {
        // Guaranteed to be quantity sample here
        guard let quantity = statistics.quantity else {
            return Double.quietNaN
        }
        return numberFromQuantity(quantity, type: statistics.quantityType)
    }

    public func stringFromStatistics(statistics: HKStatistics) -> String {
        // Cumulative has sumQuantity Discrete has quantity
        let quantity = statistics.sumQuantity() != nil ? statistics.sumQuantity() : statistics.quantity
        // Guaranteed to be quantity sample here
        guard (quantity != nil) else {
            return emptyString
        }
        return stringFromQuantity(quantity!, type: statistics.quantityType)
    }

    public func numberFromHKSamples(samples: [HKSample]) -> Double {
        guard !samples.isEmpty else { return Double.quietNaN }
        if let type = samples.last!.sampleType as? HKQuantityType {
            return numberFromQuantity((samples.last as! HKQuantitySample).quantity, type: type)
        }
        switch samples.last!.sampleType.identifier {
        case HKWorkoutTypeIdentifier:
            let d = NSDate(timeIntervalSinceReferenceDate: samples.workoutDuration!)
            return Double(d.hour) + (Double(d.minute) / 60.0)

        case HKCategoryTypeIdentifierSleepAnalysis:
            let d = NSDate(timeIntervalSinceReferenceDate: samples.sleepDuration!)
            return Double(d.hour) + (Double(d.minute) / 60.0)

        case HKCorrelationTypeIdentifierBloodPressure:
            let correlationSample = samples.first as! HKCorrelation
            let systolicSample = correlationSample.objectsForType(HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureSystolic)!).first as? HKQuantitySample
            guard systolicSample != nil else { return Double.quietNaN }
            return systolicSample!.quantity.doubleValueForUnit(HKUnit.millimeterOfMercuryUnit())

        default:
            return Double.quietNaN
        }
    }

    public func stringFromHKSamples(samples: [HKSample]) -> String {
        guard !samples.isEmpty else { return emptyString }
        if let type = samples.last!.sampleType as? HKQuantityType {
            return stringFromQuantity((samples.last as! HKQuantitySample).quantity, type: type)
        }
        switch samples.last!.sampleType.identifier {
        case HKWorkoutTypeIdentifier:
            return "\(SampleFormatter.timeIntervalFormatter.stringFromTimeInterval(samples.workoutDuration!)!)"

        case HKCategoryTypeIdentifierSleepAnalysis:
            return "\(SampleFormatter.timeIntervalFormatter.stringFromTimeInterval(samples.sleepDuration!)!)"

        case HKCorrelationTypeIdentifierBloodPressure:
            let correlationSample = samples.first as! HKCorrelation
            let diastolicSample = correlationSample.objectsForType(HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureDiastolic)!).first as? HKQuantitySample
            let systolicSample = correlationSample.objectsForType(HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureSystolic)!).first as? HKQuantitySample
            guard diastolicSample != nil && systolicSample != nil else {
                return emptyString
            }
            let diastolicNumber = SampleFormatter.integerFormatter.stringFromNumber(diastolicSample!.quantity.doubleValueForUnit(HKUnit.millimeterOfMercuryUnit()))!
            let systolicNumber = SampleFormatter.integerFormatter.stringFromNumber(systolicSample!.quantity.doubleValueForUnit(HKUnit.millimeterOfMercuryUnit()))!
            return "\(systolicNumber)/\(diastolicNumber)"

        default:
            return emptyString
        }
    }

    private func numberFromMCSamples(samples: [MCSample]) -> Double {
        guard !samples.isEmpty else { return Double.quietNaN }

        if let fst = samples.first {
            if let _ = fst.hkType as? HKQuantityType {
                return numberFromMCSample(fst)
            } else if let quantity = fst.numeralValue, type = fst.hkType {
                switch type.identifier {
                case HKWorkoutTypeIdentifier,
                     HKCategoryTypeIdentifierSleepAnalysis,
                     HKCategoryTypeIdentifierAppleStandHour:

                    if let mcunit = type.defaultUnit, userUnit = UserManager.sharedManager.userUnitsForType(type) {
                        return HKQuantity(unit: mcunit, doubleValue: quantity).doubleValueForUnit(userUnit)
                    }
                    return Double.quietNaN

                default:
                    return Double.quietNaN
                }
            }
        }
        return Double.quietNaN
    }

    private func stringFromMCSamples(samples: [MCSample]) -> String {
        guard !samples.isEmpty else { return emptyString }

        if let fst = samples.first {
            if let qType = fst.hkType as? HKQuantityType {
                if qType.identifier == HKQuantityTypeIdentifierBloodPressureSystolic
                    || qType.identifier == HKQuantityTypeIdentifierBloodPressureDiastolic
                {
                    // Check if we have the complementary blood pressure quantity in the array, and if so,
                    // return the composite string.
                    let checkId = qType.identifier == HKQuantityTypeIdentifierBloodPressureSystolic ?
                        HKQuantityTypeIdentifierBloodPressureDiastolic : HKQuantityTypeIdentifierBloodPressureSystolic

                    let matches = samples.filter { $0.hkType?.identifier == checkId }
                    if !matches.isEmpty {
                        let systolicFromMatches = checkId == HKQuantityTypeIdentifierBloodPressureSystolic
                        let systolicValue = systolicFromMatches ? matches.first!.numeralValue! : fst.numeralValue!
                        let diastolicValue = systolicFromMatches ? fst.numeralValue! : matches.first!.numeralValue!
                        let systolicNumber = SampleFormatter.integerFormatter.stringFromNumber(systolicValue)!
                        let diastolicNumber = SampleFormatter.integerFormatter.stringFromNumber(diastolicValue)!
                        return "\(systolicNumber)/\(diastolicNumber)"
                    }
                }
                return stringFromMCSample(fst)
            } else if let quantity = fst.numeralValue, type = fst.hkType {
                switch type.identifier {
                case HKWorkoutTypeIdentifier,
                     HKCategoryTypeIdentifierSleepAnalysis,
                     HKCategoryTypeIdentifierAppleStandHour:

                    if let unit = type.defaultUnit {
                        let secs = HKQuantity(unit: unit, doubleValue: quantity).doubleValueForUnit(HKUnit.secondUnit())
                        return "\(SampleFormatter.timeIntervalFormatter.stringFromTimeInterval(secs)!)"
                    }
                    return emptyString

                default:
                    return emptyString
                }
            }
        }
        return emptyString
    }

    private func numberFromQuantity(quantity: HKQuantity, type: HKQuantityType) -> Double {
        if let userUnit = UserManager.sharedManager.userUnitsForType(type) {
            return quantity.doubleValueForUnit(userUnit)
        }
        return Double.quietNaN
    }

    private func stringFromQuantity(quantity: HKQuantity, type: HKQuantityType) -> String {
        if let userUnit = UserManager.sharedManager.userUnitsForType(type) {
            let numericValue = quantity.doubleValueForUnit(userUnit)
            return stringFromNumberAndType(numericValue, type: type)
        }
        return emptyString
    }

    private func numberFromMCSample(sample: MCSample) -> Double {
        if let type = sample.hkType, quantity = sample.numeralValue, userUnit = UserManager.sharedManager.userUnitsForType(type) {
            return HKQuantity(unit: type.defaultUnit!, doubleValue: quantity).doubleValueForUnit(userUnit)
        }
        return Double.quietNaN
    }

    private func stringFromMCSample(sample: MCSample) -> String {
        if let type = sample.hkType, quantity = sample.numeralValue, userUnit = UserManager.sharedManager.userUnitsForType(type) {
            let convertedQuantity = HKQuantity(unit: type.defaultUnit!, doubleValue: quantity).doubleValueForUnit(userUnit)
            return stringFromNumberAndType(convertedQuantity, type: type)
        }
        return emptyString
    }

    private func stringFromNumberAndType(numericValue: Double, type: HKSampleType) -> String {
        if let fmtnum = SampleFormatter.numberFormatter.stringFromNumber(numericValue) {
            switch type.identifier {

            case HKCategoryTypeIdentifierSleepAnalysis,
                 HKCategoryTypeIdentifierAppleStandHour,
                 HKWorkoutTypeIdentifier:

                return fmtnum + " h"

            case HKQuantityTypeIdentifierBasalBodyTemperature,
                 HKQuantityTypeIdentifierBodyTemperature:

                return fmtnum + " F"

            case HKQuantityTypeIdentifierActiveEnergyBurned,
                 HKQuantityTypeIdentifierBasalEnergyBurned,
                 HKQuantityTypeIdentifierDietaryEnergyConsumed:

                return fmtnum + " kcal"

            case HKCorrelationTypeIdentifierBloodPressure,
                 HKQuantityTypeIdentifierBloodPressureDiastolic,
                 HKQuantityTypeIdentifierBloodPressureSystolic:

                return fmtnum + " mmHg"

            case HKQuantityTypeIdentifierBodyMassIndex,
                 HKQuantityTypeIdentifierStepCount,
                 HKQuantityTypeIdentifierUVExposure:
                return fmtnum

            case HKQuantityTypeIdentifierDietaryBiotin,
                 HKQuantityTypeIdentifierDietaryChromium,
                 HKQuantityTypeIdentifierDietaryFolate,
                 HKQuantityTypeIdentifierDietaryIodine,
                 HKQuantityTypeIdentifierDietaryMolybdenum,
                 HKQuantityTypeIdentifierDietarySelenium,
                 HKQuantityTypeIdentifierDietaryVitaminA,
                 HKQuantityTypeIdentifierDietaryVitaminB12,
                 HKQuantityTypeIdentifierDietaryVitaminD,
                 HKQuantityTypeIdentifierDietaryVitaminK:

                 return fmtnum + " mcg"

            case HKQuantityTypeIdentifierDietaryCaffeine,
                 HKQuantityTypeIdentifierDietaryCalcium,
                 HKQuantityTypeIdentifierDietaryCholesterol,
                 HKQuantityTypeIdentifierDietaryChloride,
                 HKQuantityTypeIdentifierDietaryCopper,
                 HKQuantityTypeIdentifierDietaryIron,
                 HKQuantityTypeIdentifierDietaryMagnesium,
                 HKQuantityTypeIdentifierDietaryManganese,
                 HKQuantityTypeIdentifierDietaryNiacin,
                 HKQuantityTypeIdentifierDietaryPantothenicAcid,
                 HKQuantityTypeIdentifierDietaryPhosphorus,
                 HKQuantityTypeIdentifierDietaryPotassium,
                 HKQuantityTypeIdentifierDietaryRiboflavin,
                 HKQuantityTypeIdentifierDietarySodium,
                 HKQuantityTypeIdentifierDietaryThiamin,
                 HKQuantityTypeIdentifierDietaryVitaminB6,
                 HKQuantityTypeIdentifierDietaryVitaminC,
                 HKQuantityTypeIdentifierDietaryVitaminE,
                 HKQuantityTypeIdentifierDietaryZinc:

                return fmtnum + " mg"

            case HKQuantityTypeIdentifierDietaryCarbohydrates,
                 HKQuantityTypeIdentifierDietaryFatMonounsaturated,
                 HKQuantityTypeIdentifierDietaryFatPolyunsaturated,
                 HKQuantityTypeIdentifierDietaryFatSaturated,
                 HKQuantityTypeIdentifierDietaryFatTotal,
                 HKQuantityTypeIdentifierDietaryFiber,
                 HKQuantityTypeIdentifierDietaryProtein,
                 HKQuantityTypeIdentifierDietarySugar:

                return fmtnum + " g"

            case HKQuantityTypeIdentifierDietaryWater:
                return fmtnum + " ml"

            case HKQuantityTypeIdentifierBloodAlcoholContent,
                 HKQuantityTypeIdentifierBodyFatPercentage,
                 HKQuantityTypeIdentifierOxygenSaturation,
                 HKQuantityTypeIdentifierPeripheralPerfusionIndex:

                return fmtnum + " %"

            case HKQuantityTypeIdentifierFlightsClimbed,
                 HKQuantityTypeIdentifierInhalerUsage,
                 HKQuantityTypeIdentifierNikeFuel,
                 HKQuantityTypeIdentifierNumberOfTimesFallen,
                 HKQuantityTypeIdentifierStepCount,
                 HKQuantityTypeIdentifierUVExposure:
                
                return fmtnum

            case HKQuantityTypeIdentifierElectrodermalActivity:
                return fmtnum + " mcS"

            case HKQuantityTypeIdentifierForcedExpiratoryVolume1,
                 HKQuantityTypeIdentifierForcedVitalCapacity:

                return fmtnum + " L"

            case HKQuantityTypeIdentifierPeakExpiratoryFlowRate:
                return fmtnum + " L/min"

            case HKQuantityTypeIdentifierBloodGlucose:
                return fmtnum + " mg/dL"

            case HKQuantityTypeIdentifierHeartRate:
                return fmtnum + " bpm"

            case HKQuantityTypeIdentifierRespiratoryRate:
                return fmtnum + " brpm"

            case HKQuantityTypeIdentifierBodyMassIndex:
                return fmtnum + " kg/m2"

            case HKQuantityTypeIdentifierBodyMass,
                 HKQuantityTypeIdentifierLeanBodyMass,
                 HKQuantityTypeIdentifierHeight,
                 HKQuantityTypeIdentifierDistanceWalkingRunning:

                if let userUnit = UserManager.sharedManager.userUnitsForType(type) {
                    return fmtnum + " " + userUnit.unitString
                }
                return emptyString

            default:
                return emptyString
            }
        }
        return emptyString
    }
}

public class MetricSuffixFormatter: NSObject {
    public static let sharedInstance = MetricSuffixFormatter()

    let buckets: [(Double, String)] = [
        (1e3,  "k"),
        (1e6,  "M"),
        (1e9,  "G"),
        (1e12, "T"),
        (1e15, "P"),
        (1e18, "E")
    ]

    public func formatDouble(i: Double) -> String {
        var entry: (Double, String)! = nil
        for j in 0..<buckets.count {
            if i < buckets[j].0 {
                break
            }
            entry = buckets[j]
        }

        if entry == nil {
            return String(format: "%.3g", i)
        } else {
            return "\(String(format: "%.3g", i / entry.0))\(entry.1)"
        }
    }

    public func formatCGFloat(i: CGFloat) -> String {
        return self.formatDouble(Double(i))
    }

    public func formatFloat(i: Float) -> String {
        return self.formatDouble(Double(i))
    }

    public func formatInt(i: Int) -> String {
        return self.formatDouble(Double(i))
    }
}