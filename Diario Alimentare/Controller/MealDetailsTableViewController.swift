//
//  MealDetailsTableViewController.swift
//  Diario Alimentare
//
//  Created by Andrea Bruno on 14/05/2019.
//  Copyright © 2019 Andrea Bruno. All rights reserved.
//

import UIKit
import ChameleonFramework

class MealDetailsTableViewController: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var meal: Meal?
    var emotionForMeal: Emotion?
    var dateOfMeal = Date()
    private var _isUpdate = true

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.isEditing = true
        if let _ = meal?.dishes {
            meal = Meal()
            meal?.when = Date()
            _isUpdate = false
        }
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section {
        case 0: //Meal emotion
            return 1
        case 1: //Meal date
            return 1
        case 2: //Meal content
            guard let dishesForMeal = meal?.dishes else {return 1}
            return dishesForMeal.count + 1
        default:
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
            case 0: //Meal emotion
                let cell = defaultCellForEmotionAndDate(tableView, at: indexPath)
                
                //Input view
                let picker: UIPickerView
                picker = UIPickerView(frame: CGRect(origin: CGPoint(x: 0,y :200), size: CGSize(width: view.frame.width, height: 300)))
                picker.backgroundColor = FlatWhite()
                
                picker.showsSelectionIndicator = true
                picker.delegate = self
                picker.dataSource = self
                
                let toolBar = UIToolbar()
                toolBar.barStyle = .default
                toolBar.isTranslucent = true
                toolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
                toolBar.sizeToFit()
                
                let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(donePicker))
                let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
                let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(donePicker))
                
                toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
                toolBar.isUserInteractionEnabled = true
                
                //
                
                guard let emotionForMeal = meal?.emotionForMeal, let emoticonForMeal = emotionForMeal.first else {
                    return defaultCellValueForEmotionAndDateCell(cell: cell, message: NSLocalizedString("Click to select the emotion", comment: ""))
                }
                if emoticonForMeal.emoticon == "" {
                    return defaultCellValueForEmotionAndDateCell(cell: cell, message: NSLocalizedString("Click to select the emotion", comment: ""))
                }
                cell.textLabel?.text = "\(emoticonForMeal.emoticon) \(emoticonForMeal.name)"
                return cell
            case 1: //Meal date
                let cell = defaultCellForEmotionAndDate(tableView, at: indexPath)
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .long
                dateFormatter.timeStyle = .short
                
                guard let dateOfMeal = meal?.when else {
                    cell.textLabel?.text = dateFormatter.string(from: Date())
                    return cell
                }
                cell.textLabel?.text = dateFormatter.string(from: dateOfMeal)
                
                return cell
            case 2: //Meal content
                let cell = tableView.dequeueReusableCell(withIdentifier: "mealContent", for: indexPath)
                
                guard let dishesForMeal = meal?.dishes else {
                    return configureForAddMeal(cell: cell)
                }
                
                if indexPath.row >= dishesForMeal.count {
                    return configureForAddMeal(cell: cell)
                }
                
                cell.textLabel?.text = dishesForMeal[indexPath.row].name
                
                return cell
            default:
                fatalError()
        }
    }
    
    @objc func donePicker(){
        
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "Test"
    }
    
    func defaultCellValueForEmotionAndDateCell(cell: UITableViewCell, message: String) -> UITableViewCell {
        cell.textLabel?.text = message
        cell.textLabel?.textColor = FlatGray()
        return cell
    }
    
    func defaultCellForEmotionAndDate(_ tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mealEmotionAndDateCell", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        switch indexPath.section {
        case 0: //Meal emotion
            return .none
        case 1: //Meal date
            return .none
        case 2: //Meal content
            guard let dishesForMeal = meal?.dishes else {
                return .insert
            }
            if indexPath.row >= dishesForMeal.count {
                return .insert
            }
            return .delete
        default:
            fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return NSLocalizedString("Meal emotion", comment: "")
        case 1:
            return NSLocalizedString("Add dishes", comment: "")
        case 2:
            return NSLocalizedString("Meal date", comment: "")
        default:
            fatalError()
        }
    }
    
    func configureForAddMeal(cell: UITableViewCell) -> UITableViewCell {
        cell.textLabel?.text = NSLocalizedString("Add dishes", comment: "")
        return cell
    }
    
    @objc func addDishesToDishesTableButtonPressed(){
        
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        switch indexPath.section {
        case 0: //Meal emotion
            return false
        case 1: //Meal date
            return false
        case 2: //Meal content
            return true
        default:
            fatalError()
        }
    }

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
