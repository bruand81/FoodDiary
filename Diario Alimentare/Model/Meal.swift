//
//  Meal.swift
//  Diario Alimentare
//
//  Created by Andrea Bruno on 10/05/2019.
//  Copyright © 2019 Andrea Bruno. All rights reserved.
//

import Foundation
import RealmSwift

class Meal: Object {
    @objc dynamic var mealID = UUID().uuidString
    @objc dynamic var what: String = ""
    @objc dynamic var when: Date = Date()
    var emotionForMeal = LinkingObjects<Emotion>(fromType: Emotion.self, property: "meals")
    
    override static func primaryKey() -> String? {
        return "mealID"
    }
}
