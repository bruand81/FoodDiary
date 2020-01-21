//
//  ToolbarCell.swift
//  Diario Alimentare
//
//  Created by Andrea Bruno on 21/01/2020.
//  Copyright © 2020 Andrea Bruno. All rights reserved.
//

import UIKit

protocol ToolbarCellDelegate: AnyObject {
    func doneButtonPressed(_ sender:UIButton)
}

class ToolbarCell: UITableViewCell {
    @IBOutlet weak var flexibleSpaceLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    
    weak var delegate:ToolbarCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        doneButton.setTitle(NSLocalizedString("Done", comment: ""), for: .normal)
    }
    
    @IBAction func doneButtonPressed(_ sender: UIButton) {
//        print("Pressed done button")
        delegate?.doneButtonPressed(sender)
    }
}
