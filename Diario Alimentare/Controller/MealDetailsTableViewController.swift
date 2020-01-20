//
//  MealDetailsTableViewController.swift
//  Diario Alimentare
//
//  Created by Andrea Bruno on 14/05/2019.
//  Copyright © 2019 Andrea Bruno. All rights reserved.
//

import UIKit
//import ChameleonFramework
import PickerViewCell
import RealmSwift

enum SectionOfMealDetails: Int {
    case mealName = 0
    case mealEmotion = 1
    case mealDate = 2
    case mealContent = 3
}

protocol MealDetailDelegate {
    func updatedMealDetails()
}

class MealDetailsTableViewController: UITableViewController {

    @IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var doneBarButtonItem: UIBarButtonItem!
    var meal: Meal?
    var emotionForMeal: Emotion?
    var dateOfMeal = Date()
    let realm = try! Realm()
    var indexPathForDate: IndexPath?
    var indexPathForEmotion: IndexPath?
    var duplicateExitBarrier: Bool = false
    var duplicateDatePickerExitBarrier: Bool = false
    var delegate: MealDetailDelegate?
    var measureUnitPicker: UIPickerView = UIPickerView()
    let toolBar = UIToolbar()
    var measureUnitTextField = UITextField()
    var measureUnitSelected: MeasureUnit?
    
