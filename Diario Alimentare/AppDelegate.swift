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
            let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 2,

            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < 1) {
                    migration.enumerateObjects(ofType: Dish.className()) { (oldObject, newObject) in
                        newObject!["quantity"] = -1
                    }
                }
            })
            
            Realm.Configuration.defaultConfiguration = config
            
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
            
            let measureUnits = realm.objects(MeasureUnit.self)
            
            if measureUnits.count < 1 {
                let nn = MeasureUnit()
                nn.name = NSLocalizedString("NN", comment: "Measure unit not needed")
                let ml = MeasureUnit()
                ml.name = NSLocalizedString("ml", comment: "Measure unit milliliters")
                let pz = MeasureUnit()
                pz.name = NSLocalizedString("pz", comment: "Measure unit pieces")
                let gr = MeasureUnit()
                gr.name = NSLocalizedString("gr", comment: "Measure unit grams")
                try realm.write {
                    realm.add(nn)
                    realm.add(ml)
                    realm.add(pz)
                    realm.add(gr)
                }
            }
            
            let predicate = NSPredicate(format: "name = %@", "NN")
            let nnmu = realm.objects(MeasureUnit.self).filter(predicate).first
            //print(nnmu ?? "Not present")
            let dishes = realm.objects(Dish.self)
            
            if dishes.count > 0 {
                for dish in dishes {
                    print(dish)
                    if dish.measureUnitForDishes.count < 1 {
                        try realm.write {
                            nnmu?.dishes.append(dish)
                        }
                    }
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

