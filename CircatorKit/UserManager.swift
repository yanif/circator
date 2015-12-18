//
//  UserManager.swift
//  Circator
//
//  Created by Yanif Ahmad on 12/13/15.
//  Copyright © 2015 Yanif Ahmad, Tom Woolf. All rights reserved.
//

import Foundation
import Alamofire
import Locksmith
import Stormpath
import CryptoSwift

private let UserManagerLoginKey = "UMLoginKey"
private let UserManagerHotwordKey = "UMHotwordKey"
private let UserManagerFrequencyKey = "UMFrequencyKey"

public class UserManager {
    public static let sharedManager = UserManager()

    // Defaults.
    public static let defaultRefreshFrequency = 30

    var userId: String?
    var hotWords: String?
    var refreshFrequency: Int? // Aggregate refresh frequency in seconds.

    init() {
        self.setupStormpath()
        self.userId = NSUserDefaults.standardUserDefaults().stringForKey(UserManagerLoginKey)
        self.hotWords = NSUserDefaults.standardUserDefaults().stringForKey(UserManagerHotwordKey)
        let freq = NSUserDefaults.standardUserDefaults().integerForKey(UserManagerFrequencyKey)
        self.refreshFrequency = freq == 0 ? UserManager.defaultRefreshFrequency : freq
        if ( self.hotWords == nil ) {
            self.setHotWords("food log")
        }
    }

    // Mark: - Authentication
    public func setupStormpath() {
        Stormpath.setUpWithURL(MCRouter.baseURLString)
        if Stormpath.accessToken == nil {
            print("Logging into Stormpath...")
            self.login()
        }

        if let token = Stormpath.accessToken {
            MCRouter.OAuthToken = Stormpath.accessToken
            print("User token: \(token)")
        } else {
            // TODO: start login screen here.
            print("Login failed, please do so manually.")
        }
    }

    public func getUserId() -> String? {
        return self.userId
    }

    public func getUserIdHash() -> String? {
        return self.userId?.md5()
    }

    public func setUserId(userId: String) {
        self.userId = userId
        NSUserDefaults.standardUserDefaults().setValue(self.userId, forKey: UserManagerLoginKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    public func resetUserId() {
        self.userId = nil
        NSUserDefaults.standardUserDefaults().removeObjectForKey(UserManagerLoginKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    public func getAccountData() -> [String:AnyObject]? {
        if let user = userId {
            let account = UserAccount(username: user, password: "")
            let lockbox = account.readFromSecureStore()
            return lockbox?.data
        }
        return nil
    }

    public func getPassword() -> String? {
        if let data = getAccountData() {
            if let pass = data["password"] {
                return pass as? String
            }
        }
        return nil
    }

    public func getAccessToken() -> String? {
        return Stormpath.accessToken
    }

    public func setAccountData(items: [String:AnyObject]) {
        if let user = userId {
            if var datadict = Locksmith.loadDataForUserAccount(user) {
                for (k,v) in items { datadict[k] = v }
                do {
                    try Locksmith.updateData(datadict, forUserAccount: user)
                } catch {
                    debugPrint(error)
                }
            }
        }
    }
    
    public func setPassword(userPass: String) {
        createAccount(userPass)
    }
    
    public func hasAccount() -> Bool {
        if let user = userId {
            let account = UserAccount(username: user, password: "")
            return account.readFromSecureStore() != nil
        }
        return false
    }

    func createAccount(userId: String, userPass: String) {
        let account = UserAccount(username: userId, password: userPass)
        do {
            try account.createInSecureStore()
        } catch {
            debugPrint(error)
        }
    }

    func createAccount(userPass: String) {
        if let user = userId {
            let account = UserAccount(username: user, password: userPass)
            do {
                try account.createInSecureStore()
            } catch {
                debugPrint(error)
            }
        }
    }

    func validateAccount(userPass: String) -> Bool {
        if let pass = getPassword() {
            return pass == userPass
        }
        return false
    }
    
    func resetAccount() {
        if let user = userId {
            let account = UserAccount(username: user, password: "")
            do {
                try account.deleteFromSecureStore()
            } catch {
                debugPrint(error)
            }
        }
    }

    public func login() {
        if let user = userId, pass = getPassword() {
            Stormpath.login(username: user, password: pass, completionHandler: {
                (accessToken, err) -> Void in
                guard err == nil else {
                    debugPrint(err)
                    return
                }
                MCRouter.OAuthToken = Stormpath.accessToken
                print("Access token: \(Stormpath.accessToken)")
                Alamofire.request(MCRouter.UserToken([:])).responseString {_, response, result in
                    print("POST: " + (result.isSuccess ? "SUCCESS" : "FAILED"))
                    print(result.value)
                }
            })
        }
    }

    public func login(userPass: String) {
        if let user = userId {
            if !validateAccount(userPass) { createAccount(user, userPass: userPass) }
            login()
        }
    }

    public func logout() {
        Stormpath.logout(completionHandler: { (error) -> Void in
            if error == nil { return }
            else { print("Error logging out of Stormpath") }
        })
        MCRouter.OAuthToken = nil
        resetAccount()
        resetUserId()
    }

    // Mark : - Configuration

    public func getHotWords() -> String? {
        return self.hotWords
    }

    public func setHotWords(hotWords: String) {
        self.hotWords = hotWords
        NSUserDefaults.standardUserDefaults().setValue(self.hotWords, forKey: UserManagerHotwordKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    public func getRefreshFrequency() -> Int? {
        return self.refreshFrequency
    }

    public func setRefreshFrequency(frequency: Int) {
        self.refreshFrequency = frequency
        NSUserDefaults.standardUserDefaults().setValue(self.refreshFrequency, forKey: UserManagerFrequencyKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

}