    lazy var emotions: Results<Emotion> = realm.objects(Emotion.self).sorted(byKeyPath: "name", ascending: true)
    lazy var measureUnits: Results<MeasureUnit> = realm.objects(MeasureUnit.self).sorted(byKeyPath: "name", ascending: true)
    private var _isUpdate = true
    
    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.long
        formatter.timeStyle = DateFormatter.Style.short
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.isEditing = true
        guard let _ = meal?.dishes else {
            meal = Meal()
            meal?.when = Date()
            _isUpdate = false
            return
        }
        
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        
        if #available(iOS 13.0, *) {
            doneBarButtonItem.image = UIImage(systemName: "checkmark")
            cancelBarButtonItem.image = UIImage(systemName: "chevron.left")
        }
        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section {
        case SectionOfMealDetails.mealName.rawValue: //Meal name
            return 1
        case SectionOfMealDetails.mealEmotion.rawValue: //Meal emotion
            return 1
        case SectionOfMealDetails.mealDate.rawValue: //Meal date
            return 1
        case SectionOfMealDetails.mealContent.rawValue: //Meal content
            guard let dishesForMeal = meal?.dishes else {return 1}
            return dishesForMeal.count + 1
        default:
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
            case SectionOfMealDetails.mealName.rawValue: //Meal name
                let cell = tableView.dequeueReusableCell(withIdentifier: "mealNameCell", for: indexPath)
                guard let nameForMeal = meal?.name else {
                    cell.textLabel?.text = NSLocalizedString("Set meal name", comment: "")
                    //cell.textLabel?.textColor = FlatGray()
                    cell.textLabel?.textColor = UIColor.lightGray
                    return cell
                }
                cell.textLabel?.text = nameForMeal
                return cell
            case SectionOfMealDetails.mealEmotion.rawValue: //Meal emotion
                let cell = tableView.dequeueReusableCell(withIdentifier: "emotionOfMealCell", for: indexPath)
                indexPathForEmotion = indexPath
                
                guard let emotionForMeal = meal?.emotionForMeal, let emoticonForMeal = emotionForMeal.first else {
                    return defaultCellValueForEmotionCell(cell: cell, message: NSLocalizedString("Click to select the emotion", comment: ""))
                }
                if emoticonForMeal.emoticon == "" {
                    return defaultCellValueForEmotionCell(cell: cell, message: NSLocalizedString("Click to select the emotion", comment: ""))
                }
                cell.textLabel?.text = "\(emoticonForMeal.emoticon) \(emoticonForMeal.name)"
                
                return cell
            case SectionOfMealDetails.mealDate.rawValue: //Meal date
                let cell = tableView.dequeueReusableCell(withIdentifier: "mealDateCell", for: indexPath)
                indexPathForDate = indexPath
                
                guard let dateOfMeal = meal?.when else {
                    cell.textLabel?.text = dateFormatter.string(from: Date())
                    return cell
                }
                cell.textLabel?.text = dateFormatter.string(from: dateOfMeal)
                
                return cell
            case SectionOfMealDetails.mealContent.rawValue: //Meal content
                let cell = tableView.dequeueReusableCell(withIdentifier: "mealContentCell", for: indexPath)
                
                guard let dishesForMeal = meal?.dishes else {
                    return configureForAddMeal(cell: cell)
                }
                
                if indexPath.row >= dishesForMeal.count {
                    return configureForAddMeal(cell: cell)
                }
                
                let dish = dishesForMeal[indexPath.row]
                
                var dishQuantity = ""
                
                if dish.quantity > 0 {
                    dishQuantity = " (\(dish.quantity) \(dish.measureUnitForDishes.first?.name ?? "NN"))"
                }
                let dishName = "\(dish.name)\(dishQuantity)"
                cell.textLabel?.text = dishName
                
                return cell
            default:
                fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let cell = tableView.cellForRow(at: indexPath) as? DatePickerTableViewCell {
            cell.delegate = self
            cell.picker.datePickerMode = .dateAndTime
            
            if !cell.isFirstResponder {
                _ = cell.becomeFirstResponder()
            }
        } else if let cell = tableView.cellForRow(at: indexPath) as? PickerTableViewCell {
            cell.delegate = self
            cell.dataSource = self
            
            if !cell.isFirstResponder {
                _ = cell.becomeFirstResponder()
            }
        } else if indexPath.section == SectionOfMealDetails.mealName.rawValue {
            var textField = UITextField()
            
            let alert = UIAlertController(title: NSLocalizedString("Insert meal name", comment: ""), message: "Insert the a name of this meal (e.g. Launch, Dinner, etc...)", preferredStyle: .alert)
            
            let action = UIAlertAction(title: NSLocalizedString("Add name", comment: ""), style: .default) { (action) in
                //What will happen when the user clicks the Add Button on our UIAlert
                if let insertName = textField.text {
                    do {
                        try self.realm.write {
                            self.meal?.name = insertName
                        }
                    } catch {
                        print("Error adding name \(error)")
                    }
                    
                    self.tableView.reloadData()
                }
            }
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
            
            alert.addTextField { (alertTextField) in
                guard let currentMeal = self.meal else {
                    alertTextField.placeholder = NSLocalizedString("Meal name", comment: "")
                    textField = alertTextField
                    return
                }
                
                if currentMeal.name == ""{
                    alertTextField.placeholder = NSLocalizedString("Meal name", comment: "")
                } else {
                    alertTextField.text = currentMeal.name
                }
                alertTextField.autocapitalizationType = .sentences
                alertTextField.autocorrectionType = .default
                textField = alertTextField
            }
            
            alert.addAction(action)
            alert.addAction(cancelAction)
            
            present(alert, animated: true, completion: nil)
        } else if indexPath.section == SectionOfMealDetails.mealContent.rawValue {
            guard tableView.cellForRow(at: indexPath) != nil else {return}
            if indexPath.row >= meal!.dishes.count || meal!.dishes.count == 0{
                addOrEditDish(indexPath: nil)
            } else {
                addOrEditDish(indexPath: indexPath)
            }
        } else if let cell = tableView.cellForRow(at: indexPath) {
            if !cell.isFirstResponder {
                _ = cell.becomeFirstResponder()
            }
        }
    }
    
    func addOrEditDish(indexPath idx: IndexPath?) {
        var dishNameTextField = UITextField()
        var quantityTextField = UITextField()
        var dish = Dish()
        var alertTitle = ""
        var actionButtonTitle = ""
        
        if let indexPath = idx {
            dish = meal!.dishes[indexPath.row]
            measureUnitSelected = dish.measureUnitForDishes.first
            alertTitle = "Modify new dish"
            actionButtonTitle = "Modify Dish"
        } else {
            dish.name = ""
            dish.quantity = -1
            alertTitle = "Add new dish"
            actionButtonTitle = "Add Dish"
        }
        measureUnitSelected = dish.measureUnitForDishes.first ?? measureUnits.filter(NSPredicate(format: "name = %@", "NN")).first
                
        let alert = UIAlertController(title: NSLocalizedString(alertTitle, comment: ""), message: NSLocalizedString("Modify the selected dishes for this meal", comment: ""), preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
        
        
        let action = UIAlertAction(title: NSLocalizedString(actionButtonTitle, comment: ""), style: .default) { (action) in
            //What will happen when the user clicks the Add Button on our UIAlert
            if let addDishText = dishNameTextField.text {
                let quantity = Double(quantityTextField.text ?? "-1") ?? -1

                if let indexPath = idx {
                    do {
                        try self.realm.write {
                            self.meal!.dishes[indexPath.row].name = addDishText
                            self.meal!.dishes[indexPath.row].quantity = quantity
                            for mu in self.meal!.dishes[indexPath.row].measureUnitForDishes {
                                if let index = mu.dishes.firstIndex(of: self.meal!.dishes[indexPath.row]){
                                    mu.dishes.remove(at: index)
                                }
                            }
                            self.measureUnitSelected?.dishes.append(self.meal!.dishes[indexPath.row])
                        }
                    } catch {
                        print("Error updating new dish \(error)")
                    }
                } else {
                    dish.name = addDishText
                    dish.quantity = quantity
                    
                    do {
                        try self.realm.write {
                            self.meal?.dishes.append(dish)
                            self.measureUnitSelected?.dishes.append(dish)
                        }
                    } catch {
                        print("Error adding new dish \(error)")
                    }
                }
                
                self.tableView.reloadData()
            }
        }
        
        alert.addTextField { (alertTextField) in
            if idx != nil {
                alertTextField.text = dish.name
            } else {
                alertTextField.placeholder = NSLocalizedString("Dish name", comment: "")
            }
            alertTextField.autocapitalizationType = .sentences
            alertTextField.autocorrectionType = .default
            dishNameTextField = alertTextField
        }
        
        alert.addTextField { (alertTextField) in
            if idx != nil {
                alertTextField.text = "\(dish.quantity)"
            } else {
                alertTextField.placeholder =  NSLocalizedString("Dish quantity eaten", comment: "")
            }
            alertTextField.keyboardType = .decimalPad
            quantityTextField = alertTextField
        }
        
        alert.addTextField { (alertTextField) in
            if idx != nil {
                alertTextField.text = self.measureUnitSelected?.name
            } else {
                alertTextField.placeholder = NSLocalizedString("Dish quantity measure unit", comment: "")
            }
            self.doMeasureUnitPicker()
            alertTextField.inputView = self.measureUnitPicker
            alertTextField.inputAccessoryView = self.toolBar
            self.measureUnitTextField = alertTextField
        }
        
        alert.addAction(action)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    

    
    @objc func dismissPicker() {
        
        view.endEditing(true)
        
    }
    
    func defaultCellValueForEmotionCell(cell: UITableViewCell, message: String) -> UITableViewCell {
        cell.textLabel?.text = message
        //cell.textLabel?.textColor = FlatGray()
        cell.textLabel?.textColor = UIColor.lightText
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        switch indexPath.section {
        case SectionOfMealDetails.mealContent.rawValue: //Meal content
            guard let dishesForMeal = meal?.dishes else {
                return .insert
            }
            if indexPath.row >= dishesForMeal.count {
                return .insert
            }
            return .delete
        default:
            return .none
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case SectionOfMealDetails.mealName.rawValue:
            return NSLocalizedString("Meal name", comment: "")
        case SectionOfMealDetails.mealEmotion.rawValue:
            return NSLocalizedString("Meal emotion", comment: "")
        case SectionOfMealDetails.mealContent.rawValue:
            return NSLocalizedString("Add dishes", comment: "")
        case SectionOfMealDetails.mealDate.rawValue:
            return NSLocalizedString("Meal date", comment: "")
        default:
            fatalError()
        }
    }
    
    func configureForAddMeal(cell: UITableViewCell) -> UITableViewCell {
        cell.textLabel?.text = NSLocalizedString("Add dishes", comment: "")
        cell.textLabel?.textColor = UIColor.lightGray
        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        switch indexPath.section {
        case SectionOfMealDetails.mealContent.rawValue: //Meal content
            return true
        default:
            return false
        }
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            do{
                try realm.write {
                    meal?.dishes.remove(at: indexPath.row)
                }
            } catch {
                print("Error deleting dish \(error)")
            }
            tableView.reloadData()
        } else if editingStyle == .insert {
            addOrEditDish(indexPath: nil)
        }
    }



    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        if !_isUpdate {
            if let mealsToDelete = realm.objects(Meal.self).filter("_id=%@",meal?._id ?? "").first {
                do {
                    try realm.write {
                        realm.delete(mealsToDelete.dishes)
                        realm.delete(mealsToDelete)
                    }
                } catch {
                    print("Error deleting item")
                }
                
            }
        }
        
        delegate?.updatedMealDetails()
        self.navigationController?.popViewController(animated: true)
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
        delegate?.updatedMealDetails()
        self.navigationController?.popViewController(animated: true)
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func goToMeasureUnitButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "goToMeasureUnit", sender: self)
    }
    
    // MARK: - Measure Unit Picker utility methods
    func doMeasureUnitPicker(){
        self.measureUnitPicker = UIPickerView(frame:CGRect(x: 0, y: self.view.frame.size.height - 220, width:self.view.frame.size.width, height: 216))
        //self.measureUnitPicker.backgroundColor = UIColor.white
        self.measureUnitPicker.dataSource = self
        self.measureUnitPicker.delegate = self
        if let mu = measureUnitSelected {
            self.measureUnitPicker.selectRow(measureUnits.index(of: mu) ?? 0, inComponent: 0, animated: true)
            self.measureUnitTextField.text = mu.name
        }
        
        toolBar.barStyle = .default
        toolBar.isTranslucent = true
        toolBar.sizeToFit()
        
        // Adding Button ToolBar
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(MealDetailsTableViewController.doneClick))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(MealDetailsTableViewController.cancelClick))
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: true)
        toolBar.isUserInteractionEnabled = true

        self.toolBar.isHidden = false
    }
    
    @objc func doneClick() {
        measureUnitPicker.isHidden = true
        self.toolBar.isHidden = true
    }
    
    @objc func cancelClick() {
        measureUnitPicker   .isHidden = true
        self.toolBar.isHidden = true
    }
    
}

