//
//  ScreenManager.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 2/19/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import UIKit
import Charts

/**
 We aim to support all Apple iPhone screen sizes. Towards that goal this class switches variables to reflect the user's particular phone. We use Apple's screen size from UIScreen to determine the appropriate values to set.

 */
public class ScreenManager {
    public static let sharedInstance = ScreenManager()


// MARK: - scaling

    public static let baseScreenWidth = CGFloat(375.0)
        
    private static var _scaleFactor:CGFloat? = nil
    public class var scaleFactor:CGFloat {
        if _scaleFactor == nil{
           _scaleFactor = UIScreen.mainScreen().bounds.width / ScreenManager.baseScreenWidth
           print("scaleFactor:\(_scaleFactor)")
        }
        return _scaleFactor!
    }

    func dodoFontSize() -> CGFloat {
        let screenSize = UIScreen.mainScreen().bounds.size
        let screenHeight = screenSize.height

        if (screenHeight < 569) {
            return 16
        } else {
            return 18
        }
    }

    func labelFontSize() -> CGFloat {
        let screenSize = UIScreen.mainScreen().bounds.size
        let screenHeight = screenSize.height

        if (screenHeight < 569) {
            return 14
        } else {
            return 16
        }
    }

    func inputFontSize() -> CGFloat {
        let screenSize = UIScreen.mainScreen().bounds.size
        let screenHeight = screenSize.height

        if (screenHeight < 569) {
            return 14
        } else {
            return 14
        }
    }

    public func tooltipMaxWidth() -> CGFloat {
        let screensize = UIScreen.mainScreen().bounds.size
        return 0.66 * screensize.width
    }

    public func dashboardRows() -> Int {
        let screenSize = UIScreen.mainScreen().bounds.size
        let screenHeight = screenSize.height

        if (screenHeight < 569) {
            return 4
        } else if (570 < screenHeight && screenHeight < 734) {
            return 6
        } else {
            return 7
        }
    }

    public func dashboardButtonHeight() -> CGFloat {
        let screenSize = UIScreen.mainScreen().bounds.size
        let screenHeight = screenSize.height

        if (screenHeight < 569) {
            return 28.0
        } else {
            return 35.0
        }
    }

    public func dashboardTitleLeading() -> CGFloat {
        let screenSize = UIScreen.mainScreen().bounds.size
        let screenHeight = screenSize.height

        if (screenHeight < 569) {
            return 60.0
        } else {
            return 80.0
        }
    }

    public func loginButtonFontSize() -> CGFloat {
        let screenSize = UIScreen.mainScreen().bounds.size
        let screenHeight = screenSize.height

        if (screenHeight < 569) {
            return 16.0
        } else {
            return 20.0
        }
    }

    public func settingsCellTrailing() -> CGFloat {
        let screenSize = UIScreen.mainScreen().bounds.size
        let screenHeight = screenSize.height

        if (screenHeight < 569) {
            return 15.0
        } else {
            return 20.0
        }
    }

    public func radarLegendPosition() -> ChartLegend.Position {
        return ChartLegend.Position.BelowChartCenter
    }

    public func eventTimeViewSummaryFontSize() -> CGFloat {
        let screenSize = UIScreen.mainScreen().bounds.size
        let screenHeight = screenSize.height

        if (screenHeight < 569) {
            return 18
        } else {
            return 24
        }
    }

    public func eventTimeViewPlotFontSize() -> CGFloat {
        let screenSize = UIScreen.mainScreen().bounds.size
        let screenHeight = screenSize.height

        if (screenHeight < 569) {
            return 10.5
        } else {
            return 12
        }
    }

    public func eventTimeViewHeight() -> CGFloat {
        let screenSize = UIScreen.mainScreen().bounds.size
        let screenHeight = screenSize.height

        if (screenHeight < 569) {
            return 60
        } else {
            return 100
        }
    }

    public func radarChartBottomIndent() -> CGFloat {
        let screenSize = UIScreen.mainScreen().bounds.size
        let screenHeight = screenSize.height

        if (screenHeight < 569) {
            return 20
        } else {
            return 50
        }
    }

    public func loginLabelFontSize() -> CGFloat {
        return labelFontSize()
    }

    public func loginInputFontSize() -> CGFloat {
        return inputFontSize()
    }

    public func profileLabelFontSize() -> CGFloat {
        return labelFontSize()
    }

    public func profileInputFontSize() -> CGFloat {
        return inputFontSize()
    }

    public func queryBuilderLabelFontSize() -> CGFloat {
        return labelFontSize()
    }

    public func queryBuilderInputFontSize() -> CGFloat {
        return inputFontSize()
    }

    public func quickAddSectionHeaderFontSize() -> CGFloat {
        let screenSize = UIScreen.mainScreen().bounds.size
        let screenHeight = screenSize.height

        if (screenHeight < 569) {
            return 16.0
        } else {
            return 18.0
        }
    }


    // MARK: - colors

    public class func appTitleTextColor() -> UIColor {
        //return UIColor(red: 0.58, green: 0.63, blue: 0.71, alpha: 1.0)
        return UIColor(white: 1.0, alpha: 0.6)
    }

    public class func appNavButtonsTextColor() -> UIColor {
        return UIColor(white: 1.0, alpha: 0.6)
    }

    public class func appSectionTitleTextColor() -> UIColor {
        return UIColor.colorWithHex(0x338AFF, alpha:1.0)
    }

    public class func appNavigationBackColor() -> UIColor {
        return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    }

    public func appBgColor() -> UIColor {
        return UIColor(red: 0.007, green: 0.145, blue: 0.329, alpha: 1.0)
    }

    public func appBrightBlueColor() -> UIColor {
        return UIColor(red: 0.2, green: 0.541, blue: 1.0, alpha: 1.0)
    }

    public func appGrayColor() -> UIColor {
        return UIColor(red: 0.325, green: 0.4, blue: 0.521, alpha: 1.0)
    }
    
    //MARK: Nav buttons
    
    public func appNavButtonWithTitle (title: String) -> UIButton {
        let manageButton = UIButton(type: .Custom)
        manageButton.titleLabel?.font = ScreenManager.appFontOfSize(15)
        manageButton.setTitle(title, forState: .Normal)
        manageButton.sizeToFit()
        return manageButton
    }

    //MARK: - fonts

    public func appBrightTextColor() -> UIColor {
        return UIColor.whiteColor()
    }

    public func appUnBrightTextColor() -> UIColor {
        return UIColor.whiteColor().colorWithAlphaComponent(0.4)
    }

    public func appSeparatorColor() -> UIColor {
        return UIColor.lightGrayColor()
    }

    public func appNavBarTextColor() -> UIColor {
        return UIColor.whiteColor().colorWithAlphaComponent(0.6)
    }

    static private let defaulytFontName = "GothamBook"

    public class func appFontOfSize(size: CGFloat) -> UIFont {
        return UIFont(name: defaulytFontName, size: size)!
    }
    
    public class func appScaledFontOfSize(size: CGFloat) -> UIFont {
        return UIFont(name: defaulytFontName, size: size * ScreenManager.scaleFactor)!
    }

    public class func appNavBarFont() -> UIFont {
        return UIFont(name: defaulytFontName, size: 16.0)!
    }

}


