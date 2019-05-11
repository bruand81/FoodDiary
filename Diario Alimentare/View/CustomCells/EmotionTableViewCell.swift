//
//  EmotionTableViewCell.swift
//  Diario Alimentare
//
//  Created by Andrea Bruno on 11/05/2019.
//  Copyright © 2019 Andrea Bruno. All rights reserved.
//

import UIKit
import SwipeCellKit

class EmotionTableViewCell: SwipeTableViewCell {
    @IBOutlet weak var EmoticonLabel: UILabel!
    @IBOutlet weak var EmotionDescriptionName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//
//        // Configure the view for the selected state
//    }
    
}