// MARK: - DatePickerTableCellDelegate
extension MealDetailsTableViewController : DatePickerTableCellDelegate{
    func onDatePickerOpen(_ cell: DatePickerTableViewCell) {
        guard let dateCell = tableView.cellForRow(at: indexPathForDate!) else {return}
        duplicateDatePickerExitBarrier = false
        cell.picker.date = dateFormatter.date(from: dateCell.textLabel!.text!) ?? Date()
        //cell.textLabel?.textColor = FlatRedDark()
        cell.textLabel?.textColor = UIColor.red
    }
    
    func onDatePickerClose(_ cell: DatePickerTableViewCell) {
        if duplicateDatePickerExitBarrier {
            return
        }
        guard let dateCell = tableView.cellForRow(at: indexPathForDate!), let newDate = dateFormatter.date(from: dateCell.textLabel!.text!) else {return}
        duplicateDatePickerExitBarrier = true
        guard let currentMeal = meal else {return}
        do {
            try realm.write {
                currentMeal.when = newDate
            }
        } catch {
            print("error updating meal \(error)")
        }
        cell.textLabel?.textColor = UIColor.black
        _ = cell.resignFirstResponder()
        tableView.reloadData()
    }
    
    @objc func onDateChange(_ sender: UIDatePicker, cell: DatePickerTableViewCell) {
        guard let dateCell = tableView.cellForRow(at: indexPathForDate!) else {return}
        dateCell.textLabel?.text = dateFormatter.string(from: sender.date)
    }
}

