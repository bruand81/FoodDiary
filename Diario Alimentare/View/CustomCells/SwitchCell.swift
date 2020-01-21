//
//  SwitchCell.swift
//  Diario Alimentare
//
//  Created by Andrea Bruno on 21/01/2020.
//  Copyright © 2020 Andrea Bruno. All rights reserved.
//

import UIKit

protocol SwitchCellDelegate: AnyObject {
    func switchChanged(_ sender: UISwitch)
}

class SwitchCell: UITableViewCell {
    weak var delegate: SwitchCellDelegate?
    @IBOutlet weak var labelForSwitch: UILabel!
    @IBOutlet weak var cellSwitch: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        delegate?.switchChanged(sender)
    }
}
