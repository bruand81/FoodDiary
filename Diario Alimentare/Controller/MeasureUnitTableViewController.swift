//
//  MeasureUnitTableViewController.swift
//  Diario Alimentare
//
//  Created by Andrea Bruno on 05/01/2020.
//  Copyright © 2020 Andrea Bruno. All rights reserved.
//

import UIKit
import RealmSwift
import SwipeCellKit

class MeasureUnitTableViewController: UITableViewController {
    lazy var realm = try! Realm()
    lazy var measureUnits: Results<MeasureUnit> = realm.objects(MeasureUnit.self).sorted(byKeyPath: "name", ascending: true)
    var measureUnitToModify: MeasureUnit?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return measureUnits.count + 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "measureUnitCell", for: indexPath) as! SwipeTableViewCell
        if indexPath.row >= measureUnits.count || measureUnits.count == 0 {
            cell.textLabel?.text = NSLocalizedString("Add measure unit", comment: "")
            cell.textLabel?.textColor = UIColor.lightGray
            cell.selectionStyle = .none
        } else {
            cell.textLabel?.text = measureUnits[indexPath.row].name
        }
        cell.delegate = self
        cell.backgroundColor = UIColor.clear
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            return
        }
        if indexPath.row < measureUnits.count && measureUnits.count > 0 {
            editOrAddMeasureUnit(editAt: indexPath)
        } else {
            print("None to edit")
            return
        }
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.row >= measureUnits.count || measureUnits.count == 0 {
            return .insert
        }
        
        return .delete
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let measureUnitForDeletion = measureUnits[indexPath.row]
            deleteMeasureUnit(measureUnitForDeletion: measureUnitForDeletion)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            editOrAddMeasureUnit(editAt: indexPath)
            tableView.reloadData()
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // MARK: - Data manipulation function
    func deleteMeasureUnit(measureUnitForDeletion:MeasureUnit){
        do{
            try realm.write {
                realm.delete(measureUnitForDeletion.dishes)
                realm.delete(measureUnitForDeletion)
            }
            measureUnits = realm.objects(MeasureUnit.self).sorted(byKeyPath: "name", ascending: true)
        } catch {
            print("Error deletong measure unit \(error)")
        }
    }
    
    func editOrAddMeasureUnit(editAt indexPath: IndexPath){
        var nameTextField = UITextField()
        var alertTitle = ""
        
        if indexPath.row >= measureUnits.count {
            alertTitle = NSLocalizedString("New measure unit", comment: "Label for new measure unit alert title")
        } else {
            alertTitle = NSLocalizedString("Edit measure unit", comment: "Label for edit measure unit alert title")
            measureUnitToModify = measureUnits[indexPath.row]
        }
        
        let alert = UIAlertController(title: alertTitle, message: "", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
        let action = UIAlertAction(title: NSLocalizedString(alertTitle, comment: ""), style: .default) { (action) in
            if let name = nameTextField.text {
                if let measureUnit = self.measureUnitToModify {
                    self.updateMeasureUnit(measureUnit: measureUnit, measureUnitName: name)
                } else {
                    self.saveMeasureUnit(name: name)
                }
            }
            self.tableView.reloadData()
        }
        
        alert.addTextField { (alertTextField) in
            if let measureUnit = self.measureUnitToModify {
                alertTextField.text = measureUnit.name
            } else {
                alertTextField.placeholder = NSLocalizedString("Select name for measure unit", comment: "")
            }
            nameTextField = alertTextField
        }
        
        alert.addAction(action)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func saveMeasureUnit(name:String){
        let measureUnit = MeasureUnit()
        measureUnit.name = name
        do{
            try realm.write {
                realm.add(measureUnit)
            }
            measureUnits = realm.objects(MeasureUnit.self).sorted(byKeyPath: "name", ascending: true)
        } catch {
            print("Error inserting new measure unit \(error)")
        }
    }
    
    func updateMeasureUnit(measureUnit:MeasureUnit, measureUnitName: String){
        do{
            try realm.write {
                measureUnit.name = measureUnitName
            }
            
            measureUnits = realm.objects(MeasureUnit.self).sorted(byKeyPath: "name", ascending: true)
        } catch {
            print("Error updating measure unit \(error)")
        }
    }
    
}

// MARK: - SwipeCellKit methods
extension MeasureUnitTableViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]?{
        guard orientation == .right else {
            let modifyAction = SwipeAction(style: .default, title: NSLocalizedString("Edit", comment: "")) { (action, indexPath) in
                self.editOrAddMeasureUnit(editAt: indexPath)
                self.tableView.reloadData()
            }
            
            modifyAction.backgroundColor = UIColor.flatSkyBlue()
            modifyAction.image = UIImage(named: "edit-icon")
            return [modifyAction]
        }
        
        let deleteAction = SwipeAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { action, indexPath in
            let measureUnitForDeletion = self.measureUnits[indexPath.row]
            self.deleteMeasureUnit(measureUnitForDeletion: measureUnitForDeletion)
            self.tableView.reloadData()
        }
        
        deleteAction.image = UIImage(named: "delete-icon")
        return [deleteAction]
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        guard orientation == .right else {
            var options = SwipeOptions()
            
            options.expansionStyle = .none
            options.transitionStyle = .border
            
            return options
        }
        
        var options = SwipeOptions()
        
        options.expansionStyle = .destructive
        options.transitionStyle = .border
        
        return options
    }
}
