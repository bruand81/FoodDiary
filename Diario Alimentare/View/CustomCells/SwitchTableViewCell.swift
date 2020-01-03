//
//  SwitchTableViewCell.swift
//  Diario Alimentare
//
//  Created by Andrea Bruno on 21/05/2019.
//  Copyright © 2019 Andrea Bruno. All rights reserved.
//

import UIKit

protocol SwitchTableViewCellDelegate {
    func valueChanged(withCurrentValue value:Bool)
}

class SwitchTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cellSwitch: UISwitch!
    var delegate: SwitchTableViewCellDelegate?
    private var isOn: Bool = true
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setSwitchOn(value: Bool) {
        cellSwitch.setOn(value, animated: true)
    }
    
    @IBAction func switchValueChanged(_ sender: Any) {
        guard let switchDelegate = delegate else {return}
       
        switchDelegate.valueChanged(withCurrentValue: cellSwitch.isOn)
    }
    
}
