//
//  DashboardComparisonController.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit
import MetabolicCompassKit

class DashboardComparisonController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let dashboardComparisonCellIdentifier = "ComparisonCell"
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource      = self
        self.tableView.delegate        = self
        self.tableView.allowsSelection = false
        
        AccountManager.shared.loginAndInitialize(false)
    }
    
    func contenteDidUpdate (notification: NSNotification) {
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        AccountManager.shared.contentManager.initializeBackgroundWork()
        self.tableView.reloadData()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(contenteDidUpdate), name: HMDidUpdateRecentSamplesNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateContent), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    func updateContent() {
        AccountManager.shared.contentManager.resetBackgroundWork()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        AccountManager.shared.contentManager.stopBackgroundWork()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    //MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PreviewManager.previewSampleTypes.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(dashboardComparisonCellIdentifier, forIndexPath: indexPath) as! DashboardComparisonCell
        let sampleType = PreviewManager.previewSampleTypes[indexPath.row]
        cell.sampleType = sampleType
        let timeSinceRefresh = NSDate().timeIntervalSinceDate(PopulationHealthManager.sharedManager.aggregateRefreshDate)
        let refreshPeriod = UserManager.sharedManager.getRefreshFrequency() ?? Int.max
        let stale = timeSinceRefresh > Double(refreshPeriod)
        
        cell.setUserData(HealthManager.sharedManager.mostRecentSamples[sampleType] ?? [HKSample](),
                         populationAverageData: PopulationHealthManager.sharedManager.mostRecentAggregates[sampleType] ?? [],
                         stalePopulation: stale)
        return cell
    }

}
