//
//  ViewController.swift
//  Diario Alimentare
//
//  Created by Andrea Bruno on 10/05/2019.
//  Copyright © 2019 Andrea Bruno. All rights reserved.
//

import UIKit
import DatePickerDialog
import RealmSwift

enum FoodDiarySharingSettings: Int {
    case shareAll = 0
    case startDate = 1
    case endDate = 2
    case exportFormat = 3
}

fileprivate func firstDayOfMonth(date : Date) -> Date {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month], from: date)
    return calendar.date(from: components)!
}

enum SettingsViewControllerErrors: Error {
    case NotValidDirError
}

class ShareSettingsViewController: UIViewController {
    let realm = try! Realm()
    var shareAll: Bool = false
    var startDateText: Date?
    var endDateText: Date?
    let exportFormat =  [NSLocalizedString("csv", comment: ""),NSLocalizedString("tsv", comment: "")]
    var selectedFormat: String = NSLocalizedString("csv", comment: "")
    
    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.long
        formatter.timeStyle = DateFormatter.Style.short
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    fileprivate lazy var dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.long
        formatter.timeStyle = DateFormatter.Style.none
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    fileprivate lazy var timeOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.none
        formatter.timeStyle = DateFormatter.Style.short
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "SwitchTableViewCell", bundle: nil), forCellReuseIdentifier: "customShareAllSwitchCell")
        title = NSLocalizedString("Share Settings", comment: "")
        tableView.dataSource = self
        tableView.delegate = self
        // Do any additional setup after loading the view.
    }
    
    func getAllMeal() -> Results<Meal> {
        return realm.objects(Meal.self).sorted(byKeyPath: "when", ascending: true)
    }
    
    func getMealBetweenDate(startDate: Date, endDate: Date) -> Results<Meal> {
        return realm.objects(Meal.self).filter("when BETWEEN {%@, %@}", startDate,endDate).sorted(byKeyPath: "when", ascending: true)
    }
    
    func exportMealsInCsv(meals: Results<Meal>) -> String {
        var csvString = "\"\(NSLocalizedString("Date", comment: ""))\",\"\(NSLocalizedString("Time", comment: ""))\",\"\(NSLocalizedString("Meal", comment: ""))\",\"\(NSLocalizedString("Dishes", comment: ""))\",\"\(NSLocalizedString("Emotion", comment: ""))\"\n"
        meals.forEach { (meal) in
            let mealContent = meal.dishes.map({ (dish) -> String in
                return dish.name
            }).joined(separator: " - ").replacingOccurrences(of: ",", with: ";")
            let mealEmotion = meal.emotionForMeal.first
            let mealEmotionText = "\(mealEmotion?.emoticon ?? "") \(mealEmotion?.name ?? "")"
            let mealRowText = "\"\(dateOnlyFormatter.string(from: meal.when))\",\"\(timeOnlyFormatter.string(from: meal.when))\",\"\(meal.name)\",\"\(mealContent)\",\"\(mealEmotionText)\"\n"
            csvString.append(mealRowText)
        }
        return csvString
    }
    
    func exportMealsInTsv(meals: Results<Meal>) -> String {
        var tsvString = "\(NSLocalizedString("Date", comment: ""))\t\(NSLocalizedString("Time", comment: ""))\t\(NSLocalizedString("Meal", comment: ""))\t\(NSLocalizedString("Dishes", comment: ""))\t\(NSLocalizedString("Emotion", comment: ""))\n"
        meals.forEach { (meal) in
            let mealContent = meal.dishes.map({ (dish) -> String in
                return dish.name
            }).joined(separator: " - ").replacingOccurrences(of: ",", with: ";")
            let mealEmotion = meal.emotionForMeal.first
            let mealEmotionText = "\(mealEmotion?.emoticon ?? "") \(mealEmotion?.name ?? "")"
            let mealRowText = "\(dateOnlyFormatter.string(from: meal.when))\t\(timeOnlyFormatter.string(from: meal.when))\t\(meal.name)\t\(mealContent)\t\(mealEmotionText)\n"
            tsvString.append(mealRowText)
        }
        return tsvString
    }
    
    func saveToFile(content: String) throws -> URL{
        let curDateAsText = dateFormatter.string(from: Date()).replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "")
        
        let file = "FoodDiary_\(curDateAsText).csv"
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let fileURL = dir.appendingPathComponent(file)
            
            //writing
            do {
                try content.write(to: fileURL, atomically: false, encoding: .utf8)
                return fileURL
            }
            catch {
                print("Error saving file \(error)")
                throw error
            }
        } else {
            throw SettingsViewControllerErrors.NotValidDirError
        }
    }
    
    @IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
        var meals: Results<Meal>?
        if shareAll {
            meals = getAllMeal()
        } else {
            guard let sdt = startDateText, let edt = endDateText else {
                return
            }
            meals = getMealBetweenDate(startDate: sdt, endDate: edt)
        }
        
        var csvText = "";
        switch selectedFormat {
        case NSLocalizedString("csv", comment: ""):
            csvText = exportMealsInCsv(meals: meals!)
            break;
        case NSLocalizedString("tsv", comment: ""):
            csvText = exportMealsInTsv(meals: meals!)
            break;
        default:
            print()
        }
        
        do {
            let fileUrl = try saveToFile(content: csvText)
            print(fileUrl)
            let activityViewController = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
            
            activityViewController.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
                do {
                    try FileManager.default.removeItem(at: fileUrl)
                } catch {
                    print("Error removing file \(error)")
                }
                if let errorOccurred = error {
                    print("Error in UIActivityViewController: \(errorOccurred)")
                    return
                }
                if !completed {
                    // User canceled
                    return
                }
                // User completed activity
                self.navigationController?.popViewController(animated: true)
            }
            
            present(activityViewController, animated: true)
        } catch {
            print("Error saving file \(error)")
        }
        
        //self.navigationController?.popViewController(animated: true)
        //self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
        //self.dismiss(animated: true, completion: nil)
    }
    
}

