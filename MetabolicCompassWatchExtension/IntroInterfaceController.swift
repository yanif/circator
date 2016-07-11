//
//  IntroInterfaceController.swift
//  CircatorWatch Extension
//
//  Created by Mariano on 3/2/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import WatchKit
import WatchConnectivity
import Foundation
import HealthKit
import ClockKit

protocol MCSample {
    var startDate    : NSDate        { get }
    var endDate      : NSDate        { get }
    var numeralValue : Double?       { get }
    var defaultUnit  : HKUnit?       { get }
    var hkType       : HKSampleType? { get }
}

struct MCAggregateSample : MCSample {
    var startDate    : NSDate
    var endDate      : NSDate
    var numeralValue : Double?
    var defaultUnit  : HKUnit?
    var hkType       : HKSampleType?
    
    var avgTotal: Double = 0.0
    var avgCount: Int = 0
    
    init(sample: MCSample) {
        startDate = sample.startDate
        endDate = sample.endDate
        numeralValue = nil
        defaultUnit = nil
        hkType = sample.hkType
        self.incr(sample)
    }
    
    init(value: Double?, sampleType: HKSampleType?) {
        startDate = NSDate()
        endDate = NSDate()
        numeralValue = value
        defaultUnit = sampleType?.defaultUnit
        hkType = sampleType
    }
    
    mutating func incr(sample: MCSample) {
        if hkType == sample.hkType {
            startDate = sample.startDate.earlierDate(startDate)
            endDate = sample.endDate.laterDate(endDate)
            
            switch hkType!.identifier {
            case HKCategoryTypeIdentifierSleepAnalysis:
                avgTotal += sample.numeralValue!
                avgCount += 1
                
            case HKCorrelationTypeIdentifierBloodPressure:
                avgTotal += sample.numeralValue!
                avgCount += 1
                
            case HKQuantityTypeIdentifierActiveEnergyBurned:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!
                
            case HKQuantityTypeIdentifierBasalEnergyBurned:
                avgTotal += sample.numeralValue!
                avgCount += 1
                
            case HKQuantityTypeIdentifierBloodGlucose:
                avgTotal += sample.numeralValue!
                avgCount += 1
                
            case HKQuantityTypeIdentifierBloodPressureSystolic:
                avgTotal += sample.numeralValue!
                avgCount += 1
                
            case HKQuantityTypeIdentifierBloodPressureDiastolic:
                avgTotal += sample.numeralValue!
                avgCount += 1
                
            case HKQuantityTypeIdentifierBodyMass:
                avgTotal += sample.numeralValue!
                avgCount += 1
                
            case HKQuantityTypeIdentifierBodyMassIndex:
                avgTotal += sample.numeralValue!
                avgCount += 1
                
            case HKQuantityTypeIdentifierDietaryCaffeine:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!
                
            case HKQuantityTypeIdentifierDietaryCarbohydrates:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!
                
            case HKQuantityTypeIdentifierDietaryCholesterol:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!
                
            case HKQuantityTypeIdentifierDietaryEnergyConsumed:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!
                
            case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!
                
            case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!
                
            case HKQuantityTypeIdentifierDietaryFatSaturated:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!
                
            case HKQuantityTypeIdentifierDietaryFatTotal:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!
                
            case HKQuantityTypeIdentifierDietaryProtein:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!
                
            case HKQuantityTypeIdentifierDietarySodium:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!
                
            case HKQuantityTypeIdentifierDietarySugar:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!
                
            case HKQuantityTypeIdentifierDietaryWater:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!
                
            case HKQuantityTypeIdentifierDistanceWalkingRunning:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!
                
            case HKQuantityTypeIdentifierFlightsClimbed:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!
                
            case HKQuantityTypeIdentifierHeartRate:
                avgTotal += sample.numeralValue!
                avgCount += 1
                
            case HKQuantityTypeIdentifierStepCount:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!
                
            case HKQuantityTypeIdentifierUVExposure:
                avgTotal += sample.numeralValue!
                avgCount += 1
                
            case HKWorkoutTypeIdentifier:
                numeralValue = (numeralValue ?? 0.0) + sample.numeralValue!
                
            default:
                print("Cannot aggregate \(hkType)")
            }
            
        } else {
            print("Invalid sample aggregation between \(hkType) and \(sample.hkType)")
        }
    }
    
    mutating func final() {
        switch hkType!.identifier {
        case HKCategoryTypeIdentifierSleepAnalysis:
            numeralValue = avgTotal / Double(avgCount)
            
        case HKCorrelationTypeIdentifierBloodPressure:
            numeralValue = avgTotal / Double(avgCount)
            
        case HKQuantityTypeIdentifierBasalEnergyBurned:
            numeralValue = avgTotal / Double(avgCount)
            
        case HKQuantityTypeIdentifierBloodGlucose:
            numeralValue = avgTotal / Double(avgCount)
            
        case HKQuantityTypeIdentifierBloodPressureSystolic:
            numeralValue = avgTotal / Double(avgCount)
            
        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            numeralValue = avgTotal / Double(avgCount)
            
        case HKQuantityTypeIdentifierBodyMass:
            numeralValue = avgTotal / Double(avgCount)
            
        case HKQuantityTypeIdentifierBodyMassIndex:
            numeralValue = avgTotal / Double(avgCount)
            
        case HKQuantityTypeIdentifierHeartRate:
            numeralValue = avgTotal / Double(avgCount)
            
        case HKQuantityTypeIdentifierUVExposure:
            numeralValue = avgTotal / Double(avgCount)
            
        default:
            ()
        }
    }
}
extension HKStatistics: MCSample { }
extension HKSample: MCSample { }

