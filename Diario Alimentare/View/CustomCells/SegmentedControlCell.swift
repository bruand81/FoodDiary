//
//  SwitchCell.swift
//  Diario Alimentare
//
//  Created by Andrea Bruno on 20/01/2020.
//  Copyright © 2020 Andrea Bruno. All rights reserved.
//

import UIKit

protocol SegmentedControlDelegate: AnyObject {
    func exportFormatValueChanged(_ sender: UISegmentedControl)
}


class SegmentedControlCell: UITableViewCell {
    @IBOutlet weak var labelForSwitch: UILabel!
    @IBOutlet weak var formatSegmentedControl: UISegmentedControl!
    
    weak var delegate:SegmentedControlDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
//        cellOption.addTarget(self, action: #selector(switchChanged), for: UIControl.Event.valueChanged)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        labelForSwitch.sizeToFit()
    }
    
    @IBAction func formatSegmentedControlValueChanged(_ sender: UISegmentedControl) {
        delegate?.exportFormatValueChanged(sender)
    }
    
//    @objc func switchChanged(mySwitch: UISwitch) {
//        delegate?.switchChanged(sender: mySwitch)
//    }
}
