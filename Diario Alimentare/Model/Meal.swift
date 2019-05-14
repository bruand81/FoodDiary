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
    @objc dynamic private var _mealID = UUID().uuidString
    @objc dynamic var name: String = ""
    @objc dynamic var when: Date = Date()
    var emotionForMeal = LinkingObjects<Emotion>(fromType: Emotion.self, property: "meals")
    let dishes = List<Dish>()
    
    override static func primaryKey() -> String? {
        return "_mealID"
    }
}