public extension HKStatistics {
    var quantity: HKQuantity? {
        switch quantityType.identifier {
            
        case HKCategoryTypeIdentifierSleepAnalysis:
            return averageQuantity()
            
        case HKCorrelationTypeIdentifierBloodPressure:
            return sumQuantity()
            
        case HKQuantityTypeIdentifierActiveEnergyBurned:
            return sumQuantity()
            
        case HKQuantityTypeIdentifierBasalEnergyBurned:
            return averageQuantity()
            
        case HKQuantityTypeIdentifierBodyMass:
            return averageQuantity()
            
        case HKQuantityTypeIdentifierBodyMassIndex:
            return averageQuantity()
            
        case HKQuantityTypeIdentifierBloodGlucose:
            return sumQuantity()
            
        case HKQuantityTypeIdentifierBloodPressureSystolic:
            return sumQuantity()
            
        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            return sumQuantity()
            
        case HKQuantityTypeIdentifierDietaryCaffeine:
            return sumQuantity()
            
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return sumQuantity()
            
        case HKQuantityTypeIdentifierDietaryCholesterol:
            return sumQuantity()
            
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return sumQuantity()
            
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return sumQuantity()
            
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return sumQuantity()
            
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return sumQuantity()
            
        case HKQuantityTypeIdentifierDietaryFatTotal:
            return sumQuantity()
            
        case HKQuantityTypeIdentifierDietaryProtein:
            return sumQuantity()
            
        case HKQuantityTypeIdentifierDietarySodium:
            return sumQuantity()
            
        case HKQuantityTypeIdentifierDietarySugar:
            return sumQuantity()
            
        case HKQuantityTypeIdentifierDietaryWater:
            return sumQuantity()
            
        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            return sumQuantity()
            
        case HKQuantityTypeIdentifierFlightsClimbed:
            return sumQuantity()
            
        case HKQuantityTypeIdentifierHeartRate:
            return averageQuantity()
            
        case HKQuantityTypeIdentifierStepCount:
            return sumQuantity()
            
        case HKQuantityTypeIdentifierUVExposure:
            return sumQuantity()
            
        case HKWorkoutTypeIdentifier:
            return sumQuantity()
            
        default:
            print("Invalid quantity type \(quantityType.identifier) for HKStatistics")
            return sumQuantity()
        }
    }
    
    public var numeralValue: Double? {
        guard defaultUnit != nil && quantity != nil else {
            return nil
        }
        switch quantityType.identifier {
        case HKCategoryTypeIdentifierSleepAnalysis:
            fallthrough
        case HKCorrelationTypeIdentifierBloodPressure:
            fallthrough
        case HKQuantityTypeIdentifierActiveEnergyBurned:
            fallthrough
        case HKQuantityTypeIdentifierBasalEnergyBurned:
            fallthrough
        case HKQuantityTypeIdentifierBloodGlucose:
            fallthrough
        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            fallthrough
        case HKQuantityTypeIdentifierBloodPressureSystolic:
            fallthrough
        case HKQuantityTypeIdentifierBodyMass:
            fallthrough
        case HKQuantityTypeIdentifierBodyMassIndex:
            fallthrough
        case HKQuantityTypeIdentifierDietaryCaffeine:
            fallthrough
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            fallthrough
        case HKQuantityTypeIdentifierDietaryCholesterol:
            fallthrough
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
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
        case HKQuantityTypeIdentifierDietarySodium:
            fallthrough
        case HKQuantityTypeIdentifierDietarySugar:
            fallthrough
        case HKQuantityTypeIdentifierDietaryWater:
            fallthrough
        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            fallthrough
        case HKQuantityTypeIdentifierFlightsClimbed:
            fallthrough
        case HKQuantityTypeIdentifierHeartRate:
            fallthrough
        case HKQuantityTypeIdentifierStepCount:
            fallthrough
        case HKQuantityTypeIdentifierUVExposure:
            fallthrough
        case HKWorkoutTypeIdentifier:
            return quantity!.doubleValueForUnit(defaultUnit!)
        default:
            return nil
        }
    }
    
    public var defaultUnit: HKUnit? { return quantityType.defaultUnit }
    
    public var hkType: HKSampleType? { return quantityType }
}

public extension HKSample {
    public var numeralValue: Double? {
        guard defaultUnit != nil else {
            return nil
        }
        switch sampleType.identifier {
        case HKCategoryTypeIdentifierSleepAnalysis:
            let sample = (self as! HKCategorySample)
            let secs = HKQuantity(unit: HKUnit.secondUnit(), doubleValue: sample.endDate.timeIntervalSinceDate(sample.startDate))
            return secs.doubleValueForUnit(defaultUnit!)
            
        case HKCorrelationTypeIdentifierBloodPressure:
            return ((self as! HKCorrelation).objects.first as! HKQuantitySample).quantity.doubleValueForUnit(defaultUnit!)
            
        case HKQuantityTypeIdentifierActiveEnergyBurned:
            fallthrough
            
        case HKQuantityTypeIdentifierBasalEnergyBurned:
            fallthrough
            
        case HKQuantityTypeIdentifierBloodGlucose:
            fallthrough
            
        case HKQuantityTypeIdentifierBloodPressureSystolic:
            fallthrough
            
        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            fallthrough
            
        case HKQuantityTypeIdentifierBodyMass:
            fallthrough
            
        case HKQuantityTypeIdentifierBodyMassIndex:
            fallthrough
            
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            fallthrough
            
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            fallthrough
            
        case HKQuantityTypeIdentifierDietaryProtein:
            fallthrough
            
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            fallthrough
            
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            fallthrough
            
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            fallthrough
            
        case HKQuantityTypeIdentifierDietaryFatTotal:
            fallthrough
            
        case HKQuantityTypeIdentifierDietarySugar:
            fallthrough
            
        case HKQuantityTypeIdentifierDietarySodium:
            fallthrough
            
        case HKQuantityTypeIdentifierDietaryCaffeine:
            fallthrough
            
        case HKQuantityTypeIdentifierDietaryWater:
            fallthrough
            
        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            fallthrough
            
        case HKQuantityTypeIdentifierFlightsClimbed:
            fallthrough
            
        case HKQuantityTypeIdentifierHeartRate:
            fallthrough
            
        case HKQuantityTypeIdentifierStepCount:
            fallthrough
            
        case HKQuantityTypeIdentifierUVExposure:
            return (self as! HKQuantitySample).quantity.doubleValueForUnit(defaultUnit!)
            
        case HKWorkoutTypeIdentifier:
            let sample = (self as! HKWorkout)
            let secs = HKQuantity(unit: HKUnit.secondUnit(), doubleValue: sample.duration)
            return secs.doubleValueForUnit(defaultUnit!)
            
        default:
            return nil
        }
    }
    
