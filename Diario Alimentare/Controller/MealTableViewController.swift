//
//  MealTableViewController.swift
//  Diario Alimentare
//
//  Created by Andrea Bruno on 11/05/2019.
//  Copyright © 2019 Andrea Bruno. All rights reserved.
//

import UIKit
import RealmSwift
import SwipeCellKit
import GoogleMobileAds

struct MealDetailSection: Comparable {
    var month: Date
    var meals: [Meal]
    
    static func < (lhs: MealDetailSection, rhs: MealDetailSection) -> Bool {
        return lhs.month < rhs.month
    }
    
    static func == (lhs: MealDetailSection, rhs: MealDetailSection) -> Bool {
        return lhs.month == rhs.month
    }
    
    static func > (lhs: MealDetailSection, rhs: MealDetailSection) -> Bool {
        return lhs.month > rhs.month
    }
    
    static func group(meals : Results<Meal>) -> [MealDetailSection] {
        let groups = Dictionary(grouping: meals) { (meal) -> Date in
            return firstDayOfMonth(date: meal.when)
        }
        return groups.map({ (key, values) in
            return MealDetailSection(month: key, meals: values.sorted(by: { (lhs, rhs) -> Bool in
                lhs.when > rhs.when
            }))
        }).sorted().reversed()/*.sorted(by: { (lhs, rhs) -> Bool in
            lhs > rhs
        })*/
    }
    
}

fileprivate func firstDayOfMonth(date : Date) -> Date {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month], from: date)
    return calendar.date(from: components)!
}

class MealTableViewController: UITableViewController {
    @IBOutlet weak var emotionButton: UIBarButtonItem!
    @IBOutlet weak var bannerView: GADBannerView!
    // let realm = try! Realm()
    var meals: Results<Meal>?
    var createNewMeal = false
    var sections = [MealDetailSection]()
    
    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.long
        formatter.timeStyle = DateFormatter.Style.short
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //emotionButton.title = "☺︎"
//        bannerView.adUnitID = Bundle.main.object(forInfoDictionaryKey: "GADUnitID") as? String
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        bannerView.rootViewController = self
        bannerView.delegate = self
        bannerView.load(GADRequest())
        
        tableView.register(UINib(nibName: "MealTableViewCell", bundle: nil), forCellReuseIdentifier: MealTableViewCell().reuseIdentifier ?? "customMealCell")
        tableView.rowHeight = 80.0
        
        self.navigationController?.hidesNavigationBarHairline = true
        
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.backgroundColor = UIColor.flatBlue()
            // navBarAppearance.titleTextAttributes = [.foregroundColor: ContrastColorOf(navBarAppearance.backgroundColor ?? UIColor.flatBlue(), returnFlat: true)]
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            navigationController?.navigationBar.standardAppearance = navBarAppearance
            navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        }
        
        loadMeals()
        
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    /*override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *) {
            let hasUserInterfaceStyleChanged = previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) ?? false
            
            if hasUserInterfaceStyleChanged {
                let userInterfaceStyle = traitCollection.userInterfaceStyle
                /*if userInterfaceStyle == .dark {
                    Chameleon.setGlobalThemeUsingPrimaryColor(UIColor.flatBlue(), with: UIContentStyle.dark)
                } else {
                    Chameleon.setGlobalThemeUsingPrimaryColor(UIColor.flatBlue(), with: UIContentStyle.light)
                }*/
            }
        }
        
    }*/

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count > 0 ? sections.count : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections.count > 0 ? sections[section].meals.count : 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MealTableViewCell().reuseIdentifier ?? "customMealCell", for: indexPath) as! MealTableViewCell
        cell.delegate = self
        if (sections.count < 1){
            return defaultCell(cell: cell)
        }
//        guard let meal = meals?[indexPath.row] else {
//            return defaultCell(cell: cell)
//        }
        let meal = sections[indexPath.section].meals[indexPath.row]
        
        cell.emoticonForMeal.text = meal.emotionForMeal.first?.emoticon
        cell.dateOfTheMealLabel.text = "\(meal.name) - \(dateFormatter.string(from: meal.when))"
        cell.whatForMealLabel.text = meal.dishes.map({ (dish) -> String in
            var dishQuantity = ""
            
            if dish.quantity > 0 {
                dishQuantity = " (\(dish.quantity) \(dish.measureUnitForDishes.first?.name ?? "NN"))"
            }
            let dishName = "\(dish.name)\(dishQuantity)"
            
            return dishName
        }).joined(separator: ", ")
        
        return cell
    }

    
    func defaultCell(cell: MealTableViewCell) -> MealTableViewCell {
        cell.emoticonForMeal.text="❌"
        cell.dateOfTheMealLabel.text = ""
        cell.whatForMealLabel.text = NSLocalizedString("No meals inserted", comment: "")
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        createNewMeal = (sections.count < 1)
        performSegue(withIdentifier: "goToMealDetails", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToMealDetails" {
            let destinationVC = segue.destination as! MealDetailsTableViewController
            destinationVC.delegate = self
            if !createNewMeal {
                if let indexPath = tableView.indexPathForSelectedRow {
                    destinationVC.meal = sections[indexPath.section].meals[indexPath.row]
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if sections.count == 0 {
            return nil
        }
        let section = self.sections[section]
        let date = section.month
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.string(from: date)
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
    
    func loadMeals() {
        let realm = try! Realm()
        let startDate = firstDayOfMonth(date: Date(timeInterval: TimeInterval(floatLiteral: -1*3*30*24*60*60), since: Date()))
        meals = realm.objects(Meal.self).filter("when >= %@", startDate).sorted(byKeyPath: "when", ascending: true)
//        let groups = Dictionary(grouping: self.meals!) { (meal) in
//            return firstDayOfMonth(date: meal.when)
//        }
//
//        self.sections = groups.map({ (key, values) in
//            return MealDetailSection(month: key, meals: values)
//        })
        self.sections = MealDetailSection.group(meals: self.meals!)
        tableView.reloadData()
    }
    
    // MARK: - Add new meal
    @IBAction func addMealButtonPressed(_ sender: UIBarButtonItem) {
        createNewMeal = true
        performSegue(withIdentifier: "goToMealDetails", sender: self)
    }
    
    @IBAction func goToEmotionsButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "goToEmotions", sender: self)
    }
    
    @IBAction func goToMeasureUnitButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "goToMeasureUnit", sender: self)
    }
    
}
// MARK: - SwipeCellKit methods
extension MealTableViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else {return nil}
        
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            let mealForDeletion = self.sections[indexPath.section].meals[indexPath.row]
            do{
                let realm = try! Realm()
                try realm.write {
                    realm.delete(mealForDeletion.dishes)
                    realm.delete(mealForDeletion)
                }
            } catch {
                print("Error deleting meal \(error)")
            }
            self.loadMeals()
                
                //                tableView.reloadData()
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
    
}

extension MealTableViewController: MealDetailDelegate {
    func updatedMealDetails() {
        loadMeals()
    }
}

extension MealTableViewController: GADBannerViewDelegate {
    /// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
      print("adViewDidReceiveAd")
    }

    /// Tells the delegate an ad request failed.
    func adView(_ bannerView: GADBannerView,
        didFailToReceiveAdWithError error: GADRequestError) {
      print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }

    /// Tells the delegate that a full-screen view will be presented in response
    /// to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
      print("adViewWillPresentScreen")
    }

    /// Tells the delegate that the full-screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
      print("adViewWillDismissScreen")
    }

    /// Tells the delegate that the full-screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
      print("adViewDidDismissScreen")
    }

    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
      print("adViewWillLeaveApplication")
    }

}
