//
//  ShareSettingsViewController.swift
//  Diario Alimentare
//
//  Created by Andrea Bruno on 17/01/2020.
//  Copyright © 2020 Andrea Bruno. All rights reserved.
//

import UIKit
import RealmSwift
import SwipeCellKit
import PickerViewCell
import Crashlytics
import xlsxwriter


enum ShareSettingsSection: CaseIterable {
    case viewConfigSection
    case exportToCSV
}

enum ShareSettingsExportToCSVRow: CaseIterable {
    case exportFormatCell
    case exportAll
    case fromDateLabel
    case fromDate
    case toDateLabel
    case toDate
    case exportButton
}

enum ShareFormats: CaseIterable {
    case csv
    case tsv
    case excel
}

enum ShareSettingsViewControllerErrors: Error {
    case NotValidDirError
}

class ShareSettingsViewController: UITableViewController {
    let sectionNumber = ShareSettingsSection.allCases.count
    var origCellTextColor: UIColor?
    var origCellBackgroundColor: UIColor?
    var duplicateDatePickerExitBarrier: Bool = false
    var curCell: DatePickerTableViewCell?
    let toolBar = UIToolbar()
    var dateIndexSet: [IndexPath] = []
    var exportAll = false
    var startDateText: Date?
    var endDateText: Date?
    var fromDateIndexPath: IndexPath?
    var toDateIndexPath: IndexPath?
    var shareFormat: ShareFormats = .excel
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
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
    