    public var allNumeralValues: [Double]? {
        return numeralValue != nil ? [numeralValue!] : nil
    }
    
    public var defaultUnit: HKUnit? { return sampleType.defaultUnit }
    
    public var hkType: HKSampleType? { return sampleType }
}

public extension HKSampleType {
    public var displayText: String? {
        switch identifier {
        case HKCategoryTypeIdentifierSleepAnalysis:
            return NSLocalizedString("Sleep", comment: "HealthKit data type")
            
        case HKCorrelationTypeIdentifierBloodPressure:
            return NSLocalizedString("Blood pressure", comment: "HealthKit data type")
            
        case HKQuantityTypeIdentifierActiveEnergyBurned:
            return NSLocalizedString("Active Energy Burned", comment: "HealthKit data type")
            
        case HKQuantityTypeIdentifierBasalEnergyBurned:
            return NSLocalizedString("Basal Energy Burned", comment: "HealthKit data type")
            
        case HKQuantityTypeIdentifierBloodGlucose:
            return NSLocalizedString("Blood Glucose", comment: "HealthKit data type")
            
        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            return NSLocalizedString("Blood Pressure Diastolic", comment: "HealthKit data type")
            
        case HKQuantityTypeIdentifierBloodPressureSystolic:
            return NSLocalizedString("Blood Pressure Systolic", comment: "HealthKit data type")
            
        case HKQuantityTypeIdentifierBodyMass:
            return NSLocalizedString("Weight", comment: "HealthKit data type")
            
        case HKQuantityTypeIdentifierBodyMassIndex:
            return NSLocalizedString("Body Mass Index", comment: "HealthKit data type")
            
        case HKQuantityTypeIdentifierDietaryCaffeine:
            return NSLocalizedString("Caffeine", comment: "HealthKit data type")
            
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return NSLocalizedString("Carbohydrates", comment: "HealthKit data type")
            
        case HKQuantityTypeIdentifierDietaryCholesterol:
            return NSLocalizedString("Cholesterol", comment: "HealthKit data type")
            
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return NSLocalizedString("Food calories", comment: "HealthKit data type")
            
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return NSLocalizedString("Monounsaturated Fat", comment: "HealthKit data type")
            
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return NSLocalizedString("Polyunsaturated Fat", comment: "HealthKit data type")
            
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return NSLocalizedString("Saturated Fat", comment: "HealthKit data type")
            
        case HKQuantityTypeIdentifierDietaryFatTotal:
            return NSLocalizedString("Fat", comment: "HealthKit data type")
            
        case HKQuantityTypeIdentifierDietaryProtein:
            return NSLocalizedString("Protein", comment: "HealthKit data type")
            
        case HKQuantityTypeIdentifierDietarySodium:
            return NSLocalizedString("Salt", comment: "HealthKit data type")
            
        case HKQuantityTypeIdentifierDietarySugar:
            return NSLocalizedString("Sugar", comment: "HealthKit data type")
            
        case HKQuantityTypeIdentifierDietaryWater:
            return NSLocalizedString("Water", comment: "HealthKit data type")
            
        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            return NSLocalizedString("Walking and Running Distance", comment: "HealthKit data type")
            
        case HKQuantityTypeIdentifierFlightsClimbed:
            return NSLocalizedString("Flights Climbed", comment: "HealthKit data type")
            
        case HKQuantityTypeIdentifierHeartRate:
            return NSLocalizedString("Heartrate", comment: "HealthKit data type")
            
        case HKQuantityTypeIdentifierStepCount:
            return NSLocalizedString("Step Count", comment: "HealthKit data type")
            
        case HKQuantityTypeIdentifierUVExposure:
            return NSLocalizedString("UV Exposure", comment: "HealthKit data type")
            
        case HKWorkoutTypeIdentifier:
            return NSLocalizedString("Workouts/Meals", comment: "HealthKit data type")
            
        default:
            return nil
        }
    }
    
    public var defaultUnit: HKUnit? {
        let isMetric: Bool = NSLocale.currentLocale().objectForKey(NSLocaleUsesMetricSystem)!.boolValue
        switch identifier {
        case HKCategoryTypeIdentifierSleepAnalysis:
            return HKUnit.hourUnit()
            
        case HKCorrelationTypeIdentifierBloodPressure:
            return HKUnit.millimeterOfMercuryUnit()
            
        case HKQuantityTypeIdentifierActiveEnergyBurned:
            return HKUnit.kilocalorieUnit()
            
        case HKQuantityTypeIdentifierBasalEnergyBurned:
            return HKUnit.kilocalorieUnit()
            
        case HKQuantityTypeIdentifierBloodGlucose:
            return HKUnit.gramUnitWithMetricPrefix(.Milli).unitDividedByUnit(HKUnit.literUnitWithMetricPrefix(.Deci))
            
        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            return HKUnit.millimeterOfMercuryUnit()
            
        case HKQuantityTypeIdentifierBloodPressureSystolic:
            return HKUnit.millimeterOfMercuryUnit()
            
        case HKQuantityTypeIdentifierBodyMass:
            return isMetric ? HKUnit.gramUnitWithMetricPrefix(.Kilo) : HKUnit.poundUnit()
            
        case HKQuantityTypeIdentifierBodyMassIndex:
            return HKUnit.countUnit()
            
        case HKQuantityTypeIdentifierDietaryCaffeine:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)
            
        case HKQuantityTypeIdentifierDietaryCarbohydrates:
            return HKUnit.gramUnit()
            
        case HKQuantityTypeIdentifierDietaryCholesterol:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)
            
        case HKQuantityTypeIdentifierDietaryEnergyConsumed:
            return HKUnit.kilocalorieUnit()
            
