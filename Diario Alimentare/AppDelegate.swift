//
//  AppDelegate.swift
//  Diario Alimentare
//
//  Created by Andrea Bruno on 10/05/2019.
//  Copyright © 2019 Andrea Bruno. All rights reserved.
//

import UIKit
import RealmSwift
import ChameleonFramework

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        
        do {
            let realm = try Realm()
            let emotions = realm.objects(Emotion.self)
            
            if emotions.count < 1 {
                let happyEmotion = Emotion()
                happyEmotion.emoticon = "😁"
                happyEmotion.name = NSLocalizedString("Happy", comment: "Happy emotion description")
                let angryEmotion = Emotion()
                angryEmotion.emoticon = "😡"
                angryEmotion.name = NSLocalizedString("Angry", comment: "Angry emotion description")
                let annoyedEmotion = Emotion()
                annoyedEmotion.emoticon = "😒"
                annoyedEmotion.name = NSLocalizedString("Annoyed", comment: "Annoyed emotion description")
                let sickEmotion = Emotion()
                sickEmotion.emoticon = "🤕"
                sickEmotion.name = NSLocalizedString("Sick", comment: "Sick emotion description")
                let disgustEmotion = Emotion()
                disgustEmotion.emoticon = "🤢"
                disgustEmotion.name = NSLocalizedString("Disgust", comment: "Disgust emotion description")
                try realm.write {
                    realm.add(happyEmotion)
                    realm.add(angryEmotion)
                    realm.add(annoyedEmotion)
                    realm.add(sickEmotion)
                    realm.add(disgustEmotion)
                }
            }
        } catch {
            print("Error initialising \(error)")
        }
        
        Chameleon.setGlobalThemeUsingPrimaryColor(UIColor.flatBlue(), with: UIContentStyle.light)
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

