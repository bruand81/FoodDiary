//
//  Emotion.swift
//  Diario Alimentare
//
//  Created by Andrea Bruno on 10/05/2019.
//  Copyright © 2019 Andrea Bruno. All rights reserved.
//

import Foundation
import RealmSwift

class Emotion: Object {
    @objc dynamic private var _id: String = UUID().uuidString
    @objc dynamic var name: String = ""
    @objc dynamic var emoticon: String = ""
    
    let meals = List<Meal>()
    
    override static func primaryKey() -> String? {
        return "_id"
    }
}