    override func viewDidLoad() {
        tableView.register(UINib(nibName: "SegmentedControlCell", bundle: nil), forCellReuseIdentifier: "segmentedControlCell")
        tableView.register(UINib(nibName: "SwitchCell", bundle: nil), forCellReuseIdentifier: "switchCell")
        tableView.register(UINib(nibName: "ToolbarCell", bundle: nil), forCellReuseIdentifier: "toolbarCell")
        
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if ShareSettingsSection.allCases.count <= section{
            return 0
        }
        
        switch ShareSettingsSection.allCases[section] {
        case .viewConfigSection:
            return 1
        case .exportToCSV:
            return ShareSettingsExportToCSVRow.allCases.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if ShareSettingsSection.allCases.count <= indexPath.section{
            let cell = tableView.dequeueReusableCell(withIdentifier: "exportCell", for: indexPath)
            return cell
        }
        
        switch ShareSettingsSection.allCases[indexPath.section] {
        case .viewConfigSection:
            let cell = tableView.dequeueReusableCell(withIdentifier: "toolbarCell", for: indexPath) as! ToolbarCell
            cell.backgroundColor = .systemBlue
            cell.doneButton.tintColor = .white
            cell.delegate = self
            return cell
        case .exportToCSV:
            return cellForExportToCsvSettings(tableView, cellForRowAt: indexPath)
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionNumber
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if ShareSettingsSection.allCases.count <= section{
            return nil
        }
        
        switch ShareSettingsSection.allCases[section] {
        case .viewConfigSection:
            return nil
        case .exportToCSV:
            return NSLocalizedString("Export to CSV", comment: "")
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch ShareSettingsSection.allCases[indexPath.section] {
        case .exportToCSV:
            disSelectRowInExportCSVSection(tableView, didSelectRowAt: indexPath)
        case .viewConfigSection:
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func disSelectRowInExportCSVSection(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch ShareSettingsExportToCSVRow.allCases[indexPath.row] {
        case .toDate:
            didSelectRowWithDatePicker(tableView, didSelectRowAt: indexPath)
        case .fromDate:
            didSelectRowWithDatePicker(tableView, didSelectRowAt: indexPath)
        case .exportButton:
            exportMeals()
        default:
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
    }
    
    func didSelectRowWithDatePicker(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let cell = tableView.cellForRow(at: indexPath) as? DatePickerTableViewCell {
            if exportAll {
                return
            }
            cell.delegate = self
            if !cell.isFirstResponder {
                _ = cell.becomeFirstResponder()
            }
        }
    }
    
    func expandCellToTableWidth(cell: UITableViewCell) {
        let cellFrame = cell.contentView.frame
        let newFrame = CGRect(origin: cellFrame.origin, size: CGSize(width: tableView.frame.width, height: cellFrame.height))
        cell.contentView.frame = newFrame
    }
    func cellForExportToCsvSettings(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if ShareSettingsExportToCSVRow.allCases.count <= indexPath.row {
           return UITableViewCell()
        }
        
        switch ShareSettingsExportToCSVRow.allCases[indexPath.row] {
        case .exportFormatCell:
            let cell = tableView.dequeueReusableCell(withIdentifier: "segmentedControlCell", for: indexPath) as! SegmentedControlCell
            cell.delegate = self
            cell.labelForSwitch.text = NSLocalizedString("Export format", comment: "")
            expandCellToTableWidth(cell: cell)
            return cell
        case .fromDate:
            if !dateIndexSet.contains(indexPath) {
                dateIndexSet.append(indexPath)
            }
            fromDateIndexPath = indexPath
            let cell = tableView.dequeueReusableCell(withIdentifier: "dateCell", for: indexPath) as! DatePickerViewCellWithToolbar
            startDateText = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            cell.textLabel?.text = dateFormatter.string(from: startDateText!)
            cell.toolbar = toolBar
            origCellBackgroundColor = cell.backgroundColor
            return cell
        case .toDate:
            if !dateIndexSet.contains(indexPath) {
                dateIndexSet.append(indexPath)
            }
            toDateIndexPath = indexPath
            let cell = tableView.dequeueReusableCell(withIdentifier: "dateCell", for: indexPath) as! DatePickerViewCellWithToolbar
            endDateText = Date()
            cell.textLabel?.text = dateFormatter.string(from: endDateText!)
            cell.toolbar = toolBar
            origCellBackgroundColor = cell.backgroundColor
            return cell
        case .fromDateLabel:
            if !dateIndexSet.contains(indexPath) {
                dateIndexSet.append(indexPath)
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "exportCell", for: indexPath)
            cell.textLabel?.text = NSLocalizedString("From date", comment: "")
            cell.backgroundColor = .lightGray
            return cell
        case .toDateLabel:
            if !dateIndexSet.contains(indexPath) {
                dateIndexSet.append(indexPath)
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "exportCell", for: indexPath)
            cell.textLabel?.text = NSLocalizedString("To date", comment: "")
            cell.backgroundColor = .lightGray
            return cell
        case .exportAll:
            let cell = tableView.dequeueReusableCell(withIdentifier: "switchCell", for: indexPath) as! SwitchCell
            cell.delegate = self
            cell.labelForSwitch.text = NSLocalizedString("Export all", comment: "")
            expandCellToTableWidth(cell: cell)
            return cell
        case .exportButton:
            let cell = tableView.dequeueReusableCell(withIdentifier: "exportButtonCell", for: indexPath)
            cell.textLabel?.text = NSLocalizedString("Export", comment: "")
            return cell
        }
    }
    
    func changeDateFieldStatus(_ isEnabled:Bool){
        for indexPath in dateIndexSet {
            if let cell = tableView.cellForRow(at: indexPath) {
//                cell.textLabel?.textColor = isEnabled ? self.origCellTextColor : .lightText
//                if let dateCell = cell as? DatePickerViewCellWithToolbar {
//                    dateCell.backgroundColor = isEnabled ? origCellBackgroundColor : .lightGray
//                }
                
                if isEnabled {
                   cell.isHidden = false
               }
                UIView.animate(withDuration: 0.5, animations: {
                    cell.alpha = isEnabled ? 100 : 0
                }) { _ in
                    cell.isHidden = !isEnabled
                }
            }
        }
    }
    
    func getAllMeals() -> Results<Meal> {
        let realm = try! Realm()
        return realm.objects(Meal.self).sorted(byKeyPath: "when", ascending: true)
    }
    
    func getMealsBetweenDate(startDate: Date, endDate: Date) -> Results<Meal> {
        let realm = try! Realm()
        return realm.objects(Meal.self).filter("when BETWEEN {%@, %@}", startDate,endDate).sorted(byKeyPath: "when", ascending: true)
    }
    
    func dishToString(dish: Dish) -> String {
        var dishQuantity = ""
        if dish.quantity > 0 {
           dishQuantity = " (\(self.format(quantity: dish.quantity)) \(dish.measureUnitForDishes.first?.name ?? "NN"))"
        }
        return "\(dish.name)\(dishQuantity)"
    }
    
    func exportMealsInCsv(meals: Results<Meal>) -> String {
        var csvString = "\"\(NSLocalizedString("Date", comment: ""))\",\"\(NSLocalizedString("Time", comment: ""))\",\"\(NSLocalizedString("Meal", comment: ""))\",\"\(NSLocalizedString("Dishes", comment: ""))\",\"\(NSLocalizedString("Emotion", comment: ""))\"\n"
        meals.forEach { (meal) in
            let mealContent = meal.dishes.map({ (dish) -> String in
                return self.dishToString(dish: dish)
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
                return self.dishToString(dish: dish)
            }).joined(separator: " - ").replacingOccurrences(of: ",", with: ";")
            let mealEmotion = meal.emotionForMeal.first
            let mealEmotionText = "\(mealEmotion?.emoticon ?? "") \(mealEmotion?.name ?? "")"
            let mealRowText = "\(dateOnlyFormatter.string(from: meal.when))\t\(timeOnlyFormatter.string(from: meal.when))\t\(meal.name)\t\(mealContent)\t\(mealEmotionText)\n"
            tsvString.append(mealRowText)
        }
        return tsvString
    }
    
    func exportMealsInXlsx(meals: Results<Meal>) -> URL? {
        let curDateAsText = dateFormatter.string(from: Date()).replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "")
               
        let file = "FoodDiary_\(curDateAsText).xlsx"
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(file)
//            print(fileURL.path)
//            print(fileURL.absoluteString)
//            FileManager.default.createFile(atPath: fileURL.absoluteString, contents: nil, attributes: nil)
            try! "".write(to: fileURL, atomically: false, encoding: .utf8)
            
            // Create a new workbook.
            let workbook = workbook_new((fileURL.path as NSString).fileSystemRepresentation)
            
            let worksheet = workbook_add_worksheet(workbook, NSLocalizedString("Diary", comment: ""))
            
            // Add some cell formats.
            let header_text = workbook_add_format(workbook)
            let common_text = workbook_add_format(workbook)
            let wrapped_text = workbook_add_format(workbook)
            
            // Set columna size
            worksheet_set_column(worksheet, 0, 0, 15, nil)
            worksheet_set_column(worksheet, 1, 2, 10, nil)
            worksheet_set_column(worksheet, 3, 3, 40, nil)
            worksheet_set_column(worksheet, 4, 4, 20, nil)
            
            // Set the bold property for the formats.
            format_set_bold(header_text)
            format_set_font_size(header_text, 14.0)
            format_set_text_wrap(wrapped_text)
            format_set_font_size(wrapped_text, 12.0)
            format_set_font_size(common_text, 12.0)
            format_set_bg_color(header_text, LXW_COLOR_GRAY.rawValue)
            
            //Writing header
            worksheet_write_string(worksheet, 0, 0, NSLocalizedString("Diary", comment: ""), header_text)
            worksheet_write_string(worksheet, 0, 1, NSLocalizedString("Time", comment: ""), header_text)
            worksheet_write_string(worksheet, 0, 2, NSLocalizedString("Meal", comment: ""), header_text)
            worksheet_write_string(worksheet, 0, 3, NSLocalizedString("Dishes", comment: ""), header_text)
            worksheet_write_string(worksheet, 0, 4, NSLocalizedString("Emotion", comment: ""), header_text)
            
            var row = 0
            meals.forEach { (meal) in
                row+=1
                let mealContent = meal.dishes.map({ (dish) -> String in
                    return self.dishToString(dish: dish)
                }).joined(separator: " - ").replacingOccurrences(of: ",", with: ";")
                let mealEmotion = meal.emotionForMeal.first
                let mealEmotionText = "\(mealEmotion?.emoticon ?? "") \(mealEmotion?.name ?? "")"
                
                worksheet_write_string(worksheet, lxw_row_t(row), 0, dateOnlyFormatter.string(from: meal.when), common_text)
                worksheet_write_string(worksheet, lxw_row_t(row), 1, timeOnlyFormatter.string(from: meal.when), common_text)
                worksheet_write_string(worksheet, lxw_row_t(row), 2, meal.name, common_text)
                worksheet_write_string(worksheet, lxw_row_t(row), 3, mealContent, wrapped_text)
                worksheet_write_string(worksheet, lxw_row_t(row), 4, mealEmotionText, common_text)
            }
            workbook_close(workbook)
            return fileURL
        }
        return nil
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
            throw ShareSettingsViewControllerErrors.NotValidDirError
        }
    }
    
    func format(quantity: Double) -> String {
        let formatter = NumberFormatter()
        formatter.usesSignificantDigits = true
        formatter.minimumSignificantDigits = 0 // default
        formatter.maximumSignificantDigits = 2 // default
        return formatter.string(from: NSNumber(value: quantity)) ?? ""
    }
    
    func exportMeals() {
        var meals: Results<Meal>?
        if exportAll {
            meals = getAllMeals()
        } else {
            guard let sdt = startDateText, let edt = endDateText else {
                return
            }
            meals = getMealsBetweenDate(startDate: sdt, endDate: edt)
        }
        
        guard let mealsToExport = meals else {return}
        
       
        do {
            let savedUrl = { () -> URL? in
                switch self.shareFormat {
                case .csv:
                    return try self.saveToFile(content: self.exportMealsInCsv(meals: mealsToExport))
                case .tsv:
                    return try self.saveToFile(content: self.exportMealsInTsv(meals: mealsToExport))
                case .excel:
                    return self.exportMealsInXlsx(meals: mealsToExport)
                }
            };
            if let fileUrl = try savedUrl() {
//                print(fileUrl)
                let activityViewController = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
                
                activityViewController.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
                    do {
                        try FileManager.default.removeItem(at: fileUrl)
                    } catch {
                        Crashlytics.sharedInstance().recordError(error)
                        print("Error removing file \(error)")
                    }
                    if let errorOccurred = error {
                        Crashlytics.sharedInstance().recordError(errorOccurred)
                        print("Error in UIActivityViewController: \(errorOccurred)")
                        return
                    }
                    if !completed {
                        // User canceled
                        do {
                            try FileManager.default.removeItem(at: fileUrl)
                        } catch {
                            Crashlytics.sharedInstance().recordError(error)
                            print("Error removing file \(error)")
                        }
                        return
                    }
                    // User completed activity
                    self.navigationController?.popViewController(animated: true)
                    self.dismiss(animated: true, completion: nil)
                }
                
                present(activityViewController, animated: true)
            }
        } catch {
            Crashlytics.sharedInstance().recordError(error)
            print("Error saving file \(error)")
        }
        
    }
    
}

// MARK: - Segmented Control Cell Delegate
extension ShareSettingsViewController: SegmentedControlDelegate{
    func exportFormatValueChanged(_ sender: UISegmentedControl) {
//        print(sender.titleForSegment(at: sender.selectedSegmentIndex) ?? "")
        let selectedFormat = sender.titleForSegment(at: sender.selectedSegmentIndex)
        switch selectedFormat {
        case "CSV":
            shareFormat = .csv
        case "TSV":
            shareFormat = .tsv
        case "Excel":
            shareFormat = .excel
        default:
            print(selectedFormat ?? "")
        }
    }
}

// MARK: - Toolbar Cell Delegate
extension ShareSettingsViewController:ToolbarCellDelegate {
    func doneButtonPressed(_ sender: UIButton) {
//        print("Dismiss export view")
        self.navigationController?.popViewController(animated: true)
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Date Picker Table Cell Delegate
extension ShareSettingsViewController: DatePickerTableCellDelegate{
    
    func onDateChange(_ sender: UIDatePicker, cell: DatePickerTableViewCell) {
        if let datePath = fromDateIndexPath, cell == tableView.cellForRow(at: datePath) {
            startDateText = sender.date
        } else if let datePath = toDateIndexPath, cell == tableView.cellForRow(at: datePath) {
            endDateText = sender.date
        }
        cell.textLabel?.text = dateFormatter.string(from: sender.date)
    }
    
    func onDatePickerOpen(_ cell: DatePickerTableViewCell) {
        let pickerDate = dateFormatter.date(from: cell.textLabel!.text!) ?? Date()
        if let datePath = fromDateIndexPath, cell == tableView.cellForRow(at: datePath) {
            startDateText = pickerDate
        } else if let datePath = toDateIndexPath, cell == tableView.cellForRow(at: datePath) {
            endDateText = pickerDate
        }
        self.origCellTextColor = cell.textLabel?.textColor
        self.curCell = cell
        cell.textLabel?.textColor = .systemRed
        duplicateDatePickerExitBarrier = false
        cell.picker.date = pickerDate
        toolBar.barStyle = .default
        toolBar.isTranslucent = true
        toolBar.sizeToFit()
        
        // Adding Button ToolBar
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(ShareSettingsViewController.doneClick))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(ShareSettingsViewController.cancelClick))
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: true)
        toolBar.isUserInteractionEnabled = true

        self.toolBar.isHidden = false
    }
    
    func onDatePickerClose(_ cell: DatePickerTableViewCell) {
        if duplicateDatePickerExitBarrier {
            return
        }
        endEditing()
    }
    
    @objc func doneClick() {
        self.toolBar.isHidden = true
        endEditing()
    }
    
    @objc func cancelClick() {
        self.toolBar.isHidden = true
        endEditing()
    }
    
    func endEditing(){
        duplicateDatePickerExitBarrier = true
        curCell?.textLabel?.textColor = self.origCellTextColor
        _ = curCell?.resignFirstResponder()
        curCell=nil
        view.endEditing(true)
    }
    
}

// MARK: - Switch Cell Delegate
extension ShareSettingsViewController: SwitchCellDelegate {
    func switchChanged(_ sender: UISwitch) {
        exportAll = sender.isOn
        changeDateFieldStatus(!exportAll)
    }
}
