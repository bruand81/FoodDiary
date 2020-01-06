//
//  MeasureUnit.swift
//  Diario Alimentare
//
//  Created by Andrea Bruno on 03/01/2020.
//  Copyright © 2020 Andrea Bruno. All rights reserved.
//

import Foundation
import RealmSwift

class MeasureUnit: Object {
    @objc dynamic var _id = UUID().uuidString
    @objc dynamic var name: String = ""
    let dishes = List<Dish>()
    
    override static func primaryKey() -> String? {
        return "_id"
    }
}
