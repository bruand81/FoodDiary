//
//  DatePickerViewCellWithToolbar.swift
//  Diario Alimentare
//
//  Created by Andrea Bruno on 17/05/2019.
//  Copyright © 2019 Andrea Bruno. All rights reserved.
//

import Foundation
import PickerViewCell

class DatePickerViewCellWithToolbar: DatePickerTableViewCell {
    var toolbar: UIToolbar?
    
    open override var inputAccessoryView: UIView? {
        return toolbar
    }
}
