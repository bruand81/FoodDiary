//
//  Dish.swift
//  Diario Alimentare
//
//  Created by Andrea Bruno on 14/05/2019.
//  Copyright © 2019 Andrea Bruno. All rights reserved.
//

import Foundation
import RealmSwift

class Dish: Object {
    @objc dynamic private var _id: String = UUID().uuidString
    @objc dynamic var name = ""
    var mealForDish = LinkingObjects<Meal>(fromType: Meal.self, property: "dishes")
    
    override static func primaryKey() -> String? {
        return "_id"
    }
}
