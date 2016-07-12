//
//  SampleFormatter.swift
//  MetabolicCompass
//
//  Created by Sihao Lu on 10/2/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit

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
        //Cumulative has sumQuantity Discrete has quantity
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

        if let fst      = samples.first,
               quantity = fst.numeralValue,
               type     = fst.hkType
        {
            if let qtype = type as? HKQuantityType {
                return numberFromMCSample(quantity, type: qtype)
            }

            switch type.identifier {
            case HKWorkoutTypeIdentifier:
                let d = NSDate(timeIntervalSinceReferenceDate: quantity)
                return Double(d.hour) + (Double(d.minute) / 60.0)

            case HKCategoryTypeIdentifierSleepAnalysis:
                let d = NSDate(timeIntervalSinceReferenceDate: quantity)
                return Double(d.hour) + (Double(d.minute) / 60.0)

            default:
                return Double.quietNaN
            }
        }
        return Double.quietNaN
    }

    private func stringFromMCSamples(samples: [MCSample]) -> String {
        guard !samples.isEmpty else { return emptyString }

        if let fst      = samples.first,
               quantity = fst.numeralValue,
               type     = fst.hkType
        {
            if let qtype = type as? HKQuantityType {
                return stringFromMCSample(quantity, type: qtype)
            }

            switch type.identifier {
            case HKWorkoutTypeIdentifier:
                return "\(SampleFormatter.timeIntervalFormatter.stringFromTimeInterval(quantity)!)"

            case HKCategoryTypeIdentifierSleepAnalysis:
                return "\(SampleFormatter.timeIntervalFormatter.stringFromTimeInterval(quantity)!)"

            default:
                return emptyString
            }
        }
        return emptyString
    }

    private func numberFromQuantity(quantity: HKQuantity, type: HKQuantityType) -> Double {
        switch type.identifier {
        case HKQuantityTypeIdentifierActiveEnergyBurned:
            return quantity.doubleValueForUnit(HKUnit.kilocalorieUnit())
            
        case HKQuantityTypeIdentifierBasalEnergyBurned:
            return quantity.doubleValueForUnit(HKUnit.kilocalorieUnit())

        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            return quantity.doubleValueForUnit(HKUnit.millimeterOfMercuryUnit())

        case HKQuantityTypeIdentifierBloodPressureSystolic:
            return quantity.doubleValueForUnit(HKUnit.millimeterOfMercuryUnit())
            
        case HKQuantityTypeIdentifierBodyMass:
            return quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo))

        case HKQuantityTypeIdentifierBodyMassIndex:
            return quantity.doubleValueForUnit(HKUnit.countUnit())

        case HKQuantityTypeIdentifierDietaryCaffeine:
            return quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Milli))

        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return quantity.doubleValueForUnit(HKUnit.gramUnit())

        case HKQuantityTypeIdentifierDietaryCholesterol:
            return quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Milli))

        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return quantity.doubleValueForUnit(HKUnit.kilocalorieUnit())

        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return quantity.doubleValueForUnit(HKUnit.gramUnit())

        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return quantity.doubleValueForUnit(HKUnit.gramUnit())

        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return quantity.doubleValueForUnit(HKUnit.gramUnit())

        case HKQuantityTypeIdentifierDietaryFatTotal:
            return quantity.doubleValueForUnit(HKUnit.gramUnit())

        case HKQuantityTypeIdentifierDietaryProtein:
            return quantity.doubleValueForUnit(HKUnit.gramUnit())

        case HKQuantityTypeIdentifierDietarySodium:
            return quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Milli))

        case HKQuantityTypeIdentifierDietaryFiber:
            return quantity.doubleValueForUnit(HKUnit.gramUnit())

        case HKQuantityTypeIdentifierDietarySugar:
            return quantity.doubleValueForUnit(HKUnit.gramUnit())

        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            return quantity.doubleValueForUnit(HKUnit.mileUnit())

        case HKQuantityTypeIdentifierDietaryWater:
            return quantity.doubleValueForUnit(HKUnit.literUnitWithMetricPrefix(.Milli))

        case HKQuantityTypeIdentifierHeartRate:
            return quantity.doubleValueForUnit(HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit()))

        case HKQuantityTypeIdentifierStepCount:
            return quantity.doubleValueForUnit(HKUnit.countUnit())

        case HKQuantityTypeIdentifierUVExposure:
            return quantity.doubleValueForUnit(HKUnit.countUnit())
            
        default:
            return Double.quietNaN
        }
    }

    private func stringFromQuantity(quantity: HKQuantity, type: HKQuantityType) -> String {
        let milliGramUnit = HKUnit.gramUnitWithMetricPrefix(.Milli)
        switch type.identifier {
        case HKQuantityTypeIdentifierActiveEnergyBurned:
            fallthrough
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            fallthrough
        case HKQuantityTypeIdentifierBasalEnergyBurned:
            return SampleFormatter.calorieFormatter.stringFromValue(quantity.doubleValueForUnit(HKUnit.kilocalorieUnit()), unit: .Kilocalorie)
            
        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            fallthrough
        case HKQuantityTypeIdentifierBloodPressureSystolic:
            return SampleFormatter.integerFormatter.stringFromNumber(quantity.doubleValueForUnit(HKUnit.millimeterOfMercuryUnit()))!

        case HKQuantityTypeIdentifierBodyMass:
            return SampleFormatter.bodyMassFormatter.stringFromKilograms(quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo)))

        case HKQuantityTypeIdentifierBodyMassIndex:
            fallthrough
        case HKQuantityTypeIdentifierStepCount:
            fallthrough
        case HKQuantityTypeIdentifierUVExposure:
            return SampleFormatter.numberFormatter.stringFromNumber(quantity.doubleValueForUnit(HKUnit.countUnit()))!

        case HKQuantityTypeIdentifierDietaryCaffeine:
            fallthrough
        case HKQuantityTypeIdentifierDietaryCholesterol:
            fallthrough
        case HKQuantityTypeIdentifierDietarySodium:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity.doubleValueForUnit(milliGramUnit))!) mg"

        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            fallthrough
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            fallthrough
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            fallthrough
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            fallthrough
        case HKQuantityTypeIdentifierDietaryFatTotal:
            fallthrough
        case HKQuantityTypeIdentifierDietaryProtein:
            fallthrough
        case HKQuantityTypeIdentifierDietaryFiber:
            fallthrough
        case HKQuantityTypeIdentifierDietarySugar:
            return SampleFormatter.foodMassFormatter.stringFromValue(quantity.doubleValueForUnit(HKUnit.gramUnit()), unit: .Gram)

        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            return SampleFormatter.numberFormatter.stringFromNumber(quantity.doubleValueForUnit(HKUnit.mileUnit()))!

        case HKQuantityTypeIdentifierDietaryWater:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity.doubleValueForUnit(HKUnit.literUnitWithMetricPrefix(.Milli)))!) ml"

        case HKQuantityTypeIdentifierHeartRate:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity.doubleValueForUnit(HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit())))!) bpm"
            
        default:
            return emptyString
        }
    }

    private func numberFromMCSample(quantity: Double, type: HKSampleType) -> Double {
        switch type.identifier {
        case HKQuantityTypeIdentifierBodyMass:
            let hkquantity = HKQuantity(unit: HKUnit.poundUnit(), doubleValue: quantity)
            return hkquantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo))

        default:
            return quantity
        }
    }

    private func stringFromMCSample(quantity: Double, type: HKSampleType) -> String {
        switch type.identifier {
        case HKQuantityTypeIdentifierActiveEnergyBurned:
            fallthrough
        case HKQuantityTypeIdentifierBasalEnergyBurned:
            return SampleFormatter.calorieFormatter.stringFromValue(quantity, unit: .Kilocalorie)

        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            fallthrough
        case HKQuantityTypeIdentifierBloodPressureSystolic:
            return SampleFormatter.integerFormatter.stringFromNumber(quantity)!

        case HKQuantityTypeIdentifierBodyMass:
            let hkquantity = HKQuantity(unit: HKUnit.poundUnit(), doubleValue: quantity)
            let kilos = hkquantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo))
            return SampleFormatter.bodyMassFormatter.stringFromKilograms(kilos)

        case HKQuantityTypeIdentifierBodyMassIndex:
            return SampleFormatter.numberFormatter.stringFromNumber(quantity)!

        case HKQuantityTypeIdentifierDietaryCaffeine:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) mg"

        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            fallthrough
        case HKQuantityTypeIdentifierDietaryFiber:
            fallthrough
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            fallthrough
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            fallthrough
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            fallthrough
        case HKQuantityTypeIdentifierDietaryFatTotal:
            fallthrough
        case HKQuantityTypeIdentifierDietaryProtein:
            fallthrough
        case HKQuantityTypeIdentifierDietarySugar:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) g"
        
        case HKQuantityTypeIdentifierDietaryCholesterol:
            fallthrough
        case HKQuantityTypeIdentifierDietarySodium:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) mg"

        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return SampleFormatter.calorieFormatter.stringFromValue(quantity, unit: .Kilocalorie)

        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) miles"

        case HKQuantityTypeIdentifierDietaryWater:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) ml"

        case HKQuantityTypeIdentifierHeartRate:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) bpm"

        case HKQuantityTypeIdentifierStepCount:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) steps"

        case HKQuantityTypeIdentifierUVExposure:
            return "\(SampleFormatter.numberFormatter.stringFromNumber(quantity)!) hours"
            
        default:
            return SampleFormatter.numberFormatter.stringFromNumber(quantity) ?? "<nil>"
        }
    }
}