        case HKQuantityTypeIdentifierDietaryFatMonounsaturated:
            return HKUnit.gramUnit()
            
        case HKQuantityTypeIdentifierDietaryFatPolyunsaturated:
            return HKUnit.gramUnit()
            
        case HKQuantityTypeIdentifierDietaryFatSaturated:
            return HKUnit.gramUnit()
            
        case HKQuantityTypeIdentifierDietaryFatTotal:
            return HKUnit.gramUnit()
            
        case HKQuantityTypeIdentifierDietaryProtein:
            return HKUnit.gramUnit()
            
        case HKQuantityTypeIdentifierDietarySodium:
            return HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli)
            
        case HKQuantityTypeIdentifierDietarySugar:
            return HKUnit.gramUnit()
            
        case HKQuantityTypeIdentifierDietaryWater:
            return HKUnit.literUnitWithMetricPrefix(HKMetricPrefix.Milli)
            
        case HKQuantityTypeIdentifierDistanceWalkingRunning:
            return HKUnit.mileUnit()
            
        case HKQuantityTypeIdentifierFlightsClimbed:
            return HKUnit.countUnit()
            
        case HKQuantityTypeIdentifierHeartRate:
            return HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit())
            
        case HKQuantityTypeIdentifierStepCount:
            return HKUnit.countUnit()
            
        case HKQuantityTypeIdentifierUVExposure:
            return HKUnit.countUnit()
            
        case HKWorkoutTypeIdentifier:
            return HKUnit.hourUnit()
            
        default:
            return nil
        }
    }
}

let stWorkout = 0.0
let stSleep = 0.33
let stFast = 0.66
let stEat = 1.0

let refDate  = NSDate(timeIntervalSinceReferenceDate: 0)
let noLimit  = Int(HKObjectQueryNoLimit)
let noAnchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
let dateAsc  = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
let dateDesc = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

class IntroInterfaceController: WKInterfaceController, WCSessionDelegate  {
    
    var heightHK, weightHK:HKQuantitySample?
    var proteinHK, fatHK, carbHK:HKQuantitySample?
    var bmiHK:Double = 22.1
    let kUnknownString   = "Unknown"
    let HMErrorDomain                        = "HMErrorDomain"
    
    var HKBMIString:String = "24.3"
    var weightLocalizedString:String = "151 lb"
    var heightLocalizedString:String = "5 ft"
    var proteinLocalizedString:String = "50 gms"
    typealias HMTypedSampleBlock    = (samples: [HKSampleType: [MCSample]], error: NSError?) -> Void
    typealias HMCircadianBlock          = (intervals: [(NSDate, CircadianEvent)], error: NSError?) -> Void
    typealias HMCircadianAggregateBlock = (aggregates: [(NSDate, Double)], error: NSError?) -> Void
    typealias HMFastingCorrelationBlock = ([(NSDate, Double, MCSample)], NSError?) -> Void
    typealias HMSampleBlock         = (samples: [MCSample], error: NSError?) -> Void
    enum CircadianEvent {
        case Meal
        case Fast
        case Sleep
        case Exercise
    }

    
    var session : WCSession!
    
    let healthKitStore:HKHealthStore = HKHealthStore()
    //    var healthConditions: HealthConditions = HealthConditions.loadConditions()
    //    var healthMetrics: HealthMetrics
    //    var healthMetrics: HealthMetrics = HealthMetrics.loadConditions()
    
    override init() {
        super.init()
        if (WCSession.isSupported()) {
            session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
        }
    }
    
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        // get values from app context
        let displayDate = (applicationContext["dateKey"] as? String)
        
