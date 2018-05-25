//
//  MCAppHealthManager.swift
//  MetabolicCompass
//
//  Created by Olearis on 5/25/18.
//  Copyright © 2018 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit
import MetabolicCompassKit
import MCCircadianQueries

class MCAppHealthManager {
    static let shared = MCAppHealthManager()
    
    func addSleep(startTime: Date, endTime: Date, callback: @escaping (Bool, String?) -> ()) {
        validateTimedEvent(startTime: startTime, endTime: endTime) { (success, errorMessage) -> Void in
            guard success else {
                callback(false, errorMessage)
                return
            }
            MCHealthManager.sharedManager.saveSleep(startTime, endDate: endTime, metadata: [:], completion: {
                (success, error ) -> Void in
                guard error == nil else {
                    callback(false, error?.localizedDescription)
                    log.error(error as! String); return
                }
                UserManager.sharedManager.setUsualWhenToSleepTime(date: startTime)
                UserManager.sharedManager.setUsualWokeUpTime(date: endTime)
                log.info("Saved as sleep event")
                callback(true, nil)
            })
        }
    }
    
    func addExercise(workoutType: HKWorkoutActivityType, startTime: Date, endTime: Date, callback: @escaping (Bool, String?) -> ()) {
        validateTimedEvent(startTime: startTime, endTime: endTime) { (success, errorMessage) -> Void in
            guard success else {
                callback(false, errorMessage)
                return
            }
            MCHealthManager.sharedManager.saveWorkout(
                                startTime, endDate: endTime, activityType: workoutType,
                                distance: 0.0, distanceUnit: HKUnit(from: "km"), kiloCalories: 0.0, metadata: [:])
            {
                (success, error ) -> Void in
                guard error == nil else {
                    callback(false, error?.localizedDescription)
                    return
                }
                log.info("Saved as exercise workout type")
                callback(true, nil)
            }
        }
    }
    
    
    func addMeal(startTime: Date, endTime: Date, mealType: String, callback: @escaping (Bool, String?) -> ()) {
        validateTimedEvent(startTime: startTime, endTime: endTime) { (success, errorMessage) -> Void in
            guard success else {
                callback(false, errorMessage)
                return
            }
            MCHealthManager.sharedManager.savePreparationAndRecoveryWorkout(
                startTime as Date, endDate: endTime, distance: 0.0, distanceUnit: HKUnit(from: "km"),
                kiloCalories: 0.0, metadata: ["Meal Type": mealType] as NSDictionary) { (success, error ) -> Void in
                    guard error == nil else {
                        callback(false, error?.localizedDescription)
                        return
                    }
                    UserManager.sharedManager.setUsualMealTime(mealType: mealType, forDate: startTime)
                    callback(true, nil)
                    log.info("Meal saved as workout type")
            }
        }
    }
    
    //MARK: Validation
    func validateTimedEvent(startTime: Date, endTime: Date, completion: @escaping (_ success: Bool, _ errorMessage: String?) -> ()) {
        // Fetch all sleep and workout data since yesterday.
        let sleepTy = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!
        let workoutTy = HKWorkoutType.workoutType()
        let datePredicate = HKQuery.predicateForSamples(withStart: startTime, end: endTime, options: [])
        let typesAndPredicates = [sleepTy: datePredicate, workoutTy: datePredicate]
        
        // Aggregate sleep, exercise and meal events.
        MCHealthManager.sharedManager.fetchSamples(typesAndPredicates) { (samples, error) -> Void in
            guard error == nil else { log.error("error"); return }
            let overlaps = samples.reduce(false, { (acc, kv) in
                guard !acc else { return acc }
                return kv.1.reduce(acc, { (acc, s) in return acc || !( startTime >= s.endDate || endTime <= s.startDate ) })
            })
            if !overlaps {
                completion(true, nil)
            } else {
                completion(false, "This event overlaps with another, please try again")
            }
        }
    }
}
