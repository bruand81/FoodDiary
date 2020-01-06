//
//  EmotionTableViewController.swift
//  Diario Alimentare
//
//  Created by Andrea Bruno on 11/05/2019.
//  Copyright © 2019 Andrea Bruno. All rights reserved.
//

import UIKit
import RealmSwift
import SwipeCellKit

class EmotionTableViewController: UITableViewController, SwipeTableViewCellDelegate {
    
    // let realm = try! Realm()
    var emotions: Results<Emotion>?
    var emotionToModify: Emotion?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "EmotionTableViewCell", bundle: nil), forCellReuseIdentifier: "customEmotionCell")
        tableView.rowHeight = 80.0

        loadEmotions()
        
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return emotions?.count ?? 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customEmotionCell", for: indexPath) as! EmotionTableViewCell
        cell.delegate = self

        guard let emotion = emotions?[indexPath.row] else {
            cell.EmoticonLabel.text = ""
            cell.EmotionDescriptionName.text = NSLocalizedString("No emotion defined yet", comment: "No emotion presents in database")
            return cell
        }
        
//        print("Emotion \(emotion.emoticon), \(emotion.name)")
        cell.EmoticonLabel.text = emotion.emoticon
        cell.EmotionDescriptionName.text = emotion.name
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        editOrAddEmotion(editAt: indexPath)
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

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
    //MARK: - Data Manipulation
    func loadEmotions() {
        let realm = try! Realm()
        emotions = realm.objects(Emotion.self).sorted(byKeyPath: "name", ascending: true)
        
        tableView.reloadData()
    }
    
    // MARK: - SwipeCellKit methods
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else {return nil}
        
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            if let emotionForDeletion = self.emotions?[indexPath.row] {
                do{
                    let realm = try! Realm()
                    try realm.write {
                        realm.delete(emotionForDeletion.meals)
                        realm.delete(emotionForDeletion)
                    }
                } catch {
                    print("Error deletong emotion \(error)")
                }
                
//                tableView.reloadData()
            }
        }
        
        deleteAction.image = UIImage(named: "delete-icon")
        return [deleteAction]
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        
        options.expansionStyle = .destructive
        options.transitionStyle = .border
        
        return options
    }
    
    // MARK: - Edit or add emotion
    @IBAction func addEmotionButtonPressed(_ sender: UIBarButtonItem) {
        editOrAddEmotion(editAt: nil)
    }
    
    func editOrAddEmotion(editAt indexPath: IndexPath?){
        var emoticonTextField = UITextField()
        var nameTextField = UITextField()
        
        var alertTitle = ""

        if let rowIndex = indexPath?.row, let emotion = emotions?[rowIndex] {
            alertTitle = "Edit Emotion"
            emotionToModify = emotion
        } else {
            alertTitle = "Add New Emotion"
        }
        
        let alert = UIAlertController(title: NSLocalizedString(alertTitle, comment: ""), message: "", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
        let action = UIAlertAction(title: NSLocalizedString(alertTitle, comment: ""), style: .default) { (action) in
            if let emoticon = emoticonTextField.text, let emotionName = nameTextField.text {
                let newEmotion = Emotion()
                newEmotion.emoticon = emoticon
                newEmotion.name = emotionName
                if let emotion = self.emotionToModify {
                    self.updateEmotion(emotion: emotion, newEmotionValue: newEmotion)
                } else {
                    self.saveEmotion(emotion: newEmotion)
                }
            }
            
            self.tableView.reloadData()
        }
        
        alert.addTextField { (alertTextField) in
            if let emotion = self.emotionToModify {
                alertTextField.text = emotion.emoticon
            } else {
                alertTextField.placeholder = NSLocalizedString("Select emoticon for emotion", comment: "")
            }
            emoticonTextField = alertTextField
        }
        
        alert.addTextField { (alertTextField) in
            if let emotion = self.emotionToModify {
                alertTextField.text = emotion.name
            } else {
                alertTextField.placeholder = NSLocalizedString("Select description for emotion", comment: "")
            }
            nameTextField = alertTextField
        }
        
        alert.addAction(action)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func updateEmotion(emotion: Emotion, newEmotionValue: Emotion){
        do{
            let realm = try! Realm()
            try realm.write {
                emotion.emoticon = newEmotionValue.emoticon
                emotion.name = newEmotionValue.name
            }
        } catch {
            print("Error updating emotion \(error)")
        }
    }
    
    func saveEmotion(emotion: Emotion) {
        do{
            let realm = try! Realm()
            try realm.write {
                realm.add(emotion)
            }
        } catch {
            print("Error inserting new emotion \(error)")
        }
    }
}