        // save to user defaults
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(displayDate, forKey: "dateKey")
    }
    
    func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        if let dateString = userInfo["dateKey"] as? String {
            
            // save new value to user defaults
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setObject(dateString, forKey: "dateKey")
            
        }
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        func reloadComplications() {
            let server = CLKComplicationServer.sharedInstance()
            //        print("in reloadComplications: \(server.activeComplications)")
            guard let complications = server.activeComplications where complications.count > 0 else {
                print("hit a zero in reloadComplications")
                return
            }
            
            for complication in complications  {
                server.extendTimelineForComplication(complication)
                print("value from complication: \(complication.description)")
                //            print("value from complication: \(complications.)")
            }
        }

        
        print("ready to run reloadDataTake2")
        reloadDataTake2()
        
        reloadComplications()
        
        /*
         func reloadComplications() {
         let server = CLKComplicationServer.sharedInstance()
         print("in reloadComplications: \(server.activeComplications)")
         guard let complications = server.activeComplications where complications.count > 0 else {
         print("hit a zero in reloadComplications")
         return
         }
         
         for complication in complications  {
         server.reloadTimelineForComplication(complication)
         }
         }
         */
        //        reloadComplications()
        
        
        //        HealthMetrics.updateWeight()
        //        var healthMetrics: HealthMetrics
        //        HealthMetrics.updateHealthInfo(healthMetrics)
    }
    
    override func didDeactivate() {
        super.didDeactivate()

        func readMostRecentSample(sampleType:HKSampleType , completion:     ((HKSample!, NSError!) -> Void)!)
        {
            let past = NSDate.distantPast()
            let now   = NSDate()
            let mostRecentPredicate = HKQuery.predicateForSamplesWithStartDate(past, endDate:now, options: .None)
            let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
            let limit = 1
            let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: limit, sortDescriptors: [sortDescriptor])
            { (sampleQuery, results, error ) -> Void in
                guard error == nil else {
                    completion(nil,error)
                    return;
                }
                let mostRecentSample = results!.first as? HKQuantitySample
                if completion != nil {
                    completion(mostRecentSample,nil)
                }
            }
            self.healthKitStore.executeQuery(sampleQuery)
        }
        
        func updateWeight()
        {
            let sampleType = HKSampleType.quantityTypeForIdentifier (HKQuantityTypeIdentifierBodyMass)
            
            readMostRecentSample(sampleType!, completion: { (mostRecentWeight, error) -> Void in
                
                if( error != nil )
                {
                    print("Error reading weight from HealthKit Store: \(error.localizedDescription)")
                    return;
                }
                
                //                var weightLocalizedString = self.kUnknownString;
                self.weightHK = mostRecentWeight as? HKQuantitySample;
                if let kilograms = self.weightHK?.quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo)) {
                    let weightFormatter = NSMassFormatter()
                    weightFormatter.forPersonMassUse = true;
                    self.weightLocalizedString = weightFormatter.stringFromKilograms(kilograms)
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    updateBMI()
                    print("in weight update of interface controller: \(self.weightLocalizedString)")
                });
            });
        }
        
        func updateHeight()
        {
            let sampleType = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)
            readMostRecentSample(sampleType!, completion: { (mostRecentHeight, error) -> Void in
                
                if( error != nil )
                {
                    print("Error reading height from HealthKit Store: \(error.localizedDescription)")
                    return;
                }
                
                //                var heightLocalizedString = self.kUnknownString;
                self.heightHK = mostRecentHeight as? HKQuantitySample;
                if let meters = self.heightHK?.quantity.doubleValueForUnit(HKUnit.meterUnit()) {
                    let heightFormatter = NSLengthFormatter()
                    heightFormatter.forPersonHeightUse = true;
                    self.heightLocalizedString = heightFormatter.stringFromMeters(meters);
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    print("in height update of interface controller: \(self.heightLocalizedString)")
                    updateBMI()
                });
            })
        }
        
        func calculateBMIWithWeightInKilograms(weightInKilograms:Double, heightInMeters:Double) -> Double?
        {
            if heightInMeters == 0 {
                return nil;
            }
            return (weightInKilograms/(heightInMeters*heightInMeters));
        }
        
        func updateBMI()
        {
            if weightHK != nil && heightHK != nil {
                let weightInKilograms = weightHK!.quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo))
                let heightInMeters = heightHK!.quantity.doubleValueForUnit(HKUnit.meterUnit())
                bmiHK = calculateBMIWithWeightInKilograms(weightInKilograms, heightInMeters: heightInMeters)!
            }
            print("new bmi in IntroInterfaceController: \(bmiHK)")
            HKBMIString = String(format: "%.1f", bmiHK)
        }
        
        func updateProtein()
        {
            let sampleType = HKSampleType.quantityTypeForIdentifier (HKQuantityTypeIdentifierDietaryProtein)
            
            readMostRecentSample(sampleType!, completion: { (mostRecentProtein, error) -> Void in
                
                if( error != nil )
                {
                    print("Error reading dietary protein from HealthKit Store: \(error.localizedDescription)")
                    return;
                }
            
                self.proteinHK = mostRecentProtein as? HKQuantitySample;
                if let grams = self.proteinHK?.quantity.doubleValueForUnit(HKUnit.gramUnit()) {
//                    let weightFormatter = NSMassFormatter()
//                    self.proteinLocalizedString = weightFormatter.unitStringFromValue(grams, unit: HKUnit.gramUnit)
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    print("in protein update of interface controller: \(self.proteinLocalizedString)")
                });
            });
        }
        
        func updateHealthInfo() {
            updateWeight();
            print("updated weight info")
            updateHeight();
            print("updated height info")
            updateBMI();
            print("updated bmi info")
        }
        
        updateHealthInfo()

        MetricsStore.sharedInstance.weight = weightLocalizedString
        MetricsStore.sharedInstance.BMI = HKBMIString
        MetricsStore.sharedInstance.Fat = "90"
        MetricsStore.sharedInstance.Carbohydrate = "190"
        MetricsStore.sharedInstance.Protein = "290"
        
    }
    
    
    func reloadDataTake2() {
        typealias Event = (NSDate, Double)
        typealias IEvent = (Double, Double)?
        
        let yesterday = NSDate().dateByAddingTimeInterval(-(24*60.0*60.0))
        let startDate = yesterday
        
        fetchCircadianEventIntervals(startDate) { (intervals, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                guard error == nil else {
                    print("Failed to fetch circadian events: \(error)")
                    return
                }
                
                if intervals.isEmpty {
                    print("series is Empty")
                    
                } else {
                    
                    let vals : [(x: Double, y: Double)] = intervals.map { event in
                        let startTimeInFractionalHours = event.0.timeIntervalSinceDate(startDate) / 3600.0
                        let metabolicStateAsDouble = self.valueOfCircadianEvent(event.1)
                        return (x: startTimeInFractionalHours, y: metabolicStateAsDouble)
                    }
                    
                    let initialAccumulator : (Double, Double, Double, IEvent, Bool, Double, Bool) =
                        (0.0, 0.0, 0.0, nil, true, 0.0, false)
                    
                    let stats = vals.filter { $0.0 >= yesterday.timeIntervalSinceDate(startDate) }
                        .reduce(initialAccumulator, combine:
                            { (acc, event) in
                                // Named accumulator components
                                var newEatingTime = acc.0
                                let lastEatingTime = acc.1
                                var maxFastingWindow = acc.2
                                var currentFastingWindow = acc.5
                                
                                // Named components from the current event.
                                let eventEndpointDate = event.0
                                let eventMetabolicState = event.1
                                
                                let prevEvent = acc.3
                                let prevEndpointWasIntervalEnd = !acc.4
                                var prevStateWasFasting = acc.6
                                let isFasting = eventMetabolicState != stEat
                                if prevEndpointWasIntervalEnd {
                                    let prevEventEndpointDate = prevEvent!.0
                                    let duration = eventEndpointDate - prevEventEndpointDate
                                    
                                    if prevStateWasFasting && isFasting {
                                        currentFastingWindow += duration
                                        maxFastingWindow = maxFastingWindow > currentFastingWindow ? maxFastingWindow : currentFastingWindow
                                        
                                    } else if isFasting {
                                        currentFastingWindow = duration
                                        maxFastingWindow = maxFastingWindow > currentFastingWindow ? maxFastingWindow : currentFastingWindow
                                        
                                    } else if eventMetabolicState == stEat {
                                        newEatingTime += duration
                                    }
                                } else {
                                    prevStateWasFasting = prevEvent == nil ? false : prevEvent!.1 != stEat
                                }
                                
                                let newLastEatingTime = eventMetabolicState == stEat ? eventEndpointDate : lastEatingTime
                                
                                // Return a new accumulator.
                                return (
                                    newEatingTime,
                                    newLastEatingTime,
                                    maxFastingWindow,
                                    event,
                                    prevEndpointWasIntervalEnd,
                                    currentFastingWindow,
                                    prevStateWasFasting
                                )
                        })

                    let calendar = NSCalendar.currentCalendar()

                    let todayComponents = calendar.components([.Year, .Month, .Day], fromDate: NSDate())
                    let today = calendar.dateFromComponents(todayComponents)!

                    let dateFormatter = NSDateFormatter()
                    dateFormatter.dateFormat = "mm"
                    dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle

                    let fastingHrs = Int(floor(stats.2))
                    let todayPlusMins = today.dateByAddingTimeInterval(round((stats.2 % 1.0) * 60.0 * 60.0))
                    let fastingMins = dateFormatter.stringFromDate(todayPlusMins)

                    MetricsStore.sharedInstance.fastingTime = "\(fastingHrs):\(fastingMins)"
                }
            })
        }
    }
    
    func fetchCircadianEventIntervals(startDate: NSDate = NSDate().dateByAddingTimeInterval(-(24*60.0*60.0)),
                                      endDate: NSDate = NSDate(),
                                      completion: HMCircadianBlock)
    {
        typealias Event = (NSDate, CircadianEvent)
        typealias IEvent = (Double, CircadianEvent)
        
        let sleepTy = HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!
        let workoutTy = HKWorkoutType.workoutType()
        let datePredicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: .None)
        let typesAndPredicates = [sleepTy: datePredicate, workoutTy: datePredicate]
        
        fetchSamples(typesAndPredicates) { (events, error) -> Void in
            guard error == nil && !events.isEmpty else {
                completion(intervals: [], error: error)
                return
            }
            let extendedEvents = events.flatMap { (ty,vals) -> [Event]? in
                switch ty {
                case is HKWorkoutType:
                    return vals.flatMap { s -> [Event] in
                        let st = s.startDate.laterDate(startDate)
                        let en = s.endDate
                        guard let v = s as? HKWorkout else { return [] }
                        switch v.workoutActivityType {
                        case HKWorkoutActivityType.PreparationAndRecovery:
                            return [(st, .Meal), (en, .Meal)]
                        default:
                            return [(st, .Exercise), (en, .Exercise)]
                        }
                    }
                    
                case is HKCategoryType:
                    guard ty.identifier == HKCategoryTypeIdentifierSleepAnalysis else {
                        return nil
                    }
                    return vals.flatMap { s -> [Event] in
                        let st = s.startDate.laterDate(startDate)
                        let en = s.endDate
                        return [(st, .Sleep), (en, .Sleep)]
                    }
                    
                default:
                    print("Unexpected type \(ty.identifier) while fetching circadian event intervals")
                    return nil
                }
            }
            
            let sortedEvents = extendedEvents.flatten().sort { (a,b) in return a.0.compare(b.0) == .OrderedAscending }
            let epsilon = 1.0 // in seconds.
            let lastev = sortedEvents.last ?? sortedEvents.first!
            let lst = lastev.0 == endDate ? [] : [(lastev.0, CircadianEvent.Fast), (endDate, CircadianEvent.Fast)]
            
            
            let initialAccumulator : ([Event], Bool, Event!) = ([], true, nil)
            let endpointArray = sortedEvents.reduce(initialAccumulator, combine:
                { (acc, event) in
                    let eventEndpointDate = event.0
                    let eventMetabolicState = event.1
                    
                    let resultArray = acc.0
                    let eventIsIntervalStart = acc.1
                    let prevEvent = acc.2
                    
                    let nextEventAsIntervalStart = !acc.1
                    
                    guard prevEvent != nil else {
                        // Skip prefix indicates whether we should add a fasting interval before the first event.
                        let skipPrefix = eventEndpointDate == startDate || startDate == NSDate.distantPast()
                        let newResultArray = (skipPrefix ? [event] : [(startDate, CircadianEvent.Fast), (eventEndpointDate, CircadianEvent.Fast), event])
                        return (newResultArray, nextEventAsIntervalStart, event)
                    }
                    
                    let prevEventEndpointDate = prevEvent.0
                    
                    if (eventIsIntervalStart && prevEventEndpointDate == eventEndpointDate) {
                        let newResult = resultArray + [(eventEndpointDate.dateByAddingTimeInterval(1), eventMetabolicState)]
                        return (newResult, nextEventAsIntervalStart, event)
                    } else if eventIsIntervalStart {
                        
                        let fastEventStart = prevEventEndpointDate.dateByAddingTimeInterval(epsilon)
                        let modifiedEventEndpoint = eventEndpointDate.dateByAddingTimeInterval(-epsilon)
                        let fastEventEnd = fastEventStart.compare(modifiedEventEndpoint.dateByAddingTimeInterval(-(24*60.0*60.0))) == .OrderedAscending ?
                                                fastEventStart.dateByAddingTimeInterval(24 * 60.0 * 60.0) : modifiedEventEndpoint
                        let newResult = resultArray + [(fastEventStart, .Fast), (fastEventEnd, .Fast), event]
                        return (newResult, nextEventAsIntervalStart, event)
                    } else {
                        
                        return (resultArray + [event], nextEventAsIntervalStart, event)
                    }
            }).0 + lst  // Add the final fasting event to the event endpoint array.
            
            completion(intervals: endpointArray, error: error)
        }
    }
    
    func fetchSamples(typesAndPredicates: [HKSampleType: NSPredicate?], completion: HMTypedSampleBlock)
    {
        let group = dispatch_group_create()
        var samplesByType = [HKSampleType: [MCSample]]()
        
        typesAndPredicates.forEach { (type, predicate) -> () in
            dispatch_group_enter(group)
            fetchSamplesOfType(type, predicate: predicate, limit: noLimit) { (samples, error) in
                guard error == nil else {
                    //                        print("Could not fetch recent samples for \(type.displayText): \(error)")
                    dispatch_group_leave(group)
                    return
                }
                guard samples.isEmpty == false else {
                    //                        print("No recent samples available for \(type.displayText)")
                    dispatch_group_leave(group)
                    return
                }
                samplesByType[type] = samples
                dispatch_group_leave(group)
            }
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) {
            // TODO: partial error handling, i.e., when a subset of the desired types fail in their queries.
            completion(samples: samplesByType, error: nil)
        }
    }
    
    func valueOfCircadianEvent(e: CircadianEvent) -> Double {
        switch e {
        case .Meal:
            return stEat
            
        case .Fast:
            return stFast
            
        case .Exercise:
            return stWorkout
            
        case .Sleep:
            return stSleep
        }
    }
    
    
    func fetchSamplesOfType(sampleType: HKSampleType, predicate: NSPredicate? = nil, limit: Int = noLimit,
                            sortDescriptors: [NSSortDescriptor]? = [dateAsc], completion: HMSampleBlock)
    {
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: limit, sortDescriptors: sortDescriptors) {
            (query, samples, error) -> Void in
            guard error == nil else {
                completion(samples: [], error: error)
                return
            }
            completion(samples: samples ?? [], error: nil)
        }
        healthKitStore.executeQuery(query)
    }
    
    // Query food diary events stored as prep and recovery workouts in HealthKit
    func fetchPreparationAndRecoveryWorkout(oldestFirst: Bool, beginDate: NSDate? = nil, completion: HMSampleBlock)
    {
        let predicate = mealsSincePredicate(beginDate)
        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: oldestFirst)
        fetchSamplesOfType(HKWorkoutType.workoutType(), predicate: predicate, limit: noLimit, sortDescriptors: [sortDescriptor], completion: completion)
    }
    
    func fetchAggregatedCircadianEvents<T>(predicate: ((NSDate, CircadianEvent) -> Bool)? = nil,
                                               aggregator: ((T, (NSDate, CircadianEvent)) -> T), initial: T, final: (T -> [(NSDate, Double)]),
                                               completion: HMCircadianAggregateBlock)
    {
        fetchCircadianEventIntervals(NSDate.distantPast()) { (intervals, error) in
            guard error == nil else {
                completion(aggregates: [], error: error)
                return
            }
            
            let filtered = predicate == nil ? intervals : intervals.filter(predicate!)
            let accum = filtered.reduce(initial, combine: aggregator)
            completion(aggregates: final(accum), error: nil)
        }
    }
    
    func fetchEatingTimes(completion: HMCircadianAggregateBlock) {
        typealias Accum = (Bool, NSDate!, [NSDate: Double])
        let calendar = NSCalendar.currentCalendar()
        let aggregator : (Accum, (NSDate, CircadianEvent)) -> Accum = { (acc, e) in
            if !acc.0 && acc.1 != nil {
                switch e.1 {
                case .Meal:
                    let day = calendar.dateFromComponents(calendar.components([.Year, .Month, .Day], fromDate: acc.1))!
                    var nacc = acc.2
                    nacc.updateValue((acc.2[day] ?? 0.0) + e.0.timeIntervalSinceDate(acc.1!), forKey: day)
                    return (!acc.0, e.0, nacc)
                default:
                    return (!acc.0, e.0, acc.2)
                }
            }
            return (!acc.0, e.0, acc.2)
        }
        let initial : Accum = (true, nil, [:])
        let final : (Accum -> [(NSDate, Double)]) = { acc in
            return acc.2.map { return ($0.0, $0.1 / 3600.0) }.sort { (a,b) in return a.0.compare(b.0) == .OrderedAscending }
        }
        
        fetchAggregatedCircadianEvents(nil, aggregator: aggregator, initial: initial, final: final, completion: completion)
    }
    
    func fetchMaxFastingTimes(completion: HMCircadianAggregateBlock)
    {
        // Accumulator:
        // i. boolean indicating event start.
        // ii. start of this fasting event.
        // iii. the previous event.
        // iv. a dictionary of accumulated fasting intervals.
        typealias Accum = (Bool, NSDate!, NSDate!, [NSDate: Double])
        
        let predicate : (NSDate, CircadianEvent) -> Bool = {
            switch $0.1 {
            case .Exercise, .Fast, .Sleep:
                return true
            default:
                return false
            }
        }
        
        let calendar = NSCalendar.currentCalendar()
        let aggregator : (Accum, (NSDate, CircadianEvent)) -> Accum = { (acc, e) in
            var byDay = acc.3
            let (iStart, prevFast, prevEvt) = (acc.0, acc.1, acc.2)
            var nextFast = prevFast
            if iStart && prevFast != nil && prevEvt != nil && e.0 != prevEvt {
                let fastStartDay = calendar.dateFromComponents(calendar.components([.Year, .Month, .Day], fromDate: prevFast))!
                let duration = prevEvt.timeIntervalSinceDate(prevFast)
                let currentMax = byDay[fastStartDay] ?? duration
                byDay.updateValue(currentMax >= duration ? currentMax : duration, forKey: fastStartDay)
                nextFast = e.0
            } else if iStart && prevFast == nil {
                nextFast = e.0
            }
            return (!acc.0, nextFast, e.0, byDay)
        }
        
        let initial : Accum = (true, nil, nil, [:])
        let final : Accum -> [(NSDate, Double)] = { acc in
            var byDay = acc.3
            if let finalFast = acc.1, finalEvt = acc.2 {
                if finalFast != finalEvt {
                    let fastStartDay = calendar.dateFromComponents(calendar.components([.Year, .Month, .Day], fromDate: finalFast))!
                    let duration = finalEvt.timeIntervalSinceDate(finalFast)
                    let currentMax = byDay[fastStartDay] ?? duration
                    byDay.updateValue(currentMax >= duration ? currentMax : duration, forKey: fastStartDay)
                }
            }
            return byDay.map { return ($0.0, $0.1 / 3600.0) }.sort { (a,b) in return a.0.compare(b.0) == .OrderedAscending }
        }
        
        fetchAggregatedCircadianEvents(predicate, aggregator: aggregator, initial: initial, final: final, completion: completion)
    }
    
    func correlateWithFasting(sortFasting: Bool, type: HKSampleType, predicate: NSPredicate? = nil, completion: HMFastingCorrelationBlock) {
        var results1: [MCSample]?
        var results2: [(NSDate, Double)]?

        let calendar = NSCalendar.currentCalendar()
        func intersect(samples: [MCSample], fasting: [(NSDate, Double)]) -> [(NSDate, Double, MCSample)] {
            var output:[(NSDate, Double, MCSample)] = []
            var byDay: [NSDate: Double] = [:]
            fasting.forEach { f in
                let start = calendar.dateFromComponents(calendar.components([.Year, .Month, .Day], fromDate: f.0))!
                byDay.updateValue((byDay[start] ?? 0.0) + f.1, forKey: start)
            }
            
            samples.forEach { s in
                let start = calendar.dateFromComponents(calendar.components([.Year, .Month, .Day], fromDate: s.startDate))!
                if let match = byDay[start] { output.append((start, match, s)) }
            }
            return output
        }
        
        let group = dispatch_group_create()
        dispatch_group_enter(group)
        fetchStatisticsOfType(type, predicate: predicate) { (results, error) -> Void in
            guard error == nil else {
                completion([], error)
                dispatch_group_leave(group)
                return
            }
            results1 = results
            dispatch_group_leave(group)
        }
        dispatch_group_enter(group)
        fetchMaxFastingTimes { (results, error) -> Void in
            guard error == nil else {
                completion([], error)
                dispatch_group_leave(group)
                return
            }
            results2 = results
            dispatch_group_leave(group)
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) {
            guard !(results1 == nil || results2 == nil) else {
                let desc = results1 == nil ? (results2 == nil ? "LHS and RHS" : "LHS") : "RHS"
                let err = NSError(domain: self.HMErrorDomain, code: 1048576, userInfo: [NSLocalizedDescriptionKey: "Invalid \(desc) statistics"])
                completion([], err)
                return
            }
            var zipped = intersect(results1!, fasting: results2!)
            zipped.sortInPlace { (a,b) in return ( sortFasting ? a.1 < b.1 : a.2.numeralValue! < b.2.numeralValue! ) }
            completion(zipped, nil)
        }
    }
    
    func mealsSincePredicate(startDate: NSDate? = nil, endDate: NSDate = NSDate()) -> NSPredicate? {
        var predicate : NSPredicate? = nil
        if let st = startDate {
            let conjuncts = [
                HKQuery.predicateForSamplesWithStartDate(st, endDate: endDate, options: .None),
                HKQuery.predicateForWorkoutsWithWorkoutActivityType(HKWorkoutActivityType.PreparationAndRecovery)
            ]
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: conjuncts)
        } else {
            predicate = HKQuery.predicateForWorkoutsWithWorkoutActivityType(HKWorkoutActivityType.PreparationAndRecovery)
        }
        return predicate
    }
    
    func fetchStatisticsOfType(sampleType: HKSampleType, predicate: NSPredicate? = nil, completion: HMSampleBlock) {
        switch sampleType {
        case is HKCategoryType:
            fallthrough
            
        case is HKCorrelationType:
            fallthrough
            
        case is HKWorkoutType:
            fetchAggregatedSamplesOfType(sampleType, predicate: predicate, completion: completion)
            
        case is HKQuantityType:
            let calendar = NSCalendar.currentCalendar()
            let interval = NSDateComponents()
            interval.day = 1
            
            // Set the anchor date to midnight today.
            let anchorDate = calendar.dateFromComponents(calendar.components([.Year, .Month, .Day], fromDate: NSDate()))!

            let quantityType = HKObjectType.quantityTypeForIdentifier(sampleType.identifier)!
            
            // Create the query
            let query = HKStatisticsCollectionQuery(quantityType: quantityType,
                                                    quantitySamplePredicate: predicate,
                                                    options: quantityType.aggregationOptions,
                                                    anchorDate: anchorDate,
                                                    intervalComponents: interval)
            
            // Set the results handler
            query.initialResultsHandler = { query, results, error in
                guard error == nil else {
                    print("Failed to fetch \(sampleType.displayText) statistics: \(error!)")
                    completion(samples: [], error: error)
                    return
                }
                completion(samples: results?.statistics().map { $0 as MCSample } ?? [], error: nil)
            }
            healthKitStore.executeQuery(query)
            
        default:
            let err = NSError(domain: HMErrorDomain, code: 1048576, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
            completion(samples: [], error: err)
        }
    }
    
    func fetchAggregatedSamplesOfType(sampleType: HKSampleType, aggregateUnit: NSCalendarUnit = .Day, predicate: NSPredicate? = nil,
                                             limit: Int = noLimit, sortDescriptors: [NSSortDescriptor]? = [dateAsc], completion: HMSampleBlock)
    {
        let calendar = NSCalendar.currentCalendar()
        fetchSamplesOfType(sampleType, predicate: predicate, limit: limit, sortDescriptors: sortDescriptors) { samples, error in
            guard error == nil else {
                completion(samples: [], error: error)
                return
            }
            var byDay: [NSDate: MCAggregateSample] = [:]
            samples.forEach { sample in
                let day = calendar.dateFromComponents(calendar.components([.Year, .Month, .Day], fromDate: sample.startDate))!
                if var agg = byDay[day] {
                    agg.incr(sample)
                    byDay[day] = agg
                } else {
                    byDay[day] = MCAggregateSample(sample: sample)
                }
            }

            let doFinal: ((NSDate, MCAggregateSample) -> MCSample) = { (_, in_agg) in var agg = in_agg; agg.final(); return agg as MCSample }
            completion(samples: byDay.sort({ (a,b) in return a.0.compare(b.0) == .OrderedAscending }).map(doFinal), error: nil)
        }
    }
}