// MARK: - PickerTableCellDelegate
extension MealDetailsTableViewController : PickerTableCellDelegate, PickerTableCellDataSource{
    func numberOfComponents(in pickerView: UIPickerView, forCell cell: PickerTableViewCell) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int, forCell cell: PickerTableViewCell) -> Int {
        return emotions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int, forCell cell: PickerTableViewCell) -> String? {
        return "\(emotions[row].emoticon) \(emotions[row].name)"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int, forCell cell: PickerTableViewCell) {
        emotionForMeal = emotions[row]
        guard let emotionCell = tableView.cellForRow(at: indexPathForEmotion!) else {return}
        emotionCell.textLabel?.text = "\(emotionForMeal!.emoticon) \(emotionForMeal!.name)"
    }
    
    func onPickerOpen(_ cell: PickerTableViewCell) {
        guard let emotionCell = tableView.cellForRow(at: indexPathForEmotion!) else {return}
        duplicateExitBarrier = false
        emotionCell.textLabel?.textColor = UIColor.red
        if let emotionLabelText = emotionCell.textLabel?.text {
            let emotionText = emotionLabelText.toLengthOf(length: 2)
            guard let emotionIndex = emotions.index(matching: NSPredicate(format: "name = %@", emotionText)) else {return}
            cell.picker.selectRow(emotionIndex, inComponent: 0, animated: true)
        }
        
    }
    
    func onPickerClose(_ cell: PickerTableViewCell) {
//        print("Picker closed")
        if duplicateExitBarrier {
            return
        }
        guard let emotionCell = tableView.cellForRow(at: indexPathForEmotion!) else {return}
        duplicateExitBarrier = true
        emotionCell.textLabel?.textColor = UIColor.black
        guard let currentMeal = meal, let emotion = emotionForMeal else {return}

        do {
            if !emotion.meals.contains(currentMeal) {

                if meal?.emotionForMeal.count ?? 0 > 0
                {
                    guard let oldEmotion = meal?.emotionForMeal.first else {return}
                    guard let currentMealIndexInEmotion = oldEmotion.meals.index(of: currentMeal) else {return}
                    print("\(oldEmotion.name)")
                    try realm.write {
                        oldEmotion.meals.remove(at: currentMealIndexInEmotion)
                    }
                }
                try realm.write {
                    emotion.meals.append(currentMeal)
                }
            } 
            _ = cell.resignFirstResponder()
            meal = realm.objects(Meal.self).filter("_id=%@",meal?._id ?? "").first
            tableView.reloadData()
        } catch {
            print("error updating emotion in meal\(error)")
        }
    }
    
    
}

extension String {
    
    func toLengthOf(length:Int) -> String {
        if length <= 0 {
            return self
        } else if let to = self.index(self.startIndex, offsetBy: length, limitedBy: self.endIndex) {
            return String(self[to...])
            
        } else {
            return ""
        }
    }
}

extension MealDetailsTableViewController : UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return measureUnits.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return measureUnits[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        measureUnitTextField.text = measureUnits[row].name
        measureUnitSelected = measureUnits[row]
    }
}
