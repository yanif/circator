//
//  AddActivityManager.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 9/25/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit
import HealthKit
import MetabolicCompassKit
import Async
import SwiftDate
import Crashlytics
import AwesomeCache
import HTPressableButton
import AKPickerView_Swift
import MCCircadianQueries

typealias FrequentActivityCache = Cache<FrequentActivityInfo>

class AppPickerManager: PickerManager, PickerManagerSelectionDelegate {

    var apps: [UIStackView]

    private var notificationView: UIView! = nil

    static let activityApps: [String: AnyObject] = [
        "Cardiograph"     : "cardiograph:",
        "Sleep Cycle"     : "fb162575247235:", /* Sleep Cycle */
        "Runkeeper"       : "fb62572192129:", /* Runkeeper */
        "FitBit"          : "fitbit:",
        "Garmin"          : "garmin:",
        "LoseIt"          : "loseit:",
        "MyFitnessPal"    : "mfp:",
        "MyFitnessPal HD" : "mfphd:",
        "MyPlate"         : "myplate:",
        "Nike+ Run Club"  : "nikeplus:",
        "Strava"          : "strava:",
        "HealthMate"      : "withings-bd2:"
    ]

    static let appIcons: [String: AnyObject] = [
        "Cardiograph"     : "icon-Cardiograph",
        "Sleep Cycle"     : "icon-SleepCycle",
        "Runkeeper"       : "icon-runkeeper",
        "FitBit"          : "icon-fitbit",
        "Garmin"          : "icon-Garmin",
        "LoseIt"          : "icon-LoseIt",
        "MyFitnessPal"    : "icon-myfitnesspal",
        "MyFitnessPal HD" : "icon-myfitnesspal",
        "MyPlate"         : "icon-MyPlate",
        "Nike+ Run Club"  : "icon-Nike+RunClub",
        "Strava"          : "icon-Strava",
        "HealthMate"      : "icon-WithingsHealthMate"
    ]

    var availableActivityApps: [String: AnyObject] = [:]

    init(notificationView: UIView!) {
        self.notificationView = notificationView

        self.availableActivityApps = Dictionary(pairs: AppPickerManager.activityApps.filter { (name, scheme) in
            if let scheme = scheme as? String, url = NSURL(string: "\(scheme)//") {
                return UIApplication.sharedApplication().canOpenURL(url)
            }
            log.debug("App \(name) unavailable with scheme: \(scheme)", feature: "appIntegration")
            return false
        })

        let ctor : String -> UIImageView = { name in
            let image = UIImage(named: AppPickerManager.appIcons[name]! as! String)!
            let view = UIImageView(image: image)
            view.backgroundColor = UIColor.clearColor()
            view.contentMode = .ScaleAspectFit
            view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            view.layer.cornerRadius = 8
            view.layer.masksToBounds = true
            view.layer.shadowColor = UIColor.lightGrayColor().CGColor
            view.layer.shadowOffset = CGSize(width: 3, height: 3)
            view.layer.shadowOpacity = 0.7
            view.layer.shadowRadius = 4.0
            return view
        }

        let appNames = availableActivityApps.map({ $0.0 }).sort()

        self.apps = appNames.map { name in
            let stack = UIComponents.createLabelledComponent(name, labelOnTop: false, labelFontSize: 12.0, stackAlignment: .Center, value: name, constructor: ctor)
            stack.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            return stack
        }

        super.init(itemType: "Apps", items: appNames, data: availableActivityApps)
    }

    func cellHeight() -> CGFloat {
        let screenSize = UIScreen.mainScreen().bounds.size
        return (screenSize.width / 5) + 28.0
    }

    func cellWidth(label: UILabel, image: UIImageView, item: Int) -> CGFloat {
        let height = cellHeight()

        let txt = label.text ?? ""
        let size = txt.sizeWithAttributes([NSFontAttributeName: label.font])
        return max(max(size.width, image.image!.size.width), height)
    }

    // MARK: - AKPickerViewDataSource View-centric interface
    func pickerView(pickerView: AKPickerView, viewForItem item: Int) -> UIView {
        return self.apps[item]
    }

