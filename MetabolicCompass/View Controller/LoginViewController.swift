//
//  LoginViewController.swift
//  MetabolicCompass
//
//  Created by Yanif Ahmad on 12/17/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import UIKit
import MetabolicCompassKit
import Async
import Former
import Crashlytics
import Dodo

private let btnFontSize = ScreenManager.sharedInstance.loginButtonFontSize()
private let lblFontSize = ScreenManager.sharedInstance.loginLabelFontSize()
private let inputFontSize = ScreenManager.sharedInstance.loginInputFontSize()

/**
 Controls the Login screens for the App.
 
- note: for both signup and login; uses Stormpath for authentication
 */
class LoginViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    private var userCell: FormTextFieldCell?
    private var passCell: FormTextFieldCell?
    var parentView: IntroViewController?
    var completion: (Void -> Void)?

    lazy var logoImageView: UIImageView = {
        let img = UIImageView(frame: CGRectMake(0,0,100,100))
        img.image = UIImage(named: "image-logo")
        img.autoresizingMask = UIViewAutoresizing.FlexibleBottomMargin
        img.clipsToBounds = true
        img.contentMode = UIViewContentMode.ScaleAspectFit
        img.contentScaleFactor = 2.0
        return img
    }()

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRectMake(0, 0, 1000, 1000), style: UITableViewStyle.Plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "loginCell")
        tableView.backgroundColor = UIColor.clearColor()
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = false
        tableView.scrollEnabled = false
        return tableView
    }()

    lazy var loginLabelButton : UIButton = {
        let button = UIButton(type: .Custom)
        button.setTitle("Login", forState: .Normal)
        button.addTarget(self, action: "doLogin:", forControlEvents: .TouchUpInside)
        button.titleLabel?.font = UIFont.systemFontOfSize(btnFontSize, weight: UIFontWeightSemibold)
        button.setTitleColor(Theme.universityDarkTheme.titleTextColor, forState: .Normal)
        button.backgroundColor = Theme.universityDarkTheme.backgroundColor
        return button
    }()

    lazy var signupLabelButton : UIButton = {
        let button = UIButton(type: .Custom)
        button.setTitle("Signup", forState: .Normal)
        button.addTarget(self, action: "doSignup:", forControlEvents: .TouchUpInside)
        button.titleLabel?.font = UIFont.systemFontOfSize(btnFontSize, weight: UIFontWeightSemibold)
        button.setTitleColor(Theme.universityDarkTheme.titleTextColor, forState: .Normal)
        button.backgroundColor = Theme.universityDarkTheme.backgroundColor
        return button
    }()

    lazy var loginContainerView: UIStackView = {
        let stackView: UIStackView = UIStackView(arrangedSubviews:
                            [self.loginLabelButton, self.signupLabelButton])
        stackView.axis = .Horizontal
        stackView.distribution = UIStackViewDistribution.FillEqually
        stackView.alignment = UIStackViewAlignment.Fill
        stackView.spacing = 20
        return stackView
    }()

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        tableView.reloadData()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        UIDevice.currentDevice().setValue(UIInterfaceOrientation.Portrait.rawValue, forKey: "orientation")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        tableView.layoutIfNeeded()
    }

    private func configureViews() {
        view.backgroundColor = Theme.universityDarkTheme.backgroundColor

        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        loginContainerView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(logoImageView)
        view.addSubview(tableView)
        view.addSubview(loginContainerView)

        let constraints: [NSLayoutConstraint] = [
            logoImageView.topAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.topAnchor, constant: 110),
            logoImageView.centerXAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.centerXAnchor),
            logoImageView.widthAnchor.constraintEqualToConstant(100),
            logoImageView.heightAnchor.constraintEqualToConstant(100),
            tableView.topAnchor.constraintEqualToAnchor(logoImageView.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.leadingAnchor, constant: 5),
            tableView.trailingAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.trailingAnchor, constant: -5),
            tableView.bottomAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.bottomAnchor, constant: -30),

            loginContainerView.topAnchor.constraintEqualToAnchor(logoImageView.bottomAnchor, constant: 110),
            loginContainerView.centerXAnchor.constraintEqualToAnchor(tableView.centerXAnchor),
            loginContainerView.widthAnchor.constraintEqualToAnchor(view.layoutMarginsGuide.widthAnchor, multiplier: 0.8),
            loginContainerView.heightAnchor.constraintEqualToConstant(44)
        ]

        view.addConstraints(constraints)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: self.view.frame.width, bottom: 0, right: 0)
    }

    func doLogin(sender: UIButton) {
        UserManager.sharedManager.ensureUserPass(userCell?.textField.text, pass: passCell?.textField.text) {
            error in
            guard !error else {
                UINotifications.invalidUserPass(self.navigationController!)
                return
            }
            UserManager.sharedManager.loginWithPull { (error, _) in
                guard !error else {
                    Answers.logLoginWithMethod("SPL", success: false, customAttributes: nil)

                    UINotifications.invalidUserPass(self.navigationController!)
                    return
                }
                if let comp = self.completion { comp() }
                UINotifications.doWelcome(self.parentView!, pop: true, user: UserManager.sharedManager.getUserId() ?? "")
                Async.main {
                    Answers.logLoginWithMethod("SPL", success: true, customAttributes: nil)
                    self.parentView?.initializeBackgroundWork()
                }
            }
        }
    }

    func doSignup(sender: UIButton) {
        let registerVC = RegisterViewController()
        registerVC.parentView = parentView
        registerVC.consentOnLoad = true
        self.navigationController?.pushViewController(registerVC, animated: true)
    }

    // MARK: - Table View

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44.0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("loginCell", forIndexPath: indexPath)

        switch indexPath.section {
        case 0:
            if (indexPath.row == 0 && userCell == nil) || (indexPath.row == 1 && passCell == nil) {
                let formCell = FormTextFieldCell()
                let cellInput = formCell.formTextField()
                let cellLabel = formCell.formTitleLabel()

                cellInput.font = UIFont.systemFontOfSize(inputFontSize)
                cellLabel?.font = UIFont.systemFontOfSize(lblFontSize)

                cell.backgroundColor = Theme.universityDarkTheme.backgroundColor
                cellInput.textColor = Theme.universityDarkTheme.titleTextColor
                cellInput.backgroundColor = Theme.universityDarkTheme.backgroundColor
                cellLabel?.textColor = Theme.universityDarkTheme.titleTextColor
                cellLabel?.backgroundColor = Theme.universityDarkTheme.backgroundColor

                cellInput.textAlignment = NSTextAlignment.Right
                cellInput.autocorrectionType = UITextAutocorrectionType.No // no auto correction support
                cellInput.autocapitalizationType = UITextAutocapitalizationType.None // no auto capitalization support

                if (indexPath.row == 0) {
                    cellInput.keyboardType = UIKeyboardType.EmailAddress
                    cellInput.returnKeyType = UIReturnKeyType.Next
                    cellInput.attributedPlaceholder = NSAttributedString(string:"example@gmail.com",
                        attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor()])
                    cellInput.text = UserManager.sharedManager.getUserId()
                    cellLabel?.text = "User"
                    userCell = formCell
                    cellInput.tag = 0
                }
                else {
                    cellInput.keyboardType = UIKeyboardType.Default
                    cellInput.returnKeyType = UIReturnKeyType.Done
                    cellInput.secureTextEntry = true
                    cellInput.attributedPlaceholder = NSAttributedString(string:"Required",
                        attributes:[NSForegroundColorAttributeName: UIColor.lightGrayColor()])
                    cellInput.text = UserManager.sharedManager.getPassword()
                    cellLabel?.text = "Password"
                    passCell = formCell
                    cellInput.tag = 1
                }

                formCell.translatesAutoresizingMaskIntoConstraints = false
                cell.contentView.addSubview(formCell)

                let constraints: [NSLayoutConstraint] = [
                    formCell.topAnchor.constraintEqualToAnchor(cell.contentView.topAnchor),
                    formCell.leadingAnchor.constraintEqualToAnchor(cell.contentView.layoutMarginsGuide.leadingAnchor),
                    formCell.trailingAnchor.constraintEqualToAnchor(cell.contentView.layoutMarginsGuide.trailingAnchor, constant: -(ScreenManager.sharedInstance.settingsCellTrailing())),
                    formCell.heightAnchor.constraintEqualToAnchor(cell.contentView.heightAnchor)
                ]
                cell.contentView.addConstraints(constraints)

                cellInput.enabled = true
                cellInput.delegate = self
            }

        default:
            log.error("Invalid settings tableview section")
        }

        return cell
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let txt = textField.text {
            switch textField.tag {
            case 0:
                userCell?.textField.resignFirstResponder()
                passCell?.textField.becomeFirstResponder()
                UserManager.sharedManager.setUserId(txt)

            case 1:
                passCell?.textField.resignFirstResponder()
                userCell?.textField.becomeFirstResponder()

                // Take the current username text as well as the password.
                UserManager.sharedManager.ensureUserPass(userCell?.textField.text, pass: txt) { error in
                    guard !error else {
                        UINotifications.invalidUserPass(self.navigationController!)
                        return
                    }
                }
            default:
                return false
            }
        }
        return false
    }
}