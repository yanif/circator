//
//  AppDelegate.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 9/20/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit
import SwiftyBeaver
import Fabric
import Crashlytics
import Locksmith
import SwiftyUserDefaults
import WatchConnectivity

let log = SwiftyBeaver.self

@UIApplicationMain
/**
An overview of the Circator files and their connections follows. First, a reader should realize that MC="Metabolic Compass" and that the abbreviation is common in the code.  Also, Circator was the working name for Metabolic Compass, so the two names are present frequently and refer to this same application. Lastly, to orient those looking at the code, the CircatorKit provides the core functionality needed for the Circator code.  Highlights of that functionality are that all of the HealthKit calls and all of the formatting/unit conversions are done with CircatorKit code, and that the consent flow through ResearchKit along with the account set-up and API calls are in the CircatorKit code.

*/
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {

    var window: UIWindow?
    var mainViewController: UIViewController!
    private let firstRunKey = "FirstRun"
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        HKMock.mock()
        
        configureLogging()
        Fabric.with([Crashlytics.self,Answers.self])
        
        if ((Defaults.objectForKey(firstRunKey) == nil)) {
            UserManager.sharedManager.resetFull()
            Defaults.setObject("firstrun", forKey: firstRunKey)
            Defaults.synchronize()
        }
        
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
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: ScreenManager.appTitleTextColor(), NSFontAttributeName: ScreenManager.appNavBarFont()]
//        UINavigationBar.appearance().tintColor = ScreenManager.appNavigationBackColor()


        //set custom back button image
        let backBtnImg = UIImage(named: "back-button")

        UINavigationBar.appearance().backIndicatorImage = backBtnImg
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = backBtnImg


        let tabBarStoryboard = UIStoryboard(name: "TabScreens", bundle: nil)
        let tabBarScreen = tabBarStoryboard.instantiateViewControllerWithIdentifier("TabBarController")
        mainViewController = tabBarScreen

//        mainViewController = IntroViewController(nibName: nil, bundle: nil)
        let navController  = UINavigationController(rootViewController: mainViewController)
        AccountManager.shared.rootViewController = navController
        
        FontScaleLabel.scaleFactor = ScreenManager.scaleFactor
        FontScaleTextField.scaleFactor = ScreenManager.scaleFactor

        window?.rootViewController = navController
        window?.makeKeyAndVisible()
                
        return true
    }

    func application(application: UIApplication, supportedInterfaceOrientationsForWindow window: UIWindow?) -> UIInterfaceOrientationMask {
        //return checkOrientation(self.window?.rootViewController)
        return UIInterfaceOrientationMask.Portrait
    }

    func checkOrientation(viewController: UIViewController?) -> UIInterfaceOrientationMask {
        if viewController == nil {
            return .All
        } else if viewController is IntroViewController {
            return .Portrait
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
    }

    func applicationWillEnterForeground(application: UIApplication) {
//        mainViewController.fetchRecentSamples()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
        }
    }
    
    private func sendDictValuesToWatch() {
        var testDict:[String:String] = ["str1": "1.0"]
        if WCSession.isSupported() {
            let session = WCSession.defaultSession()
            if session.watchAppInstalled {
                do {
                    //                        let dictionary = ["movies": movies]
                    try session.updateApplicationContext(testDict)
                } catch {
                    print("ERROR: \(error)")
                }
            }
        }
    }
}


import Foundation
import HealthKit
import HealthKitSampleGenerator

class HKMock {
    

    class func mock() {
        
        // setup an output file name
        let fm              = NSFileManager.defaultManager()
        let documentsUrl    = fm.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        let outputFileName  = documentsUrl.URLByAppendingPathComponent("export.json").path!
        
        // create a target for the export - all goes in a single json file
        let target          = JsonSingleDocAsFileExportTarget(outputFileName: outputFileName, overwriteIfExist:true)
        
        // configure the export
        var configuration   = HealthDataFullExportConfiguration(profileName: "Profilname", exportType: HealthDataToExportType.ALL)
        configuration.exportUuids = false //false is default - if true, all uuids will be exported too
        
        // create your instance of HKHeakthStore
        let healthStore     = HKHealthStore()
        // and pass it to the HealthKitDataExporter
        let exporter        = HealthKitDataExporter(healthStore: healthStore)
        
        // now start the import.
        exporter.export(
            
            exportTargets: [target],
            
            exportConfiguration: configuration,
            
            onProgress: {
                (message: String, progressInPercent: NSNumber?) -> Void in
                // output progress messages
                dispatch_async(dispatch_get_main_queue(), {
                    print(message)
                })
            },
            
            onCompletion: {
                (error: ErrorType?)-> Void in
                // output the result - if error is nil. everything went well
                dispatch_async(dispatch_get_main_queue(), {
                    if let exportError = error {
                        print(exportError)
                    }
                })
            }
        )
    
    }

}