    func pickerView(pickerView: AKPickerView, cellForItem: AKCollectionViewCell, constraintsForItem item: Int) -> [NSLayoutConstraint] {
        let height = cellHeight()

        let image = apps[item].subviews[0] as! UIImageView
        let label = apps[item].subviews[1] as! UILabel

        image.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        let width = cellWidth(label, image: image, item: item)

        let constraints: [NSLayoutConstraint] = [
            image.widthAnchor.constraintEqualToAnchor(image.heightAnchor),
            cellForItem.contentView.heightAnchor.constraintEqualToConstant(height),
            cellForItem.contentView.topAnchor.constraintEqualToAnchor(apps[item].topAnchor, constant: -10.0),
            cellForItem.contentView.bottomAnchor.constraintEqualToAnchor(apps[item].bottomAnchor, constant: 10.0),
            cellForItem.contentView.centerXAnchor.constraintEqualToAnchor(apps[item].centerXAnchor),
            apps[item].heightAnchor.constraintEqualToConstant(height - 20.0),
            apps[item].centerXAnchor.constraintEqualToAnchor(image.centerXAnchor),
            apps[item].centerXAnchor.constraintEqualToAnchor(label.centerXAnchor),
            image.heightAnchor.constraintEqualToConstant(height - (label.font.lineHeight + 28.0)),
            label.widthAnchor.constraintEqualToConstant(width)
        ]

        constraints[0].priority = 1000
        return constraints
    }

    func pickerView(pickerView: AKPickerView, configureView view: UIView, forItem item: Int) {
        configureItemContentView(view, item: item)
    }

    func pickerView(pickerView: AKPickerView, contentHeightForItem item: Int) -> CGFloat {
        return cellHeight()
    }

    func pickerView(pickerView: AKPickerView, contentWidthForItem item: Int) -> CGFloat {
        let height = cellHeight()

        if let label = apps[item].subviews[1] as? UILabel, image = apps[item].subviews[0] as? UIImageView {
            return cellWidth(label, image: image, item: item)
        }
        return height
    }

    // MARK : - PickerManagerSelectionDelegate
    func pickerItemSelected(pickerManager: PickerManager, itemType: String?, index: Int, item: String, data: AnyObject?) {
        if let scheme = data as? String, url = NSURL(string: "\(scheme)//") {
            if UIApplication.sharedApplication().canOpenURL(url) {
                UIApplication.sharedApplication().openURL(url)
            }
            else {
                Async.main {
                    log.error("Could not find \(url)", feature: "appIntegration")
                    let msg = "We could not find your \(item) app, please restart Metabolic Compass if you've uninstalled it."
                    UINotifications.genericErrorOnView(self.notificationView, msg: msg)
                }
            }
        }
        else {
            Async.main {
                log.error("Invalid URL scheme for \(data)", feature: "appIntegration")
                let msg = "Failed to open your \(item) app!"
                UINotifications.genericErrorOnView(self.notificationView, msg: msg)
            }
        }

        self.finishProcessingSelection()
    }
}


public class AddActivityManager: UITableView, UITableViewDelegate, UITableViewDataSource, PickerManagerSelectionDelegate {

    public var menuItems: [PathMenuItem]

    private var quickAddButtons: [SlideButtonArray] = []

    // Cache frequent activities by day of week.
    private var frequentActivitiesCache: FrequentActivityCache

    private var frequentActivities: [FrequentActivity] = []
    private var shadowActivities: [FrequentActivity] = []

    // Row to activity date
    private var frequentActivityByRow: [Int: FrequentActivity] = [:]
    private var nextActivityRowExpiry: NSDate = NSDate().startOf(.Day)
    private let nextActivityExpiryIncrement: NSDateComponents = 1.minutes // 10.minutes

    // Activity date to cell contents.
    private var frequentActivityCells: [Int: [UIView]] = [:]

    private let cacheDuration: Double = 60 * 60

    private let addEventCellIdentifier = "addEventCell"
    private let addEventSectionHeaderCellIdentifier = "addEventSectionHeaderCell"

    private var notificationView: UIView! = nil

    private var appManager: AppPickerManager! = nil
    private var appPicker: AKPickerView! = nil

    // Section and title configuration
    private var addSectionTitles = [String]()
    private var sectionRows = [Int]()

    private var frequentActivitySectionIdx = 3

    // Section title and index constants.
    private let sectionTitlesWithApps = ["Just-In-Time Activity", "Retrospective Activity", "Your Apps", "Frequent Activities"]
    private let sectionTitlesNoApps = ["Just-In-Time Activity", "Retrospective Activity", "Frequent Activities"]

    private let sectionRowsWithApps = [2, 1, 1, 0]
    private let sectionRowsNoApps = [2, 1, 0]

    private var frequentActivitySectionIdxWithApps = 3
    private var frequentActivitySectionIdxNoApps = 2


    public init(frame: CGRect, style: UITableViewStyle, menuItems: [PathMenuItem], notificationView: UIView!) {
        do {
            self.frequentActivitiesCache = try FrequentActivityCache(name: "MCAddFrequentActivities")
        } catch _ {
            fatalError("Unable to create frequent activites cache.")
        }

        self.menuItems = menuItems
        self.notificationView = notificationView
        super.init(frame: frame, style: style)
        self.setupTable()
    }

