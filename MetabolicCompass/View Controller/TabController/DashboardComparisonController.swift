//
//  DashboardComparisonController.swift
//  MetabolicCompass
//
//  Created by Inaiur on 5/6/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import HealthKit
import MCCircadianQueries
import MetabolicCompassKit
import Async
import SwiftDate
import Crashlytics
import NVActivityIndicatorView

class DashboardComparisonController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let dashboardComparisonCellIdentifier = "ComparisonCell"
    @IBOutlet weak var tableView: UITableView!

    var activityIndicator: NVActivityIndicatorView! = nil
    var activityCnt: Int = 0
    var activityAsync: Async! = nil

    var comparisonTips: [Int:TapTip] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource      = self
        self.tableView.delegate        = self
        self.tableView.allowsSelection = false

        let sz: CGFloat = 25
        let screenSize = UIScreen.main.bounds.size
        let hOffset: CGFloat = screenSize.height < 569 ? 40.0 : 75.0

        let activityFrame = CGRect((screenSize.width - sz) / 2, (screenSize.height - (hOffset+sz)) / 2, sz, sz)
//        self.activityIndicator = NVActivityIndicatorView(frame: activityFrame, type: .LineScale, color: UIColor.lightGrayColor())
        self.view.addSubview(self.activityIndicator)

        AccountManager.shared.loginAndInitialize(animated: false)
    }

    func contentDidUpdate (notification: NSNotification) {
        self.tableView.reloadData()
        self.stopActivityIndicator()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.updateContent()

        self.tableView.reloadData()
        NotificationCenter.default.addObserver(self, selector: #selector(contentDidUpdate), name: NSNotification.Name(rawValue: HMDidUpdateRecentSamplesNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: NSNotification.Name(rawValue: HMDidUpdateAnyMeasures), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateContent), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        logContentView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopActivityIndicator(force: true)
        AccountManager.shared.contentManager.stopBackgroundWork()
        NotificationCenter.default.removeObserver(self)
//        logContentView(false)
    }

    func startActivityIndicator() {
        activityIndicator.startAnimating()
        activityCnt += 2

        if activityAsync != nil { activityAsync.cancel() }
        activityAsync = Async.main(after: 20.0) {
            self.activityCnt = 0
            if self.activityCnt == 0 && self.activityIndicator.animating { self.activityIndicator.stopAnimating() }
        }
    }

    func stopActivityIndicator(force: Bool = false) {
        activityCnt = force ? 0 : max(activityCnt - 1, 0)
        if (force || activityCnt == 0) && activityIndicator.animating { activityIndicator.stopAnimating() }
    }

    func logContentView(asAppear: Bool = true) {
        Answers.logContentView(withName: "Population",
                                       contentType: asAppear ? "Appear" : "Disappear",
//                                       contentId: Date().string(DateFormat.custom("YYYY-MM-dd:HH")),
                                        contentId: Date().string(),
                                       customAttributes: nil)
    }

    func updateContent() {
        self.startActivityIndicator()
        AccountManager.shared.contentManager.initializeBackgroundWork()
    }

    func refreshData() {
        ComparisonDataModel.sharedManager.updateIndividualData(types: PreviewManager.previewSampleTypes) { _ in () }
    }

    //MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PreviewManager.previewSampleTypes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: dashboardComparisonCellIdentifier, for: indexPath as IndexPath) as! DashboardComparisonCell
        let sampleType = PreviewManager.previewSampleTypes[indexPath.row]
        cell.sampleType = sampleType

        let active = QueryManager.sharedManager.isQueriedType(sample: sampleType)
        cell.setPopulationFiltering(active: active)

//        let timeSinceRefresh = DateComponents().timeIntervalSinceDate(PopulationHealthManager.sharedManager.aggregateRefreshDate ?? Date.distantPast())
        let refreshPeriod = UserManager.sharedManager.getRefreshFrequency() ?? Int.max
//        let stale = timeSinceRefresh > Double(refreshPeriod)

        let individualSamples = ComparisonDataModel.sharedManager.recentSamples[sampleType] ?? [HKSample]()
        let populationSamples = ComparisonDataModel.sharedManager.recentAggregates[sampleType] ?? []
//        cell.setUserData(individualSamples, populationAverageData: populationSamples, stalePopulation: stale)

        if indexPath.section == 0 && comparisonTips[indexPath.row] == nil {
            let targetView = cell

            let desc = "This table helps you compare your personal health stats (left column) to our study population's stats (right column). We show values older than 24 hours in yellow. You can pick measures to display with the Manage button."

            let tipAsTop = PreviewManager.previewSampleTypes.count > 6 && indexPath.row > PreviewManager.previewSampleTypes.count - 4
            comparisonTips[indexPath.row] = TapTip(forView: targetView, withinView: tableView, text: desc, width: 350, numTaps: 2, numTouches: 1, asTop: tipAsTop)
            targetView.addGestureRecognizer(comparisonTips[indexPath.row]!.tapRecognizer)
//            targetView.userInteractionEnabled = true
        }

        return cell
    }

}
