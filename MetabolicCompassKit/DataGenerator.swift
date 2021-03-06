//
//  DataGenerator.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 2/17/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit
import Async
import SORandom
import SwiftDate
import FileKit
import SwiftyJSON
import MCCircadianQueries

public typealias MCSampler = (NSDate, Double, Double?) -> HKSample?
public typealias DatasetCompletion = [String: [HKSample]] -> ()

private let unwriteableTypeIdentifiers = [
    HKCategoryTypeIdentifierAppleStandHour,
    HKQuantityTypeIdentifierNikeFuel
]

private let filteredTypeIdentifiers = [
    HKQuantityTypeIdentifierBasalBodyTemperature,
    HKQuantityTypeIdentifierBodyTemperature,
    HKQuantityTypeIdentifierUVExposure,
    HKQuantityTypeIdentifierDietaryWater,
    HKCategoryTypeIdentifierSleepAnalysis
]

/**
 This class generates sample data for Metabolic Compass.  Note that while it is defined for the twenty data types that we start with, it can be enlarged to more data types. The distributions that we use are determined from the NHANES data (and divided into Male/Female)

 */
public class DataGenerator : GeneratorType {

    public static let sharedInstance = DataGenerator()

    let generatorTypes : [HKSampleType] = Array(PreviewManager.previewChoices.flatten()).filter { t in
        return !(unwriteableTypeIdentifiers.contains(t.identifier) || filteredTypeIdentifiers.contains(t.identifier))
    }

    let coveringTypes : [HKSampleType] = Array(HMConstants.sharedInstance.healthKitTypesToObserve).filter { t in
        return !(unwriteableTypeIdentifiers.contains(t.identifier) || filteredTypeIdentifiers.contains(t.identifier))
    }

    let workoutTypesToGenerate : [HKWorkoutActivityType] = [
        HKWorkoutActivityType.AmericanFootball,
        HKWorkoutActivityType.Archery,
        HKWorkoutActivityType.AustralianFootball,
        HKWorkoutActivityType.Badminton,
        HKWorkoutActivityType.Baseball,
        HKWorkoutActivityType.Basketball,
        HKWorkoutActivityType.Bowling,
        HKWorkoutActivityType.Boxing,
        HKWorkoutActivityType.Climbing,
        HKWorkoutActivityType.Cricket,
        HKWorkoutActivityType.CrossTraining,
        HKWorkoutActivityType.Curling,
        HKWorkoutActivityType.Cycling,
        HKWorkoutActivityType.Dance,
        HKWorkoutActivityType.DanceInspiredTraining,
        HKWorkoutActivityType.Elliptical,
        HKWorkoutActivityType.EquestrianSports,
        HKWorkoutActivityType.Fencing,
        HKWorkoutActivityType.Fishing,
        HKWorkoutActivityType.FunctionalStrengthTraining,
        HKWorkoutActivityType.Golf,
        HKWorkoutActivityType.Gymnastics,
        HKWorkoutActivityType.Handball,
        HKWorkoutActivityType.Hiking,
        HKWorkoutActivityType.Hockey,
        HKWorkoutActivityType.Hunting,
        HKWorkoutActivityType.Lacrosse,
        HKWorkoutActivityType.MartialArts,
        HKWorkoutActivityType.MindAndBody,
        HKWorkoutActivityType.MixedMetabolicCardioTraining,
        HKWorkoutActivityType.PaddleSports,
        HKWorkoutActivityType.Play,
        //HKWorkoutActivityType.PreparationAndRecovery,
        HKWorkoutActivityType.Racquetball,
        HKWorkoutActivityType.Rowing,
        HKWorkoutActivityType.Rugby,
        HKWorkoutActivityType.Running,
        HKWorkoutActivityType.Sailing,
        HKWorkoutActivityType.SkatingSports,
        HKWorkoutActivityType.SnowSports,
        HKWorkoutActivityType.Soccer,
        HKWorkoutActivityType.Softball,
        HKWorkoutActivityType.Squash,
        HKWorkoutActivityType.StairClimbing,
        HKWorkoutActivityType.SurfingSports,
        HKWorkoutActivityType.Swimming,
        HKWorkoutActivityType.TableTennis,
        HKWorkoutActivityType.Tennis,
        HKWorkoutActivityType.TrackAndField,
        HKWorkoutActivityType.TraditionalStrengthTraining,
        HKWorkoutActivityType.Volleyball,
        HKWorkoutActivityType.Walking,
        HKWorkoutActivityType.WaterFitness,
        HKWorkoutActivityType.WaterPolo,
        HKWorkoutActivityType.WaterSports,
        HKWorkoutActivityType.Wrestling,
        HKWorkoutActivityType.Yoga,
        HKWorkoutActivityType.Other
    ]