    required public init?(coder aDecoder: NSCoder) {
        do {
            self.frequentActivitiesCache = try FrequentActivityCache(name: "MCAddFrequentActivities")
        } catch _ {
            fatalError("Unable to create frequent activites cache.")
        }

        guard let mi = aDecoder.decodeObjectForKey("menuItems") as? [PathMenuItem] else {
            menuItems = []; super.init(frame: CGRect.zero, style: .Grouped); return nil
        }

        menuItems = mi
        super.init(coder: aDecoder)
    }

    override public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(menuItems, forKey: "menuItems")
    }

    func frequentActivityCacheKey(date: NSDate) -> String {
        return "\(date.weekday)"
    }

    private func setupTable() {
        self.hidden = true
        self.allowsSelection = false
        self.separatorStyle = .None
        self.layer.opacity = 0.0

        self.registerClass(UITableViewCell.self, forCellReuseIdentifier: addEventCellIdentifier)
        self.registerClass(UITableViewCell.self, forCellReuseIdentifier: addEventSectionHeaderCellIdentifier)

        self.delegate = self;
        self.dataSource = self;

        self.estimatedRowHeight = 100.0
        self.estimatedSectionHeaderHeight = 66.0
        self.rowHeight = UITableViewAutomaticDimension
        self.sectionHeaderHeight = UITableViewAutomaticDimension

        self.separatorInset = UIEdgeInsetsZero
        self.layoutMargins = UIEdgeInsetsZero
        self.cellLayoutMarginsFollowReadableWidth = false

        quickAddButtons.append(SlideButtonArray(frame: CGRect.zero, buttonsTag: 3000, arrayRowIndex: 0))
        quickAddButtons.append(SlideButtonArray(frame: CGRect.zero, buttonsTag: 4000, arrayRowIndex: 1))

        // Configure delegates.
        quickAddButtons[0].delegate = self
        quickAddButtons[1].delegate = self

        // Configure exclusive selection.
        quickAddButtons[0].exclusiveArrays.append(quickAddButtons[1])
        quickAddButtons[1].exclusiveArrays.append(quickAddButtons[0])

        // Configure app picker.
        let manager = AppPickerManager(notificationView: self.notificationView ?? self.superview)
        if manager.availableActivityApps.isEmpty {
            addSectionTitles = sectionTitlesNoApps
            sectionRows = sectionRowsNoApps
            frequentActivitySectionIdx = frequentActivitySectionIdxNoApps

        } else {
            addSectionTitles = sectionTitlesWithApps
            sectionRows = sectionRowsWithApps
            frequentActivitySectionIdx = frequentActivitySectionIdxWithApps

            appManager = manager
            appManager.delegate = appManager

            appPicker = AKPickerView()
            appPicker.delegate = appManager
            appPicker.dataSource = appManager
            appPicker.interitemSpacing = 10

            let pickerFont = UIFont(name: "GothamBook", size: 18.0)!
            appPicker.font = pickerFont
            appPicker.highlightedFont = pickerFont

            appPicker.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.0)
            appPicker.highlightedTextColor = UIColor.whiteColor()
            appPicker.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)
            appPicker.reloadData()
        }
    }

    private func descOfCircadianEvent(event: CircadianEvent) -> String {
        switch event {
        case .Meal(let mealType):
            return mealType.rawValue
        case .Exercise(let exerciseType):
            switch exerciseType {
            case .Running: return "Running"
            case .Cycling: return "Cycling"
            default: return "Exercise"
            }
        case .Sleep:
            return "Sleep"
        default:
            return ""
        }
    }

    private func frequentActivityCellView(tag: Int, aInfo: FrequentActivity) -> [UIView] {
        let fmt = DateFormat.Custom("HH:mm")
        let endDate = aInfo.start.dateByAddingTimeInterval(aInfo.duration)

        let label = UILabel()
        label.backgroundColor = .clearColor()
        label.textColor = .lightGrayColor()
        label.textAlignment = .Left

        let dayTxt = aInfo.start.isInToday() ? "" : "yesterday "
        let stTxt = aInfo.start.toString(fmt)!
        let enTxt = endDate.toString(fmt)!
        label.text = "\(aInfo.desc), \(dayTxt)\(stTxt) - \(enTxt)"

        let unchecked_image = UIImage(named: "checkbox-unchecked-register") as UIImage?
        let checked_image = UIImage(named: "checkbox-checked-register") as UIImage?
        let button = UIButton(type: .Custom)

        button.tag = tag
        button.backgroundColor = .clearColor()
        button.setImage(unchecked_image, forState: .Normal)
        button.setImage(checked_image, forState: .Selected)
        button.addTarget(self, action: #selector(self.addFrequentActivity(_:)), forControlEvents: .TouchUpInside)

        return [label, button]
    }

    func addFrequentActivity(sender: UIButton) {
        log.debug("Selected freq. activity \(sender.tag)", feature: "freqActivity")
        sender.selected = !sender.selected
    }

    private func refreshFrequentActivities() {
        let now = NSDate()
        let nowStart = now.startOf(.Day)

        let cacheKey = frequentActivityCacheKey(nowStart)

        log.debug("Refreshing activities \(self.nextActivityRowExpiry)", feature: "freqActivity")

        frequentActivitiesCache.setObjectForKey(cacheKey, cacheBlock: { (success, failure) in
            // if weekday populate from previous day and same day last week
            // else populate from the same day for the past 4 weekends
            var queryStartDates: [NSDate] = []

            // Since sleep events may span the end of day boundary, we also include the previous day.
            if nowStart.weekday < 6 {
                queryStartDates = [(nowStart - 1.weeks) - 1.days, nowStart - 1.weeks, nowStart - 2.days, nowStart - 1.days]
            } else {
                // TODO: the 3rd and 4th weeks will not be cached since MCHealthManager uses a 2-week cache by default.
                queryStartDates = (1...4).flatMap { [(nowStart - $0.weeks) - 1.days, nowStart - $0.weeks] }
            }

            var activities: [FrequentActivity] = []

            var circadianEvents: [NSDate: [(NSDate, CircadianEvent)]] = [:]
            var queryErrors: [NSError?] = []
            let queryGroup = dispatch_group_create()

            queryStartDates.forEach { date in
                dispatch_group_enter(queryGroup)
                MCHealthManager.sharedManager.fetchCircadianEventIntervals(date, endDate: date.endOf(.Day), noTruncation: true)
                { (intervals, error) in
                    guard error == nil else {
                        log.error("Failed to fetch circadian events: \(error)", feature: "freqActivity")
                        queryErrors.append(error)
                        dispatch_group_leave(queryGroup)
                        return
                    }
                    circadianEvents[date] = intervals
                    dispatch_group_leave(queryGroup)
                }
            }

            dispatch_group_notify(queryGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                guard queryErrors.isEmpty else {
                    failure(queryErrors.first!)
                    return
                }

                // Turn into activities by merging and accumulating circadian events.
                //log.info("FAQ finished with \(circadianEvents.count) results")
                //log.info("FAQ results \(circadianEvents)")

                var dateIndex = 0
                while dateIndex < queryStartDates.count {
                    let nextDateIndex = dateIndex + 1
                    if ( nextDateIndex < queryStartDates.count )
                        && ( queryStartDates[dateIndex].compare(queryStartDates[nextDateIndex] - 1.days) == .OrderedSame )
                    {
                        if let e1 = circadianEvents[queryStartDates[dateIndex]], e2 = circadianEvents[queryStartDates[nextDateIndex]] {
                            let eventsUnion = e1 + e2
                            eventsUnion.enumerate().forEach { (index, eventEdge) in
                                let nextIndex = index+1
                                if index % 2 == 0 && nextIndex < eventsUnion.count {
                                    let (nextEdgeDate, nextEdgeEvent) = eventsUnion[nextIndex]
                                    if ( eventEdge.1 != CircadianEvent.Fast ) && ( eventEdge.1 == nextEdgeEvent ) {
                                        let desc = self.descOfCircadianEvent(eventEdge.1)
                                        let duration = nextEdgeDate.timeIntervalSinceReferenceDate  - eventEdge.0.timeIntervalSinceReferenceDate
                                        activities.append(FrequentActivity(desc: desc, start: eventEdge.0, duration: duration))
                                    }
                                }
                            }
                        }
                    }
                    dateIndex += 1
                }

                // Deduplicate activities relative to today.
                var activitiesToday : [Int: FrequentActivity] = [:]

                activities.forEach { aInfo in
                    let secondsSinceDay = aInfo.start.timeIntervalSinceDate(aInfo.start.startOf(.Day))
                    let startInToday = nowStart.dateByAddingTimeInterval(secondsSinceDay)

                    let aInfo = FrequentActivity(desc: aInfo.desc, start: startInToday, duration: aInfo.duration)
                    let key = aInfo.start.hashValue + Int(aInfo.duration)
                    activitiesToday[key] = aInfo
                }

                //log.info("FAQ dedup \(activitiesToday)")

                activities = activitiesToday.map({ $0.1 }).sort { $0.0.start < $0.1.start }
                success(FrequentActivityInfo(activities: activities), CacheExpiry.Seconds(self.cacheDuration))
            } // end cacheBlock

            }, completion: { (activityInfoFromCache, loadedFromCache, error) in
                log.debug("Cache result: \(activityInfoFromCache?.activities.count ?? -1) (hit: \(loadedFromCache))", feature: "cache:freqActivity")

                guard error == nil else {
                    log.error("Failed to populate frequent activities: \(error)")
                    self.frequentActivities = []
                    self.shadowActivities = []
                    return
                }

                // Create a cell's content for each frequent activity.
                if let aInfos = activityInfoFromCache?.activities {
                    self.shadowActivities = aInfos
                    if aInfos.isEmpty {
                        // Advance the refresh guard if we have no cached activities
                        self.nextActivityRowExpiry = now + self.nextActivityExpiryIncrement
                    }
                } else {
                    // Advance the refresh guard if we have no cached activities
                    self.nextActivityRowExpiry = now + self.nextActivityExpiryIncrement
                }

                // Refresh the table.
                Async.main { self.reloadData() }
        })
    }

    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return addSectionTitles.count
    }

    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == frequentActivitySectionIdx {
            log.debug("Activities #rows \(shadowActivities.count) \(frequentActivities.count)", feature: "freqActivity")

            let now = NSDate()
            let nowStart = now.startOf(.Day)

            // Swap buffer.
            if shadowActivities.count > 0 {
                frequentActivities = shadowActivities
                shadowActivities = []
            }

            if nextActivityRowExpiry <= now {
                // Refresh cache as needed.
                let cacheKey = frequentActivityCacheKey(nowStart)

                if frequentActivities.isEmpty || frequentActivitiesCache.objectForKey(cacheKey) == nil {
                    //log.debug("Refreshing cache", feature: "cache:freqActivity")
                    frequentActivitiesCache.removeExpiredObjects()
                    refreshFrequentActivities()
                    return frequentActivityCells.isEmpty ? 1 : frequentActivityCells.count
                }
                else {
                    //log.info("Creating cells \(nextActivityRowExpiry) (now: \(now))", feature: "cache:freqActivity")

                    // Filter activities to within the last 24 hours and create the row mapping.
                    frequentActivityByRow.removeAll()
                    frequentActivityCells.removeAll()

                    let reorderedActivities: [FrequentActivity] = frequentActivities.map({ aInfo in
                        if aInfo.start > now {
                            return FrequentActivity(desc: aInfo.desc, start: aInfo.start - 1.days, duration: aInfo.duration)
                        }
                        return aInfo
                    }).sort({ $0.0.start < $0.1.start })

                    reorderedActivities.enumerate().forEach { (index, aInfo) in
                        self.frequentActivityByRow[index] = aInfo
                        self.frequentActivityCells[index] = self.frequentActivityCellView(index, aInfo: aInfo)
                    }
                    
                    nextActivityRowExpiry = now + nextActivityExpiryIncrement
                }
            } else {
                log.debug("Activities will expire at \(nextActivityRowExpiry) (now: \(now))", feature: "cache:freqActivity")
            }

            return frequentActivityCells.isEmpty ? 1 : frequentActivityCells.count
        }
        else if section < sectionRows.count {
            return sectionRows[section]
        }
        return 0
    }

    public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return addSectionTitles[section]
    }

    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(addEventCellIdentifier, forIndexPath: indexPath)

        for sv in cell.contentView.subviews { sv.removeFromSuperview() }
        cell.textLabel?.hidden = true
        cell.imageView?.image = nil
        cell.accessoryType = .None
        cell.selectionStyle = .None

        cell.backgroundColor = UIColor.clearColor()
        cell.contentView.backgroundColor = UIColor.clearColor()

        if indexPath.section == 0  {
            let v = quickAddButtons[indexPath.row]
            v.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(v)

            let constraints : [NSLayoutConstraint] = [
                cell.contentView.topAnchor.constraintEqualToAnchor(v.topAnchor, constant: -10),
                cell.contentView.bottomAnchor.constraintEqualToAnchor(v.bottomAnchor, constant: 10),
                cell.contentView.leadingAnchor.constraintEqualToAnchor(v.leadingAnchor, constant: -10),
                cell.contentView.trailingAnchor.constraintEqualToAnchor(v.trailingAnchor, constant: 10)
            ]

            cell.contentView.addConstraints(constraints)
        }
        else if indexPath.section == 1 {
            let stackView: UIStackView = UIStackView(arrangedSubviews: self.menuItems ?? [])
            stackView.axis = .Horizontal
            stackView.distribution = UIStackViewDistribution.FillEqually
            stackView.alignment = UIStackViewAlignment.Fill
            stackView.spacing = 0

            stackView.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(stackView)

            let stackConstraints : [NSLayoutConstraint] = [
                cell.contentView.topAnchor.constraintEqualToAnchor(stackView.topAnchor, constant: -10),
                cell.contentView.bottomAnchor.constraintEqualToAnchor(stackView.bottomAnchor, constant: 10),
                cell.contentView.leadingAnchor.constraintEqualToAnchor(stackView.leadingAnchor),
                cell.contentView.trailingAnchor.constraintEqualToAnchor(stackView.trailingAnchor)
            ]

            cell.contentView.addConstraints(stackConstraints)
        }
        else if indexPath.section == 2 && appPicker != nil {
            appPicker.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(appPicker)

            let constraints : [NSLayoutConstraint] = [
                cell.contentView.topAnchor.constraintEqualToAnchor(appPicker.topAnchor),
                cell.contentView.bottomAnchor.constraintEqualToAnchor(appPicker.bottomAnchor),
                cell.contentView.leadingAnchor.constraintEqualToAnchor(appPicker.leadingAnchor, constant: -10),
                cell.contentView.trailingAnchor.constraintEqualToAnchor(appPicker.trailingAnchor, constant: 10)
            ]

            cell.contentView.addConstraints(constraints)
        }
        else {
            var activityCells: [UIView] = []
            if let views = frequentActivityCells[indexPath.row] {
                activityCells = views
            } else {
                let label = UILabel()
                label.backgroundColor = .clearColor()
                label.textColor = .lightGrayColor()
                label.textAlignment = .Center
                label.text = "No frequent activities found"
                activityCells.append(label)
            }

            let stackView: UIStackView = UIStackView(arrangedSubviews: activityCells)

            stackView.axis = .Horizontal
            stackView.distribution = UIStackViewDistribution.EqualSpacing
            stackView.alignment = UIStackViewAlignment.Fill
            stackView.spacing = 0

            stackView.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(stackView)

            let stackConstraints : [NSLayoutConstraint] = [
                cell.contentView.topAnchor.constraintEqualToAnchor(stackView.topAnchor, constant: -10),
                cell.contentView.bottomAnchor.constraintEqualToAnchor(stackView.bottomAnchor, constant: 10),
                cell.contentView.leadingAnchor.constraintEqualToAnchor(stackView.leadingAnchor, constant: -20),
                cell.contentView.trailingAnchor.constraintEqualToAnchor(stackView.trailingAnchor, constant: 20)
            ]

            cell.contentView.addConstraints(stackConstraints)
        }
        return cell
    }

    //MARK: UITableViewDelegate
    public func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier(addEventSectionHeaderCellIdentifier)!

        let sectionHeaderSize = ScreenManager.sharedInstance.quickAddSectionHeaderFontSize()

        cell.textLabel?.text = self.addSectionTitles[section]
        cell.textLabel?.font = UIFont(name: "GothamBook", size: sectionHeaderSize)
        cell.textLabel?.textColor = .lightGrayColor()
        cell.textLabel?.numberOfLines = 0

        if section == 0 || section == frequentActivitySectionIdx {
            for sv in cell.contentView.subviews { sv.removeFromSuperview() }

            let button = UIButton(frame: CGRectMake(0, 0, 44, 44))
            button.backgroundColor = .clearColor()

            button.setImage(UIImage(named: "icon-quick-add-tick"), forState: .Normal)
            button.imageView?.contentMode = .ScaleAspectFit

            button.addTarget(self, action: (section == frequentActivitySectionIdx ? #selector(self.handleFrequentAddTap(_:)) : #selector(self.handleQuickAddTap(_:))), forControlEvents: .TouchUpInside)

            button.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(button)

            let buttonConstraints : [NSLayoutConstraint] = [
                cell.contentView.topAnchor.constraintEqualToAnchor(button.topAnchor, constant: -20),
                cell.contentView.bottomAnchor.constraintEqualToAnchor(button.bottomAnchor, constant: 10),
                cell.contentView.trailingAnchor.constraintEqualToAnchor(button.trailingAnchor, constant: 20),
                button.widthAnchor.constraintEqualToConstant(44),
                button.heightAnchor.constraintEqualToConstant(44)
            ]

            cell.contentView.addConstraints(buttonConstraints)
        }

        return cell;
    }

    func circadianOpCompletion(sender: UIButton?, manager: PickerManager?, displayError: Bool, error: NSError?) -> Void {
        Async.main {
            if error == nil {
                UINotifications.genericSuccessMsgOnView(self.notificationView ?? self.superview!, msg: "Successfully added events.")
            }
            else {
                let msg = displayError ? (error?.localizedDescription ?? "Unknown error") : "Failed to add event"
                UINotifications.genericErrorOnView(self.notificationView ?? self.superview!, msg: msg)
            }
            if let sender = sender {
                sender.enabled = true
                sender.setNeedsDisplay()
            }
        }
        manager?.finishProcessingSelection()
        if error != nil { log.error(error!.localizedDescription) }
        else {
            NSNotificationCenter.defaultCenter().postNotificationName(MEMDidUpdateCircadianEvents, object: nil)
        }
    }

    func validateTimedEvent(startTime: NSDate, endTime: NSDate, completion: NSError? -> Void) {
        // Fetch all sleep and workout data since yesterday.
        let (yesterday, now) = (1.days.ago, NSDate())
        let sleepTy = HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierSleepAnalysis)!
        let workoutTy = HKWorkoutType.workoutType()
        let datePredicate = HKQuery.predicateForSamplesWithStartDate(yesterday, endDate: now, options: .None)
        let typesAndPredicates = [sleepTy: datePredicate, workoutTy: datePredicate]

        // Aggregate sleep, exercise and meal events.
        MCHealthManager.sharedManager.fetchSamples(typesAndPredicates) { (samples, error) -> Void in
            guard error == nil else { log.error(error!.localizedDescription); return }
            let overlaps = samples.reduce(false, combine: { (acc, kv) in
                guard !acc else { return acc }
                return kv.1.reduce(acc, combine: { (acc, s) in return acc || !( startTime >= s.endDate || endTime <= s.startDate ) })
            })

            if !overlaps { completion(nil) }
            else {
                let msg = "This event overlaps with another, please try again"
                let err = NSError(domain: HMErrorDomain, code: 1048576, userInfo: [NSLocalizedDescriptionKey: msg])
                UINotifications.genericErrorOnView(self.notificationView ?? self.superview!, msg: msg)
                completion(err)
            }
        }
    }

    func addSleep(hoursSinceStart: Double, startDate: NSDate? = nil, completion: NSError? -> Void) {
        let startTime = startDate == nil ? (Int(hoursSinceStart * 60)).minutes.ago : startDate!
        let endTime = startDate == nil ? NSDate() : startDate! + (Int(hoursSinceStart * 60)).minutes

        log.debug("Saving sleep event: \(startTime) \(endTime)", feature: "addActivity")

        validateTimedEvent(startTime, endTime: endTime) { error in
            guard error == nil else {
                completion(error)
                return
            }

            MCHealthManager.sharedManager.saveSleep(startTime, endDate: endTime, metadata: [:]) {
                (success, error) -> Void in
                if error != nil { log.error(error!.localizedDescription) }
                else { log.debug("Saved sleep event: \(startTime) \(endTime)", feature: "addActivity") }
                completion(error)
            }
        }
    }

    func addMeal(mealType: String, minutesSinceStart: Int, startDate: NSDate? = nil, completion: NSError? -> Void) {
        let startTime = startDate == nil ? minutesSinceStart.minutes.ago : startDate!
        let endTime = startDate == nil ? NSDate() : startDate! + (Int(minutesSinceStart)).minutes
        let metadata = ["Meal Type": mealType]

        log.debug("Saving meal event: \(mealType) \(startTime) \(endTime)", feature: "addActivity")

        validateTimedEvent(startTime, endTime: endTime) { error in
            guard error == nil else {
                completion(error)
                return
            }

            MCHealthManager.sharedManager.savePreparationAndRecoveryWorkout(
                startTime, endDate: endTime, distance: 0.0, distanceUnit: HKUnit(fromString: "km"),
                kiloCalories: 0.0, metadata: metadata)
            {
                (success, error) -> Void in
                if error != nil { log.error(error!.localizedDescription) }
                else { log.debug("Saved meal event as workout type: \(mealType) \(startTime) \(endTime)", feature: "addActivity") }
                completion(error)
            }
        }
    }

    func addExercise(workoutType: HKWorkoutActivityType, minutesSinceStart: Int, startDate: NSDate? = nil, completion: NSError? -> Void) {
        let startTime = startDate == nil ? minutesSinceStart.minutes.ago : startDate!
        let endTime = startDate == nil ? NSDate() : startDate! + (Int(minutesSinceStart)).minutes

        log.debug("Saving exercise event: \(workoutType) \(startTime) \(endTime)", feature: "addActivity")

        validateTimedEvent(startTime, endTime: endTime) { error in
            guard error == nil else {
                completion(error)
                return
            }

            MCHealthManager.sharedManager.saveWorkout(
                startTime, endDate: endTime, activityType: workoutType,
                distance: 0.0, distanceUnit: HKUnit(fromString: "km"), kiloCalories: 0.0, metadata: [:])
            {
                (success, error ) -> Void in
                if error != nil { log.error(error!.localizedDescription) }
                else { log.debug("Saved exercise event as workout type: \(workoutType) \(startTime) \(endTime)", feature: "addActivity") }
                completion(error)
            }
        }
    }

    func processSelection(sender: UIButton?, pickerManager: PickerManager?, itemType: String, startDate: NSDate? = nil, duration: Double, durationInSecs: Bool) {
        var asSleep = false
        var workoutType : HKWorkoutActivityType? = nil
        var mealType: String? = nil

        switch itemType {
        case "Breakfast", "Lunch", "Dinner", "Snack":
            mealType = itemType

        case "Running":
            workoutType = .Running

        case "Cycling":
            workoutType = .Cycling

        case "Exercise":
            workoutType = .Other

        case "Sleep":
            asSleep = true

        default:
            break
        }

        if asSleep {
            addSleep(durationInSecs ? duration / 3600.0 : duration, startDate: startDate) {
                self.circadianOpCompletion(sender, manager: pickerManager, displayError: false, error: $0)
            }
        }
        else if let mt = mealType {
            let minutesSinceStart = Int(durationInSecs ? (duration / 60) : duration)
            addMeal(mt, minutesSinceStart: minutesSinceStart, startDate: startDate) {
                self.circadianOpCompletion(sender, manager: pickerManager, displayError: false, error: $0)
            }
        }
        else if let wt = workoutType {
            let minutesSinceStart = Int(durationInSecs ? (duration / 60) : duration)
            addExercise(wt, minutesSinceStart: minutesSinceStart, startDate: startDate) {
                self.circadianOpCompletion(sender, manager: pickerManager, displayError: false, error: $0)
            }
        }
        else {
            let msg = "Unknown activity type \(itemType)"
            let err = NSError(domain: HMErrorDomain, code: 1048576, userInfo: [NSLocalizedDescriptionKey: msg])
            circadianOpCompletion(sender, manager: pickerManager, displayError: true, error: err)
        }
    }


    func processSelection(sender: UIButton?, pickerManager: PickerManager,
                          itemType: String?, index: Int, item: String, data: AnyObject?)
    {
        if let itemType = itemType, let duration = data as? Double {
            processSelection(sender, pickerManager: pickerManager, itemType: itemType, duration: duration, durationInSecs: false)
        }
        else {
            let msg = itemType == nil ?
                "Unknown quick add event type \(itemType)" : "Failed to convert duration into integer: \(data)"

            let err = NSError(domain: HMErrorDomain, code: 1048576, userInfo: [NSLocalizedDescriptionKey: msg])
            circadianOpCompletion(sender, manager: pickerManager, displayError: true, error: err)
        }
    }

    func handleQuickAddTap(sender: UIButton) {
        log.debug("Quick add button pressed", feature: "addActivity")

        Async.main {
            sender.enabled = false
            sender.setNeedsDisplay()
        }

        let selection = quickAddButtons.reduce(nil, combine: { (acc, buttonArray) in
            return acc != nil ? acc : buttonArray.getSelection()
        })

        if let s = selection {
            processSelection(sender, pickerManager: s.0, itemType: s.1, index: s.2, item: s.3, data: s.4)
        } else {
            Async.main {
                UINotifications.genericErrorOnView(self.notificationView ?? self.superview!, msg: "No event selected")
                sender.enabled = true
                sender.setNeedsDisplay()
            }
        }
    }

    func handleFrequentAddTap(sender: UIButton) {
        log.debug("Adding selected frequent activities", feature: "addActivity")

        Async.main {
            sender.enabled = false
            sender.setNeedsDisplay()
        }

        // Iterate through all freq activity cells, check if button is selected, warn on overlap, and then add.
        var activitiesToAdd: [FrequentActivity] = []

        self.frequentActivityCells.forEach { kv in
            if let button = kv.1[1] as? UIButton where button.selected {
                if let aInfo = self.frequentActivityByRow[kv.0] {
                    activitiesToAdd.append(aInfo)
                }
                Async.main {
                    button.selected = false
                    button.setNeedsDisplay()
                }
            }
        }

        var overlaps = false
        for i in (0..<activitiesToAdd.count) {
            let iSt = activitiesToAdd[i].start
            let iEn = activitiesToAdd[i].start.dateByAddingTimeInterval(activitiesToAdd[i].duration)

            for j in (i+1..<activitiesToAdd.count) {
                let jSt = activitiesToAdd[j].start
                let jEn = activitiesToAdd[j].start.dateByAddingTimeInterval(activitiesToAdd[j].duration)
                overlaps = overlaps || !(jEn <= iSt || iEn <= jSt)
            }
        }
        
        if overlaps {
            Async.main {
                let msg = "You selected overlapping events, please try again"
                UINotifications.genericErrorOnView(self.notificationView ?? self.superview!, msg: msg)
                sender.enabled = true
                sender.setNeedsDisplay()
            }
        } else {
            for aInfo in activitiesToAdd {
                processSelection(nil, pickerManager: nil, itemType: aInfo.desc, startDate: aInfo.start, duration: aInfo.duration, durationInSecs: true)
            }
            Async.main {
                sender.enabled = true
                sender.setNeedsDisplay()
            }
        }
    }

    // MARK : - PickerManagerSelectionDelegate
    func pickerItemSelected(pickerManager: PickerManager, itemType: String?, index: Int, item: String, data: AnyObject?) {
        log.debug("Quick add picker selected \(itemType) \(item) \(data)", feature: "addActivity")
        processSelection(nil, pickerManager: pickerManager, itemType: itemType, index: index, item: item, data: data)
    }
    
}
