//
//  PickItemsTableViewController.swift
//  
//
//  Created by Parth Saxena on 7/10/17.
//
//

import UIKit
import CoreLocation
import Firebase
import M13Checkbox

class PickItemsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {

    let locationManager = CLLocationManager()
    var userLocation: CLLocationCoordinate2D!
    var rawUserLocation: CLLocation!
    
    @IBOutlet weak var itemsTableView: UITableView!
    var items = NSMutableArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // SET NAVIGATION BAR
        self.navigationController?.navigationItem.title = "PICK UP ORDER"
        self.navigationController?.navigationBar.alpha = 1
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "Roboto-Light", size: 24)!, NSForegroundColorAttributeName: UIColor.init(red: 49/255, green: 146/255, blue: 210/255, alpha: 1)]
        
        self.itemsTableView.delegate = self
        self.itemsTableView.dataSource = self

        // INITIALIZE MAP
        //self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        
        let currentOrderRequest = GlobalVariables.CURRENT_ORDER_REQUEST
        //print("JSON VALUE: \(currentOrderRequest?["json"])")
        if let itemsArray = currentOrderRequest?["json"] as? NSArray {
            for itemRaw in itemsArray {
                if let item = itemRaw as? NSArray {
                    // [0] IS PRODUCT
                    // [1] IS STORE
                    // [2] IS STORE-NAME AS STRING
                    
                    var productValue: [String: Any]!
                    var storeValue: [String: Any]!
                    var storeNameValue: String!
                    
                    if let product = item[0] as? [String: Any] {
                        print(product)
                        productValue = product
                    }
                    if let store = item[1] as? [String: Any] {
                        print(store)
                        storeValue = store
                    }
                    if let storeName = item[2] as? String {
                        print(storeName)
                        storeNameValue = storeName
                    }
                    
                    self.items.add([productValue, storeValue, storeNameValue])
                }
            }
            // LOAD CONTENT ONTO TABLEVIEW
            self.itemsTableView.reloadData()
            self.itemsTableView.tableFooterView = UIView()
        }

        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PickItemTableViewCell
        // Configure the cell...
        
        let orderItem = self.items[indexPath.row] as? NSArray
        
        if let product = orderItem?[0] as? [String: Any] {
            if let imageAddressString = product["image"] as? String {
                let imageURL = URL(string: imageAddressString)
                let imageData: Data!
                do {
                    try imageData = Data(contentsOf: imageURL!)
                    cell.itemImageView.image = UIImage(data: imageData)
                } catch {
                    // no image available
                    cell.itemImageView.image = UIImage(named: "image-not-available")
                }
            } else {
                // no image available
                cell.itemImageView.image = UIImage(named: "image-not-available")
            }
            if let titleString = product["title"] as? String {
                cell.itemTitleLabel.text = titleString
            }
            
            if let priceDouble = product["price"] as? Double {
                cell.itemPriceLabel.text = "$\(String(format:"%.2f", priceDouble))"
            }
        }
        if let store = orderItem?[1] as? [String: Any] {
            if let address = store["address"] as? String {
                cell.storeAddressLabel.text = address
            }
        }
        if let storeName = orderItem?[2] as? String {
            cell.storeNameLabel.text = storeName
        }

        return cell
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locationManager.location?.coordinate {
            rawUserLocation = locationManager.location
            userLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
 
            if let orderID = GlobalVariables.CURRENT_ORDER_REQUEST?["id"] as? String {
                Database.database().reference().child("orders").child(orderID).updateChildValues(["driverLatitude":userLocation.latitude, "driverLongitude":userLocation.longitude])
            }
            
        }
    }
    
    @IBAction func checkboxValueChanged(sender: M13Checkbox) {
        let buttonPosition:CGPoint = sender.convert(CGPoint.zero, to:self.itemsTableView)
        let indexPath = self.itemsTableView.indexPathForRow(at: buttonPosition)
        
        let checkboxReferenced = (self.itemsTableView.cellForRow(at: indexPath!) as! PickItemTableViewCell).itemCheckbox
        if let row = indexPath?.row {
            if checkboxReferenced?.checkState == .checked {
                Database.database().reference().child("orders").child(GlobalVariables.CURRENT_ORDER_ID).updateChildValues(["item\(row)PickedUp":"true"])
            } else {
                Database.database().reference().child("orders").child(GlobalVariables.CURRENT_ORDER_ID).updateChildValues(["item\(row)PickedUp":"false"])
            }
        }
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
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
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
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
