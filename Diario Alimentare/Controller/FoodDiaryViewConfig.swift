//
//  FoodDiaryViewConfig.swift
//  Diario Alimentare
//
//  Created by Andrea Bruno on 29/11/2019.
//  Copyright © 2019 Andrea Bruno. All rights reserved.
//

import Foundation
import UIKit

class FoodDiaryViewConfig: UIViewController {
    func initController() {
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            navBarAppearance.backgroundColor = UIColor.flatBlue()
            navigationController?.navigationBar.standardAppearance = navBarAppearance
            navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        }
    }
    
}