extension ShareSettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case FoodDiarySharingSettings.shareAll.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "customShareAllSwitchCell", for: indexPath) as! SwitchTableViewCell;
            cell.delegate = self
            cell.setSwitchOn(value: shareAll)
            cell.titleLabel?.text = NSLocalizedString("Share all the meals", comment: "")
            return cell
        case FoodDiarySharingSettings.startDate.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "dateCell", for: indexPath)
            let startDate = firstDayOfMonth(date: Date(timeInterval: TimeInterval(floatLiteral: -1*3*30*24*60*60), since: Date()))
            startDateText = startDate
            cell.textLabel?.text = NSLocalizedString("Start date", comment: "")
            cell.detailTextLabel?.text = dateOnlyFormatter.string(from: startDateText ?? startDate)
            return cell
        case FoodDiarySharingSettings.endDate.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "dateCell", for: indexPath)
            cell.textLabel?.text = NSLocalizedString("End date", comment: "")
            endDateText = Date()
            cell.detailTextLabel?.text = dateOnlyFormatter.string(from: endDateText ?? Date())
            return cell
        case FoodDiarySharingSettings.exportFormat.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: "dateCell", for: indexPath)
            cell.textLabel?.text = NSLocalizedString("Format", comment: "")
            cell.detailTextLabel?.text = selectedFormat
            return cell
        default:
            fatalError()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        
        case FoodDiarySharingSettings.startDate.rawValue:
            if shareAll {
                return CGFloat(0.0)
            }
            return tableView.rowHeight
        case FoodDiarySharingSettings.endDate.rawValue:
            if shareAll {
                return CGFloat(0.0)
            }
            return tableView.rowHeight
        case FoodDiarySharingSettings.shareAll.rawValue:
            return CGFloat(50.0)
        default:
            return tableView.rowHeight
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case FoodDiarySharingSettings.startDate.rawValue:
            let startDate = firstDayOfMonth(date: Date(timeInterval: TimeInterval(floatLiteral: -1*3*30*24*60*60), since: Date()))
            DatePickerDialog().show(NSLocalizedString("Select the start date", comment: ""), doneButtonTitle: NSLocalizedString("Done", comment: ""), cancelButtonTitle: NSLocalizedString("Cancel", comment: ""), defaultDate: startDate, minimumDate: nil, maximumDate: nil, datePickerMode: .date, callback: {(date) in
                    if let dt = date {
                        self.startDateText = dt
                        self.tableView.reloadData()
                    }
                })
        case FoodDiarySharingSettings.endDate.rawValue:
            DatePickerDialog().show(NSLocalizedString("Select the end date", comment: ""), doneButtonTitle: NSLocalizedString("Done", comment: ""), cancelButtonTitle: NSLocalizedString("Cancel", comment: ""), defaultDate: Date(), minimumDate: nil, maximumDate: nil, datePickerMode: .date, callback: {(date) in
                if let dt = date {
                    self.endDateText = dt
                    self.tableView.reloadData()
                }
            })
        case FoodDiarySharingSettings.exportFormat.rawValue:
            let pickerViewDialog = CustomPickerDialog(dataSource: exportFormat) { (format) -> String in
                return format
            }
            
            pickerViewDialog.selectRow(0)
            
            pickerViewDialog.showDialog(NSLocalizedString("Select export format", comment: ""), doneButtonTitle: NSLocalizedString("Done", comment: ""), cancelButtonTitle: NSLocalizedString("Cancel", comment: "")) { (format) in
                self.selectedFormat = format
                self.tableView.reloadData()
            }
            
            break;
        default:
            return
        }
    }
    
    
}

extension ShareSettingsViewController: SwitchTableViewCellDelegate {
    func valueChanged(withCurrentValue value: Bool) {
        shareAll = value
        tableView.reloadData()
    }
}
