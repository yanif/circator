//
//  AppDelegate.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 9/20/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import GameKit
import MetabolicCompassKit
import MCCircadianQueries
import SwiftyBeaver
import Fabric
import Crashlytics
import Locksmith
import SwiftDate
import SwiftyUserDefaults
import WatchConnectivity

let log = SwiftyBeaver.self

@UIApplicationMain
/**
An overview of the Circator files and their connections follows. First, a reader should realize that MC="Metabolic Compass" and that the abbreviation is common in the code.  Also, Circator was the working name for Metabolic Compass, so the two names are present frequently and refer to this same application. Lastly, to orient those looking at the code, the CircatorKit provides the core functionality needed for the Circator code.  Highlights of that functionality are that all of the HealthKit calls and all of the formatting/unit conversions are done with CircatorKit code, and that the consent flow through ResearchKit along with the account set-up and API calls are in the CircatorKit code.

*/
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate
{

    var window: UIWindow?
    var mainViewController: UIViewController!
    private let firstRunKey = "FirstRun"

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        configureLogging()
        Fabric.with([Crashlytics.self,Answers.self])

        log.info("Using service URL: \(MCRouter.baseURL)")

        if ((Defaults.objectForKey(firstRunKey) == nil)) {
            UserManager.sharedManager.resetFull()
            Defaults.setObject("firstrun", forKey: firstRunKey)
            Defaults.synchronize()
        }

        // Set up notifications after launching the app.
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        AccountManager.shared.resetLocalNotifications()
        recycleNotification()
        UINotifications.configureNotifications()

        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.backgroundColor = UIColor.whiteColor()

        // Override point for customization after application launch.
        // Sets background to a blank/empty image
        UINavigationBar.appearance().setBackgroundImage(UIImage(), forBarMetrics: .Default)

        // Sets shadow (line below the bar) to a blank image
        UINavigationBar.appearance().shadowImage = UIImage()

        // Sets the translucent background color
        UINavigationBar.appearance().backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)

        // Set translucent. (Default value is already true, so this can be removed if desired.)
        UINavigationBar.appearance().translucent = true
        UINavigationBar.appearance().titleTextAttributes = [
            NSForegroundColorAttributeName: ScreenManager.appTitleTextColor(),
            NSFontAttributeName: ScreenManager.appNavBarFont()
        ]


        //set custom back button image
        let backBtnImg = UIImage(named: "back-button")

        UINavigationBar.appearance().backIndicatorImage = backBtnImg
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = backBtnImg


        let tabBarStoryboard = UIStoryboard(name: "TabScreens", bundle: nil)
        let tabBarScreen = tabBarStoryboard.instantiateViewControllerWithIdentifier("TabBarController")
        mainViewController = tabBarScreen

        let navController  = UINavigationController(rootViewController: mainViewController)
        AccountManager.shared.rootViewController = navController
        
        FontScaleLabel.scaleFactor = ScreenManager.scaleFactor
        FontScaleTextField.scaleFactor = ScreenManager.scaleFactor

        window?.rootViewController = navController
        window?.makeKeyAndVisible()

        // Add a recycling observer.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(recycleNotification), name: USNDidUpdateBlackoutNotification, object: nil)

        // Add a debugging observer.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(errorNotification(_:)), name: MCRemoteErrorNotification, object: nil)

        return true
    }

    func application(application: UIApplication, supportedInterfaceOrientationsForWindow window: UIWindow?) -> UIInterfaceOrientationMask {
        //return checkOrientation(self.window?.rootViewController)
        return UIInterfaceOrientationMask.Portrait
    }

    func checkOrientation(viewController: UIViewController?) -> UIInterfaceOrientationMask {
        if viewController == nil {
            return .All
        } else if viewController is QueryViewController {
            return .Portrait
        } else if viewController is QueryBuilderViewController {
            return .Portrait
        } else if viewController is UINavigationController {
            return checkOrientation((viewController as? UINavigationController)!.visibleViewController)
        } else {
            return checkOrientation(viewController!.presentedViewController)
        }
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        recycleNotification()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        recycleNotification()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(application: UIApplication, didRegisterUserNotificationSettings: UIUserNotificationSettings) {
        let enabled = didRegisterUserNotificationSettings.types != .None
        log.info("APPDEL Enabling user notifications: \(enabled)")
        Defaults.setObject(enabled, forKey: AMNotificationsKey)
        Defaults.synchronize()
    }

    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        log.info("APPDEL received \(notification)")
        NotificationManager.sharedManager.showInApp(notification)
    }

    func configureLogging() {
        // add log destinations. at least one is needed!
        let console = ConsoleDestination()
        console.detailOutput = true
        console.colored = false
        console.minLevel = .Info

        let paths : [String : SwiftyBeaver.Level] = ["ServiceAPI":.Verbose, "HealthManager":.Debug]
        let pathfuns : [String : SwiftyBeaver.Level] = [:]

//        for (p,l) in paths { console.addFilter(Filters.Path.contains(p, minLevel: l)) }
//        for (f,l) in pathfuns { console.addFilter(Filters.Function.contains(f, minLevel: l)) }

        log.addDestination(console)
    }

    func recycleNotification() {
        NotificationManager.sharedManager.onRecycleEvent()
    }

    func errorNotification(notification: NSNotification) {
        if let info = notification.userInfo, event = info["event"] as? String, attrs = info["attrs"] as? [String: AnyObject]
        {
            Answers.logCustomEventWithName(event, customAttributes: attrs)
        }
    }

    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
        }
    }
}
