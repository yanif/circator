//
//  PopulationHealthManager.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 1/31/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import HealthKit
import Async

/**
 This is the manager of information for the comparison population.
 By providing this comparison we provide our study participants with a greater ability to view themselves in context.
 
 Initially this is defined by the NHANES data.
 With sufficient enrolled subjects, this will be determined by aggregates over the ongoing study population.
 
 - remark: pulls from PostgreSQL store (AWS RDS) -- see MCRouter --
 */
public class PopulationHealthManager {
    
    public static let sharedManager = PopulationHealthManager()
    
    public var aggregateRefreshDate : NSDate = NSDate()
    
    public var mostRecentAggregates = [HKSampleType: [MCSample]]() {
        didSet {
            aggregateRefreshDate = NSDate()
        }
    }
    
    // MARK: - Population query execution.
    
    // Clear all aggregates.
    public func resetAggregates() { mostRecentAggregates = [:] }
    
    // Retrieve aggregates for all previewed rows.
    // TODO: enable input of start time, end time and columns retrieved in the query view controllers.
    public func fetchAggregates() {
        var columnIndex = 0
        var columns : [String:AnyObject] = [:]

        var tstart  : NSDate             = NSDate(timeIntervalSince1970: 0)
        var tend    : NSDate             = NSDate()
        
        var filter  : [String:AnyObject] = [:]
        
        // Add population filter parameters.
        let popQueryIndex = QueryManager.sharedManager.getSelectedQuery()
        let popQueries = QueryManager.sharedManager.getQueries()
//        if popQueryIndex >= 0 && popQueryIndex < popQueries.count  {
//            switch popQueries[popQueryIndex].1 {
//            case Query.ConjunctiveQuery(let qstartOpt, let qendOpt, let qcolsOpt, let aggpreds):
//                if let qstart = qstartOpt { tstart = qstart }
//                if let qend = qEndOpt { tend = qend }
//
//                if let qcols = qcolsOpt {
//                    for hksType in qcols {
//                        if let column = HMConstants.sharedInstance.hkToMCDB[hksType.identifier] {
//                            columns[String(columnIndex)] = column
//                            columnIndex += 1
//                        }
//                    }
//                }
//
//                let predArray = aggpreds.map(serializePredicateREST)
//                for pred in predArray {
//                    for (k,v) in pred {
//                        filter.updateValue(v, forKey: k)
//                    }
//                }
//            }
//        }
        
        if columns.isEmpty {
            for hksType in PreviewManager.supportedTypes {
                if let column = HMConstants.sharedInstance.hkToMCDB[hksType.identifier] {
                    columns[String(columnIndex)] = column
                    columnIndex += 1
                }
            }
        }

        let params : [String:AnyObject] = [
            "tstart"  : Int(floor(tstart.timeIntervalSince1970)),
            "tend"    : Int(ceil(tend.timeIntervalSince1970)),
            "columns" : columns,
            "filter"  : filter
        ]
        
        Service.json(MCRouter.AggMeasures(params), statusCode: 200..<300, tag: "AGGPOST") {
            _, response, result in
            guard !result.isSuccess else {
                self.refreshAggregatesFromMsg(result.value)
                return
            }
        }
    }
    
    func refreshAggregatesFromMsg(payload: AnyObject?) {
        var populationAggregates : [HKSampleType: [MCSample]] = [:]
        if let aggregates = payload as? [[String: AnyObject]] {
            var failed = false
            for sample in aggregates {
                for (column, val) in sample {
                    log.info("Refreshing population aggregate for \(column)")
                    if let sampleValue = val as? Double,
                        typeIdentifier = HMConstants.sharedInstance.mcdbToHK[column]
                    {
                        switch typeIdentifier {
                        case HKCategoryTypeIdentifierSleepAnalysis:
                            let sampleType = HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!
                            populationAggregates[sampleType] = [MCAggregateSample(value: sampleValue, sampleType: sampleType)]
                            
                        case HKCategoryTypeIdentifierAppleStandHour:
                            let sampleType = HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierAppleStandHour)!
                            populationAggregates[sampleType] = [MCAggregateSample(value: sampleValue, sampleType: sampleType)]
                            
                        default:
                            let sampleType = HKObjectType.quantityTypeForIdentifier(typeIdentifier)!
                            populationAggregates[sampleType] = [MCAggregateSample(value: sampleValue, sampleType: sampleType)]
                        }
                    } else {
                        failed = true
//                        let err = NSError(domain: "App error", code: 0, userInfo: [NSLocalizedDescriptionKey:kvdict.description])
//                        let dict = ["title":"population data error", "error":err]
//                        NSNotificationCenter.defaultCenter().postNotificationName("ncAppLogNotification", object: nil, userInfo: dict)
                    }
                }
            }
            if ( !failed ) {
                Async.main {
//                    let dict = ["title":"population data", "obj":populationAggregates.description ?? ""]
//                    NSNotificationCenter.defaultCenter().postNotificationName("ncAppLogNotification", object: nil, userInfo: dict)
                    self.mostRecentAggregates = populationAggregates
                    NSNotificationCenter.defaultCenter().postNotificationName(HMDidUpdateRecentSamplesNotification, object: self)
                }
            }
        }
    }
}