    public let generatorUnits : [String: HKUnit] = [
        HKCategoryTypeIdentifierAppleStandHour            : HKUnit.hourUnit(),
        HKCategoryTypeIdentifierSleepAnalysis             : HKUnit.hourUnit(),
        HKQuantityTypeIdentifierActiveEnergyBurned        : HKUnit.kilocalorieUnit(),
        HKQuantityTypeIdentifierBasalBodyTemperature      : HKUnit.degreeFahrenheitUnit(),
        HKQuantityTypeIdentifierBasalEnergyBurned         : HKUnit.kilocalorieUnit(),
        HKQuantityTypeIdentifierBloodAlcoholContent       : HKUnit.percentUnit(),
        HKQuantityTypeIdentifierBloodGlucose              : HKUnit.gramUnit().unitDividedByUnit(HKUnit.literUnit()),
        HKQuantityTypeIdentifierBloodPressureDiastolic    : HKUnit.millimeterOfMercuryUnit(),
        HKQuantityTypeIdentifierBloodPressureSystolic     : HKUnit.millimeterOfMercuryUnit(),
        HKQuantityTypeIdentifierBodyFatPercentage         : HKUnit.percentUnit(),
        HKQuantityTypeIdentifierBodyMass                  : HKUnit.poundUnit(),
        HKQuantityTypeIdentifierBodyMassIndex             : HKUnit.countUnit(),
        HKQuantityTypeIdentifierBodyTemperature           : HKUnit.degreeFahrenheitUnit(),
        HKQuantityTypeIdentifierDietaryBiotin             : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryCaffeine           : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryCalcium            : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryCarbohydrates      : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryChloride           : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryCholesterol        : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryChromium           : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryCopper             : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryEnergyConsumed     : HKUnit.kilocalorieUnit(),
        HKQuantityTypeIdentifierDietaryFatMonounsaturated : HKUnit.gramUnit(),
        HKQuantityTypeIdentifierDietaryFatPolyunsaturated : HKUnit.gramUnit(),
        HKQuantityTypeIdentifierDietaryFatSaturated       : HKUnit.gramUnit(),
        HKQuantityTypeIdentifierDietaryFatTotal           : HKUnit.gramUnit(),
        HKQuantityTypeIdentifierDietaryFiber              : HKUnit.gramUnit(),
        HKQuantityTypeIdentifierDietaryFolate             : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryIodine             : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryIron               : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryMagnesium          : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryManganese          : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryMolybdenum         : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryNiacin             : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryPantothenicAcid    : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryPhosphorus         : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryPotassium          : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryProtein            : HKUnit.gramUnit(),
        HKQuantityTypeIdentifierDietaryRiboflavin         : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietarySelenium           : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietarySugar              : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietarySodium             : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryThiamin            : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryVitaminA           : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryVitaminB12         : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryVitaminB6          : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryVitaminC           : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryVitaminD           : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryVitaminE           : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryVitaminK           : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryWater              : HKUnit.literUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDietaryZinc               : HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Milli),
        HKQuantityTypeIdentifierDistanceCycling           : HKUnit.mileUnit(),
        HKQuantityTypeIdentifierDistanceWalkingRunning    : HKUnit.mileUnit(),
        HKQuantityTypeIdentifierElectrodermalActivity     : HKUnit.siemenUnit(),
        HKQuantityTypeIdentifierFlightsClimbed            : HKUnit.countUnit(),
        HKQuantityTypeIdentifierForcedExpiratoryVolume1   : HKUnit.literUnit(),
        HKQuantityTypeIdentifierForcedVitalCapacity       : HKUnit.literUnit(),
        HKQuantityTypeIdentifierHeartRate                 : HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit()),
        HKQuantityTypeIdentifierHeight                    : HKUnit.meterUnit(),
        HKQuantityTypeIdentifierInhalerUsage              : HKUnit.countUnit(),
        HKQuantityTypeIdentifierLeanBodyMass              : HKUnit.gramUnit(),
        HKQuantityTypeIdentifierNikeFuel                  : HKUnit.kilocalorieUnit(),
        HKQuantityTypeIdentifierNumberOfTimesFallen       : HKUnit.countUnit(),
        HKQuantityTypeIdentifierOxygenSaturation          : HKUnit.percentUnit(),
        HKQuantityTypeIdentifierPeakExpiratoryFlowRate    : HKUnit.literUnit().unitDividedByUnit(HKUnit.minuteUnit()),
        HKQuantityTypeIdentifierPeripheralPerfusionIndex  : HKUnit.percentUnit(),
        HKQuantityTypeIdentifierRespiratoryRate           : HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit()),
        HKQuantityTypeIdentifierStepCount                 : HKUnit.countUnit(),
        HKQuantityTypeIdentifierUVExposure                : HKUnit.countUnit()
    ]

    let parameters : [Bool: [String: (Double, Double)]] = [
        true: [
            HKCategoryTypeIdentifierAppleStandHour            : (4.0,    1.0),
            HKCategoryTypeIdentifierSleepAnalysis             : (6.5,    1.83),
            HKQuantityTypeIdentifierActiveEnergyBurned        : (2750.0, 750.0),
            HKQuantityTypeIdentifierBasalBodyTemperature      : (98.0,   5.0 ),
            HKQuantityTypeIdentifierBasalEnergyBurned         : (1500.0, 250.0),
            HKQuantityTypeIdentifierBloodAlcoholContent       : (0.001,  0.001),
            HKQuantityTypeIdentifierBloodGlucose              : (0.05,   0.01),
            HKQuantityTypeIdentifierBloodPressureDiastolic    : (80.0,   10.0),
            HKQuantityTypeIdentifierBloodPressureSystolic     : (120.0,  13.33),
            HKQuantityTypeIdentifierBodyFatPercentage         : (215.0,  41.67),
            HKQuantityTypeIdentifierBodyMass                  : (215.0,  41.67),
            HKQuantityTypeIdentifierBodyMassIndex             : (25,     5.0),
            HKQuantityTypeIdentifierBodyTemperature           : (25,     5.0),
            HKQuantityTypeIdentifierDietaryBiotin             : (166.4,  55.467),
            HKQuantityTypeIdentifierDietaryCaffeine           : (166.4,  55.467),
            HKQuantityTypeIdentifierDietaryCalcium            : (166.4,  55.467),
            HKQuantityTypeIdentifierDietaryCarbohydrates      : (327.0,  69.9),
            HKQuantityTypeIdentifierDietaryChloride           : (327.0,  69.9),
            HKQuantityTypeIdentifierDietaryCholesterol        : (352.0,  107.147),
            HKQuantityTypeIdentifierDietaryChromium           : (352.0,  107.147),
            HKQuantityTypeIdentifierDietaryCopper             : (352.0,  107.147),
            HKQuantityTypeIdentifierDietaryEnergyConsumed     : (2757.0, 526.6),
            HKQuantityTypeIdentifierDietaryFatMonounsaturated : (36.9,   8.493),
            HKQuantityTypeIdentifierDietaryFatPolyunsaturated : (24.3,   6.01),
            HKQuantityTypeIdentifierDietaryFatSaturated       : (33.4,   9.147),
            HKQuantityTypeIdentifierDietaryFatTotal           : (103.2,  21.77),
            HKQuantityTypeIdentifierDietaryFiber              : (103.2,  21.77),
            HKQuantityTypeIdentifierDietaryFolate             : (103.2,  21.77),
            HKQuantityTypeIdentifierDietaryIodine             : (103.2,  21.77),
            HKQuantityTypeIdentifierDietaryIron               : (103.2,  21.77),
            HKQuantityTypeIdentifierDietaryMagnesium          : (88.3,   22.2),
            HKQuantityTypeIdentifierDietaryManganese          : (88.3,   22.2),
            HKQuantityTypeIdentifierDietaryMolybdenum         : (88.3,   22.2),
            HKQuantityTypeIdentifierDietaryNiacin             : (88.3,   22.2),
            HKQuantityTypeIdentifierDietaryPantothenicAcid    : (88.3,   22.2),
            HKQuantityTypeIdentifierDietaryPhosphorus         : (88.3,   22.2),
            HKQuantityTypeIdentifierDietaryPotassium          : (88.3,   22.2),
            HKQuantityTypeIdentifierDietaryProtein            : (88.3,   22.2),
            HKQuantityTypeIdentifierDietaryRiboflavin         : (88.3,   22.2),
            HKQuantityTypeIdentifierDietarySelenium           : (88.3,   22.2),
            HKQuantityTypeIdentifierDietarySodium             : (4560.7, 988.493),
            HKQuantityTypeIdentifierDietarySugar              : (143.3,  47.03),
            HKQuantityTypeIdentifierDietaryThiamin            : (143.3,  47.03),
            HKQuantityTypeIdentifierDietaryVitaminA           : (143.3,  47.03),
            HKQuantityTypeIdentifierDietaryVitaminB12         : (143.3,  47.03),
            HKQuantityTypeIdentifierDietaryVitaminB6          : (143.3,  47.03),
            HKQuantityTypeIdentifierDietaryVitaminC           : (143.3,  47.03),
            HKQuantityTypeIdentifierDietaryVitaminD           : (143.3,  47.03),
            HKQuantityTypeIdentifierDietaryVitaminE           : (143.3,  47.03),
            HKQuantityTypeIdentifierDietaryVitaminK           : (143.3,  47.03),
            HKQuantityTypeIdentifierDietaryWater              : (5.0,    1.67),
            HKQuantityTypeIdentifierDietaryZinc               : (5.0,    1.67),
            HKQuantityTypeIdentifierDistanceCycling           : (5.0,    1.67),
            HKQuantityTypeIdentifierDistanceWalkingRunning    : (5.0,    1.67),
            HKQuantityTypeIdentifierElectrodermalActivity     : (5.0,    1.67),
            HKQuantityTypeIdentifierFlightsClimbed            : (5.0,    1.67),
            HKQuantityTypeIdentifierForcedExpiratoryVolume1   : (5.0,    1.67),
            HKQuantityTypeIdentifierForcedVitalCapacity       : (5.0,    1.67),
            HKQuantityTypeIdentifierHeartRate                 : (80.0,   13.33),
            HKQuantityTypeIdentifierHeight                    : (80.0,   13.33),
            HKQuantityTypeIdentifierInhalerUsage              : (80.0,   13.33),
            HKQuantityTypeIdentifierLeanBodyMass              : (80.0,   13.33),
            HKQuantityTypeIdentifierNikeFuel                  : (80.0,   13.33),
            HKQuantityTypeIdentifierNumberOfTimesFallen       : (80.0,   13.33),
            HKQuantityTypeIdentifierOxygenSaturation          : (80.0,   13.33),
            HKQuantityTypeIdentifierPeakExpiratoryFlowRate    : (80.0,   13.33),
            HKQuantityTypeIdentifierPeripheralPerfusionIndex  : (80.0,   13.33),
            HKQuantityTypeIdentifierRespiratoryRate           : (6000.0, 1996.67),
            HKQuantityTypeIdentifierStepCount                 : (6000.0, 1996.67),
            HKQuantityTypeIdentifierUVExposure                : (6.0,    1.0),
            //HKWorkoutSortIdentifierDuration                   : (10,0,   1.0),
            HKWorkoutSortIdentifierTotalDistance              : (100.0,  10.0),
            HKWorkoutSortIdentifierTotalEnergyBurned          : (5.0,     0.5)
        ],

        false: [
            HKCategoryTypeIdentifierAppleStandHour            : (4.0,    1.0),
            HKCategoryTypeIdentifierSleepAnalysis             : (6.5,    1.83),
            HKQuantityTypeIdentifierActiveEnergyBurned        : (2750.0, 750.0),
            HKQuantityTypeIdentifierBasalBodyTemperature      : (98.0,   5.0 ),
            HKQuantityTypeIdentifierBasalEnergyBurned         : (1500.0, 500.0),
            HKQuantityTypeIdentifierBloodAlcoholContent       : (0.001,  0.001),
            HKQuantityTypeIdentifierBloodGlucose              : (0.10,   0.01),
            HKQuantityTypeIdentifierBloodPressureDiastolic    : (80.0,   10.0),
            HKQuantityTypeIdentifierBloodPressureSystolic     : (120.0,  13.33),
            HKQuantityTypeIdentifierBodyFatPercentage         : (215.0,  41.67),
            HKQuantityTypeIdentifierBodyMass                  : (215.0,  41.67),
            HKQuantityTypeIdentifierBodyMassIndex             : (25,     5.0),
            HKQuantityTypeIdentifierBodyTemperature           : (25,     5.0),
            HKQuantityTypeIdentifierDietaryBiotin             : (166.4,  55.467),
            HKQuantityTypeIdentifierDietaryCaffeine           : (142.7,  47.567),
            HKQuantityTypeIdentifierDietaryCalcium            : (166.4,  55.467),
            HKQuantityTypeIdentifierDietaryCarbohydrates      : (246.3,  43.13),
            HKQuantityTypeIdentifierDietaryChloride           : (327.0,  69.9),
            HKQuantityTypeIdentifierDietaryCholesterol        : (235.7,  78.57),
            HKQuantityTypeIdentifierDietaryChromium           : (352.0,  107.147),
            HKQuantityTypeIdentifierDietaryCopper             : (352.0,  107.147),
            HKQuantityTypeIdentifierDietaryEnergyConsumed     : (1957.0, 315.67),
            HKQuantityTypeIdentifierDietaryFatMonounsaturated : (25.7,   5.1),
            HKQuantityTypeIdentifierDietaryFatPolyunsaturated : (17.4,   3.533),
            HKQuantityTypeIdentifierDietaryFatSaturated       : (23.9,   5.227),
            HKQuantityTypeIdentifierDietaryFatTotal           : (73.1,   13.0),
            HKQuantityTypeIdentifierDietaryFiber              : (103.2,  21.77),
            HKQuantityTypeIdentifierDietaryFolate             : (103.2,  21.77),
            HKQuantityTypeIdentifierDietaryIodine             : (103.2,  21.77),
            HKQuantityTypeIdentifierDietaryIron               : (103.2,  21.77),
            HKQuantityTypeIdentifierDietaryMagnesium          : (88.3,   22.2),
            HKQuantityTypeIdentifierDietaryManganese          : (88.3,   22.2),
            HKQuantityTypeIdentifierDietaryMolybdenum         : (88.3,   22.2),
            HKQuantityTypeIdentifierDietaryNiacin             : (88.3,   22.2),
            HKQuantityTypeIdentifierDietaryPantothenicAcid    : (88.3,   22.2),
            HKQuantityTypeIdentifierDietaryPhosphorus         : (88.3,   22.2),
            HKQuantityTypeIdentifierDietaryPotassium          : (88.3,   22.2),
            HKQuantityTypeIdentifierDietaryProtein            : (71.3,   12.03),
            HKQuantityTypeIdentifierDietaryRiboflavin         : (88.3,   22.2),
            HKQuantityTypeIdentifierDietarySelenium           : (88.3,   22.2),
            HKQuantityTypeIdentifierDietarySodium             : (3187.3, 557.93),
            HKQuantityTypeIdentifierDietarySugar              : (112.0,  28.73),
            HKQuantityTypeIdentifierDietaryThiamin            : (143.3,  47.03),
            HKQuantityTypeIdentifierDietaryVitaminA           : (143.3,  47.03),
            HKQuantityTypeIdentifierDietaryVitaminB12         : (143.3,  47.03),
            HKQuantityTypeIdentifierDietaryVitaminB6          : (143.3,  47.03),
            HKQuantityTypeIdentifierDietaryVitaminC           : (143.3,  47.03),
            HKQuantityTypeIdentifierDietaryVitaminD           : (143.3,  47.03),
            HKQuantityTypeIdentifierDietaryVitaminE           : (143.3,  47.03),
            HKQuantityTypeIdentifierDietaryVitaminK           : (143.3,  47.03),
            HKQuantityTypeIdentifierDietaryWater              : (4.7,    1.567),
            HKQuantityTypeIdentifierDietaryZinc               : (5.0,    1.67),
            HKQuantityTypeIdentifierDistanceCycling           : (5.0,    1.67),
            HKQuantityTypeIdentifierDistanceWalkingRunning    : (5.0,    1.67),
            HKQuantityTypeIdentifierElectrodermalActivity     : (5.0,    1.67),
            HKQuantityTypeIdentifierFlightsClimbed            : (5.0,    1.67),
            HKQuantityTypeIdentifierForcedExpiratoryVolume1   : (5.0,    1.67),
            HKQuantityTypeIdentifierForcedVitalCapacity       : (5.0,    1.67),
            HKQuantityTypeIdentifierHeartRate                 : (80.0,   13.33),
            HKQuantityTypeIdentifierHeight                    : (80.0,   13.33),
            HKQuantityTypeIdentifierInhalerUsage              : (80.0,   13.33),
            HKQuantityTypeIdentifierLeanBodyMass              : (80.0,   13.33),
            HKQuantityTypeIdentifierNikeFuel                  : (80.0,   13.33),
            HKQuantityTypeIdentifierNumberOfTimesFallen       : (80.0,   13.33),
            HKQuantityTypeIdentifierOxygenSaturation          : (80.0,   13.33),
            HKQuantityTypeIdentifierPeakExpiratoryFlowRate    : (80.0,   13.33),
            HKQuantityTypeIdentifierPeripheralPerfusionIndex  : (80.0,   13.33),
            HKQuantityTypeIdentifierRespiratoryRate           : (6000.0, 1996.67),
            HKQuantityTypeIdentifierStepCount                 : (6000.0, 1996.67),
            HKQuantityTypeIdentifierUVExposure                : (6.0,    1.0),
            //HKWorkoutSortIdentifierDuration                   : (10,0,   1.0),
            HKWorkoutSortIdentifierTotalDistance              : (100.0,  10.0),
            HKWorkoutSortIdentifierTotalEnergyBurned          : (5.0,     0.5)
        ]
    ]

    // 2hr blocks through a day, represented as seconds.
    let timeBlocksInSecs = 0.0.stride(through: 22.0, by: 2.0).map { x in return x * 3600.0 }

    // Probabilities of event occurring in a 2 hour block, e.g., 0-2AM, 2-4AM, etc. We assume uniformity within the block
    let defaultEventTimeDistribution = [0.03, 0.01, 0.01, 0.12, 0.12, 0.11, 0.11, 0.11, 0.12, 0.12, 0.11, 0.03]

    // Type-specific event distributions, e.g., start of sleep is inverted from the above.
    let eventTimeDistributions : [Bool: [String: [Double]]] = [
        true: [
            HKCategoryTypeIdentifierSleepAnalysis : [0.2, 0.1, 0.0125, 0.0125, 0.0125, 0.0125, 0.0125, 0.0125, 0.0125, 0.0125, 0.1, 0.5]
        ],
        false: [
            HKCategoryTypeIdentifierSleepAnalysis : [0.2, 0.1, 0.0125, 0.0125, 0.0125, 0.0125, 0.0125, 0.0125, 0.0125, 0.0125, 0.1, 0.5]
        ]
    ]

    // Point and bulk generation API.

    func sampleDailyTimestampsWithWeights(date: NSDate, weights: [Double], count: Int) -> [NSDate] {
        let ts = sampleWithWeights(timeBlocksInSecs, weights, count)
        let offsetInBlock = randContUniforms(0.0, 7200.0, count)
        return zip(ts, offsetInBlock).map { (t,o) in return date + Int(ceil(t + o)).seconds }
    }

    func sampleDailyTimestamps(date: NSDate, count: Int) -> [NSDate] {
        return sampleDailyTimestampsWithWeights(date, weights: defaultEventTimeDistribution, count: count)
    }

    public func generatorForType(type: HKSampleType, count: Int, asMale: Bool = true, date: NSDate, completion: MCSampler) -> [HKSample] {
        switch type.identifier
        {
        case HKCategoryTypeIdentifierSleepAnalysis:
            let params = parameters[asMale]![type.identifier]!
            let tparams = eventTimeDistributions[asMale]![type.identifier]!
            let ts = sampleDailyTimestampsWithWeights(date, weights: tparams, count: count)
            return zip(ts, randNormals(params.0, params.1, count)).flatMap { (t,x) in return completion(t, x, nil) }

        case HKCategoryTypeIdentifierAppleStandHour:
            let params = parameters[asMale]![type.identifier]!
            let ts = sampleDailyTimestamps(date, count: count)
            return zip(ts, randNormals(params.0, params.1, count)).flatMap { (t,x) in return completion(t, x, nil) }

        case HKCorrelationTypeIdentifierBloodPressure:
            let ts = sampleDailyTimestamps(date, count: count)
            let dp = parameters[asMale]![HKQuantityTypeIdentifierBloodPressureDiastolic]!
            let sp = parameters[asMale]![HKQuantityTypeIdentifierBloodPressureSystolic]!

            let dv : [Double] = randNormals(dp.0, dp.1, count)
            let sv : [Double] = randNormals(sp.0, sp.1, count)
            return zip(ts, zip(dv, sv)).flatMap { (t,ds) in return completion(t, ds.0, ds.1) }

        case HKWorkoutTypeIdentifier:
            // TODO: tbw should add in the custom distributions for each workout type.
            // Currently this lookup on eventTimeDistributions fails, since sleep is the only custom distribution.
            //let tparams = eventTimeDistributions[asMale]![type.identifier]!
            //let ts = sampleDailyTimestampsWithWeights(date, weights: tparams, count: count)
            
            let ts = sampleDailyTimestamps(date, count: count)
            let energy = parameters[asMale]![HKQuantityTypeIdentifierActiveEnergyBurned]!
            let distance = parameters[asMale]![HKQuantityTypeIdentifierDistanceWalkingRunning]!
            let ev : [Double] = randNormals(energy.0, energy.1, count)
            let dv : [Double] = randNormals(distance.0, distance.1, count)
            return zip(ts, zip(ev, dv)).flatMap { (t,ds) in return completion(t, ds.0, ds.1) }

        default:
            let tparams = eventTimeDistributions[asMale]![type.identifier] ?? defaultEventTimeDistribution
            let ts = sampleDailyTimestampsWithWeights(date, weights: tparams, count: count)

            if let params = parameters[asMale]![type.identifier] {
                return zip(ts, randNormals(params.0, params.1, count)).flatMap { (t,x) in return completion(t, x, nil) }
            }
            return []
        }
    }

    public func minutesBetweenDate(startDate: NSDate, endDate: NSDate) -> Int
    {
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Minute], fromDate: startDate, toDate: endDate, options: [])
        return components.minute
    }

    func nextSample(type: HKSampleType, asMale: Bool = true, date: NSDate, x: Double, y: Double?) -> HKSample? {
        let meta : [String: AnyObject] = [sampleTag: true]
        let sleepVal = HKCategoryValueSleepAnalysis.Asleep.rawValue
        let stoodVal = HKCategoryValueAppleStandHour.Stood.rawValue
        switch type.identifier {
        case HKCategoryTypeIdentifierSleepAnalysis:
            let ct = type as! HKCategoryType
            let sleepStart = date
            let sleepEnd = sleepStart + Int(abs(x) * 3600.0).seconds
            return HKCategorySample(type: ct, value: sleepVal, startDate: sleepStart, endDate: sleepEnd, metadata: meta)

        case HKCategoryTypeIdentifierAppleStandHour:
            let ct = type as! HKCategoryType
            let standStart = date
            let standEnd = standStart + Int(abs(x) * 60.0).seconds
            return HKCategorySample(type: ct, value: stoodVal, startDate: standStart, endDate: standEnd, metadata: meta)

        case HKWorkoutTypeIdentifier:
            let workoutStart = date
            let workoutEnd = workoutStart + Int(randNormal(100, 1)).minutes
            let energyBurned = HKQuantity(unit: HKUnit.kilocalorieUnit(), doubleValue: x)
            let distance = HKQuantity(unit: HKUnit.mileUnit(), doubleValue: y!)
            let workoutDuration : NSTimeInterval = Double(randNormal(100, 1)*60)
            let workoutTypeInt = randDiscUniform(0,56)
            return HKWorkout(activityType: workoutTypesToGenerate[workoutTypeInt],
                startDate: workoutStart, endDate: workoutEnd, duration: workoutDuration,
                totalEnergyBurned: energyBurned, totalDistance: distance, metadata: meta)

        case HKCorrelationTypeIdentifierBloodPressure:
            let du = self.generatorUnits[HKQuantityTypeIdentifierBloodPressureDiastolic]!
            let su = self.generatorUnits[HKQuantityTypeIdentifierBloodPressureSystolic]!

            let ct = type as! HKCorrelationType
            let dt = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureDiastolic)!
            let st = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureSystolic)!
            let ds = HKQuantitySample(type: dt, quantity: HKQuantity(unit: du, doubleValue: x), startDate: date, endDate: date, metadata: meta)
            let ss = HKQuantitySample(type: st, quantity: HKQuantity(unit: su, doubleValue: y!), startDate: date, endDate: date, metadata: meta)
            let objs : Set = [ds,ss]
            return HKCorrelation(type: ct, startDate: date, endDate: date, objects: objs, metadata: meta)

        default:
            if let u = self.generatorUnits[type.identifier] {
                let qt = type as! HKQuantityType
                let q = HKQuantity(unit: u, doubleValue: x)
                return HKQuantitySample(type: qt, quantity: q, startDate: date, endDate: date, metadata: meta)
            }
            return nil
        }
    }

    public func generateManyForType(type: HKSampleType, count: Int, asMale: Bool = true, date: NSDate) -> [HKSample] {
        return generatorForType(type, count: count, asMale: asMale, date: date) { (d,x,y) in
            return self.nextSample(type, asMale: asMale, date: d, x: x, y: y)
        }
    }

    public func generateForType(type: HKSampleType, asMale: Bool = true, date: NSDate) -> HKSample? {
        if let params = parameters[asMale]![type.identifier] {
            let x = randNormal(params.0, params.1)
            return nextSample(type, asMale: asMale, date: date, x: x, y: nil)
        }
        return nil
    }

    // Stream/Generator API
    // This returns a set of HealthKit samples per day.
    // Callers must set the 'currentDay' and 'samplesPerDay' parameters appropriately.

    public typealias Element = [HKSample]

    var coveringDataset : Bool                         = false
    var currentDay      : NSDate!                      = NSDate()
    var samplesPerDay   : Int                          = 10
    var samplesPerType  : Int                          = 5
    var sampleBuffer    : [Bool: [String: [HKSample]]] = [true: [:], false: [:]]
    var sampleTag       : String                       = HMConstants.sharedInstance.generatedSampleKey


    // Generate samples for the next day.
    public func next() -> Element?
    {
        let sleepWeight = 0.99999
        let sleepOrOther = randBinomial(sleepWeight) > 0 ? [HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!] : []

        var maleOrFemale  : [Int] = []
        var typesToSample : [HKSampleType] = []

        if coveringDataset {
            maleOrFemale = coinTosses(samplesPerType * coveringTypes.count)
            typesToSample = Array(coveringTypes.map { t in return [HKSampleType](count: samplesPerType, repeatedValue: t) }.flatten())
        } else {
            maleOrFemale = coinTosses(samplesPerDay)
            typesToSample = sampleWithReplacement(generatorTypes, sleepOrOther.isEmpty ? samplesPerDay : samplesPerDay-1) + sleepOrOther
        }

        let meta : [String: AnyObject] = [sampleTag: true]
        let z : [HKSample] = []

        return zip(maleOrFemale, typesToSample).reduce(z, combine: { (in_acc, mt) in
            var acc = in_acc
            if let s = sampleBuffer[mt.0 > 0]?[mt.1.identifier]?.popLast() {
                let ddiff = Int(floor(currentDay.timeIntervalSinceDate(s.startDate) / 86400)).days
                let ns = ddiff.fromDate(s.startDate)
                let ne = ddiff.fromDate(s.endDate)

                switch s {
                case is HKCategorySample:
                    let cs = s as! HKCategorySample
                    acc.append(HKCategorySample(type: cs.categoryType, value: cs.value, startDate: ns, endDate: ne, metadata: meta))

                case is HKCorrelation:
                    let cs = s as! HKCorrelation
                    acc.append(HKCorrelation(type: cs.correlationType, startDate: ns, endDate: ne, objects: cs.objects, metadata: meta))

                case is HKQuantitySample:
                    let qs = s as! HKQuantitySample
                    acc.append(HKQuantitySample(type: qs.quantityType, quantity: qs.quantity, startDate: ns, endDate: ne, metadata: meta))

                default:
                    acc.append(s)
                }

                return acc

            } else {
                var newSamples = generateManyForType(mt.1, count: coveringDataset ? samplesPerType : samplesPerDay, asMale: mt.0 > 0, date: currentDay)
                if let r = newSamples.popLast() { acc.append(r) }
                sampleBuffer[mt.0 > 0]![mt.1.identifier] = newSamples
                return acc
            }
        })
    }

    // Dataset generation.
    private var samplesSkipped = 0
    private var daysSkipped = 0

    func writeSample(handle: NSFileHandle, sample: HKSample, asFirst: Bool) {
        do {
            let js = try JSON(UploadManager.serializer.dictForSample(sample))
            if let jsstr = js.rawString(),
                   jsdata = ((asFirst ? "" : ",") + jsstr).dataUsingEncoding(NSUTF8StringEncoding)
            {
                handle.writeData(jsdata)
            } else {
                samplesSkipped += 1
            }
        } catch {
            log.error(error)
        }
    }

    // Data generation driver.
    // This is responsible for creating a JSON file of samples, and passing the file handle
    // to a data generation callback which does the actual work of generating HKSamples.
    private func generateWithCompletion(path: String, users: [String], completion: NSFileHandle -> ()) {
        let output = TextFile(path: Path.UserHome + "Documents/" + path)

        do {
            if output.exists { try output.delete() }
            try output.create()

            let gpreamble  = "{ users: [".dataUsingEncoding(NSUTF8StringEncoding)!
            let gpostamble = "]}".dataUsingEncoding(NSUTF8StringEncoding)!
            var firstUser = true

            if let outhndl = output.handleForWriting {
                outhndl.writeData(gpreamble)
                users.forEach { userId in
                    log.info("Generating dataset for \(userId)")

                    let upreamble = ((firstUser ? "" : ",") + "{ \"id\": \"\(userId)\", \"samples\": [").dataUsingEncoding(NSUTF8StringEncoding)!
                    let upostamble = "]}".dataUsingEncoding(NSUTF8StringEncoding)!

                    firstUser = false

                    outhndl.writeData(upreamble)
                    completion(outhndl)
                    outhndl.writeData(upostamble)
                }
                outhndl.writeData(gpostamble)

                log.info("Created a HealthKit dataset of size \(output.size! / (1024*1024)) MB at: \(output.path)")
                log.info("Skipped \(samplesSkipped) samples, \(daysSkipped) days")
            } else {
                log.error("Could not write dataset to \(output.path)")
            }
        } catch {
            log.error(error)
        }
    }

    // Generates an in-memony HKSample dataset rather than a file-based one.
    // This invokes a callback on the dataset created.
    private func generateInMemory(users: [String], startDateDay: NSDate, days: Int, completion: DatasetCompletion) {
        var dataset : [String: [HKSample]] = [:]
        samplesSkipped = 0
        daysSkipped = 0

        users.forEach { userId in
            log.info("Generating dataset for \(userId)")
            dataset[userId] = []
            (0..<days).forEach { i in
                autoreleasepool { _ in
                    self.currentDay = startDateDay + i.days
                    if let samples : [HKSample] = self.next() {
                        if (i % 10) == 0 { log.info("Created batch \(i) / \(days),  \(samples.count) samples") }
                        dataset[userId]!.appendContentsOf(samples)
                    } else {
                        self.daysSkipped += 1
                    }
                }
            }
        }
        completion(dataset)
    }

    // File-based dataset generation.
    // This invokes the file-based generator driver with a closure that creates a sample dataset
    // per day over the given day range, for each user specified.
    private func generateDataset(path: String, users: [String], startDateDay: NSDate, days: Int) {
        generateWithCompletion(path, users: users) { outhndl in
            (0..<days).forEach { i in
                autoreleasepool { _ in
                    self.currentDay = startDateDay + i.days
                    if let samples : [HKSample] = self.next() {
                        if (i % 10) == 0 { log.info("Writing batch \(i) / \(days),  \(samples.count) samples") }
                        var firstSample = true
                        samples.forEach { s in
                            self.writeSample(outhndl, sample: s, asFirst: firstSample)
                            firstSample = false
                        }
                    } else {
                        self.daysSkipped += 1
                    }
                }
            }
        }
    }

    // Generates a file-based random health measure dataset for the given users and date range.
    private func generateSampledDataset(path: String, users: [String], size: Int, startDate: NSDate, endDate: NSDate) {
        let startDateDay = startDate.startOf(.Day, inRegion: Region())
        let days = Int(ceil(endDate.timeIntervalSinceDate(startDate)) / 86400.0)

        samplesPerDay = size / days
        samplesSkipped = 0
        daysSkipped = 0

        generateDataset(path, users: users, startDateDay: startDateDay, days: days)
    }

    // Generates a covering dataset (i.e., one that includes all known health measures) for the given users and date range.
    private func generateCoveringDataset(path: String, users: [String], samplesPerType: Int, startDate: NSDate, endDate: NSDate) {
        let startDateDay = startDate.startOf(.Day, inRegion: Region())
        let days = Int(ceil(endDate.timeIntervalSinceDate(startDate)) / 86400.0)

        coveringDataset = true
        self.samplesPerType = samplesPerType
        samplesSkipped = 0
        daysSkipped = 0

        generateDataset(path, users: users, startDateDay: startDateDay, days: days)
    }

    // Generates a random user id according to the user id format for the Metabolic Compass backend.
    private func randomUser(length: Int) -> String {
        let charactersString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let charactersArray = Array(charactersString.characters)

        var string = ""
        for _ in 0..<length {
            string.append(charactersArray[Int(arc4random()) % charactersArray.count])
        }

        return string
    }


    ///////////////////////////////////////////////
    //
    // Public accessors for dataset generation.

    // Generates a health dataset for a single user.
    public func generateDatasetForUser(path: String, userId: String, size: Int, startDate: NSDate, endDate: NSDate) {
        generateSampledDataset(path, users: [userId], size: size, startDate: startDate, endDate: endDate)
    }

    // Generates a health dataset for the given number of users, where user ids are chosen randomly
    public func generateDatasetForService(path: String, numUsers: Int, size: Int, startDate: NSDate, endDate: NSDate) {
        let userIdLen = 20
        let users = (0..<numUsers).map { _ in return randomUser(userIdLen) }
        let sizePerUser = Int(ceil(Double(size) / Double(numUsers)))
        generateSampledDataset(path, users: users, size: sizePerUser, startDate: startDate, endDate: endDate)
    }


    ////////////////////////////////////////
    // Covering datasets constructors:
    // Dataset that include at least one sample of every HealthKit type and workout activity.

    public func generateCoveringDatasetForService(path: String, numUsers: Int, samplesPerType: Int, startDate: NSDate, endDate: NSDate) {
        let userIdLen = 20
        let users = (0..<numUsers).map { _ in return randomUser(userIdLen) }
        generateCoveringDataset(path, users: users, samplesPerType: samplesPerType, startDate: startDate, endDate: endDate)
    }

    public func generateInMemoryCoveringDatasetForService(numUsers: Int, samplesPerType: Int, startDate: NSDate, endDate: NSDate, completion: DatasetCompletion) {
        let userIdLen = 20
        let users = (0..<numUsers).map { _ in return randomUser(userIdLen) }

        let startDateDay = startDate.startOf(.Day, inRegion: Region())
        let days = Int(ceil(endDate.timeIntervalSinceDate(startDate)) / 86400.0)

        coveringDataset = true
        self.samplesPerType = samplesPerType
        generateInMemory(users, startDateDay: startDateDay, days: days, completion: completion)
    }

    public func generateInMemoryCoveringDataset(samplesPerType: Int, startDate: NSDate, endDate: NSDate, completion: DatasetCompletion) {
        let startDateDay = startDate.startOf(.Day, inRegion: Region())
        let days = Int(ceil(endDate.timeIntervalSinceDate(startDate)) / 86400.0)

        coveringDataset = true
        self.samplesPerType = samplesPerType
        generateInMemory(["<yourself>"], startDateDay: startDateDay, days: days, completion: completion)
    }


    ////////////////////////////////////////////
    // Local dataset generation

    private func generateLocalInMemoryCoveringDataset(samplesPerType: Int, startDate: NSDate, endDate: NSDate) {
        let startDateDay = startDate.startOf(.Day, inRegion: Region())
        let days = Int(ceil(endDate.timeIntervalSinceDate(startDate)) / 86400.0)

        self.coveringDataset = true
        self.samplesPerType = samplesPerType

        log.info("Generating covering dataset for types:")
        coveringTypes.forEach {
            log.info("    " + $0.identifier)
        }

        generateInMemory(["<yourself>"], startDateDay: startDateDay, days: days) {
            $0.forEach { (_,block) in
                if !block.isEmpty {
                    MCHealthManager.sharedManager.saveSamples(block) {
                        (success, error) -> Void in
                        guard error == nil else { log.error(error); return }
                    }
                } else {
                    log.info("Empty block for covering data generator")
                }
            }
        }
    }

    public func generateLocalInMemoryCoveringDatasetWithoutUpload(samplesPerType: Int, startDate: NSDate, endDate: NSDate) {
        self.sampleTag = HMConstants.sharedInstance.generatedSampleKey
        generateLocalInMemoryCoveringDataset(samplesPerType, startDate: startDate, endDate: endDate)
    }

    public func generateLocalInMemoryCoveringDatasetWithUpload(samplesPerType: Int, startDate: NSDate, endDate: NSDate) {
        self.sampleTag = HMConstants.sharedInstance.generatedUploadSampleKey
        generateLocalInMemoryCoveringDataset(samplesPerType, startDate: startDate, endDate: endDate)
    }

    private func removeLocalInMemoryDatasetWithTag(tag: String, completion: (Int, NSError!) -> Void) {
        var typesAndPredicates = [HKSampleType: NSPredicate]()
        for type in coveringTypes {
            typesAndPredicates[type] = HKQuery.predicateForObjectsWithMetadataKey(tag)
        }
        MCHealthManager.sharedManager.deleteSamples(typesAndPredicates: typesAndPredicates, completion: completion)
    }

    public func removeLocalInMemoryDataset(completion: (Int, NSError!) -> Void) {
        removeLocalInMemoryDatasetWithTag(HMConstants.sharedInstance.generatedSampleKey, completion: completion)
        removeLocalInMemoryDatasetWithTag(HMConstants.sharedInstance.generatedUploadSampleKey, completion: completion)
    }

}
