//
//  AnalysisViewController.swift
//  MetabolicCompass
//
//  Created by Artem Usachov on 8/10/16.
//  Copyright © 2016 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit

// Enums
enum AnalysisType : Int {
    case Correlate = 0
    case Fasting
    case OurStudy
}

class AnalysisViewController: UIViewController {
    
    var currentViewController: UIViewController?
    
    @IBOutlet weak var containerView: UIView!
    
    override func viewDidLoad() {
        let correlateController = UIStoryboard(name: "TabScreens", bundle: nil).instantiateViewControllerWithIdentifier("correlatePlaceholder") as! CorrelationChartsViewController
        self.addChildViewController(correlateController)
        correlateController.view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(correlateController.view, toView: self.containerView)
        self.currentViewController = correlateController;
        super.viewDidLoad()
    }
    
    func switchToScatterPlotViewController() {
        let newViewController = UIStoryboard(name: "TabScreens", bundle: nil).instantiateViewControllerWithIdentifier("correlatePlaceholder") as! CorrelationChartsViewController
        newViewController.view.translatesAutoresizingMaskIntoConstraints = false
        cycleFromViewController(self.currentViewController!, toViewController: newViewController)
        self.currentViewController = newViewController;
    }
    
    func switchToFastingViewController() {
        let fastingViewController = UIStoryboard(name: "TabScreens", bundle: nil).instantiateViewControllerWithIdentifier("fastingController");
        fastingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        cycleFromViewController(self.currentViewController!, toViewController: fastingViewController);
        self.currentViewController = fastingViewController;
    }

    func switchToOurStudyViewController() {
        let ourStudyViewController = UIStoryboard(name: "TabScreens", bundle: nil).instantiateViewControllerWithIdentifier("ourStudyController");
        ourStudyViewController.view.translatesAutoresizingMaskIntoConstraints = false
        cycleFromViewController(self.currentViewController!, toViewController: ourStudyViewController);
        self.currentViewController = ourStudyViewController;
    }

    @IBAction func segmentSelectedAction(segment: UISegmentedControl) {
        switch segment.selectedSegmentIndex {
        case AnalysisType.Correlate.rawValue:
            switchToScatterPlotViewController()
        case AnalysisType.OurStudy.rawValue:
            switchToOurStudyViewController()
        default://by default show fastings
            switchToFastingViewController()
        }
    }
    
    func cycleFromViewController(oldViewController: UIViewController, toViewController newViewController: UIViewController) {
        oldViewController.willMoveToParentViewController(nil)
        oldViewController.view.removeFromSuperview()
        oldViewController.removeFromParentViewController()
        self.addChildViewController(newViewController)
        self.addSubview(newViewController.view, toView:self.containerView!)
        newViewController.view.layoutIfNeeded()
        newViewController.didMoveToParentViewController(self)
    }
    
    func addSubview(subView:UIView, toView parentView:UIView) {
        parentView.addSubview(subView)
        var viewBindingsDict = [String: AnyObject]()
        viewBindingsDict["subView"] = subView
        parentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[subView]|",
            options: [], metrics: nil, views: viewBindingsDict))
        parentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[subView]|",
            options: [], metrics: nil, views: viewBindingsDict))
    }
}
