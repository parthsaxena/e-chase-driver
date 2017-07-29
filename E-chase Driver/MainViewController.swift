//
//  MainViewController.swift
//  E-chase Driver
//
//  Created by Parth Saxena on 7/4/17.
//  Copyright © 2017 Parth Saxena. All rights reserved.
//

import UIKit
import MapKit
import GeoFire
import Firebase

class MainViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var statusButton: UIButton!
    
    var circleQuery: GFCircleQuery!
    
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    var effect: UIVisualEffect!
    
    @IBOutlet weak var mapView: MKMapView!
    let locationManager = CLLocationManager()
    var userLocation: CLLocationCoordinate2D!
    var rawUserLocation: CLLocation!
    @IBOutlet weak var driverStatusLabel: UILabel!
    @IBOutlet var orderView: UIView!
    @IBOutlet weak var fullNameOrderView: UILabel!
    @IBOutlet weak var addressOrderView: UILabel!
    @IBOutlet weak var buttonOrderView: UIButton!
    
    var timer = Timer()
    var currentOrderTimerCount = 60
    var currentOrderRequest: [String: Any]!
    var currentOrderID: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        effect = visualEffectView.effect
        visualEffectView.effect = nil
        self.view.sendSubview(toBack: visualEffectView)
        
        // SET NAVIGATION BAR
        self.navigationController?.navigationItem.title = "E-CHASE DRIVER"
        self.navigationController?.navigationBar.alpha = 1
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "Roboto-Light", size: 24)!, NSForegroundColorAttributeName: UIColor.init(red: 49/255, green: 146/255, blue: 210/255, alpha: 1)]
        
        // SET COLOR OF BUTTON
        self.statusButton.backgroundColor = UIColor(red: 49/255, green: 136/255, blue: 210/255, alpha: 1.0)
        
        // INITIALIZE MAP
        //self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        mapView.delegate = self
        mapView.mapType = .standard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        
        // Do any additional setup after loading the view.
    }
    
    func animateOrderIn() {
        self.view.addSubview(orderView)
        orderView.center = self.view.center
        
        orderView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        orderView.alpha = 0
        self.view.bringSubview(toFront: visualEffectView)
        self.view.bringSubview(toFront: orderView)
        UIView.animate(withDuration: 0.4, animations: {
            self.visualEffectView.effect = self.effect
            self.orderView.alpha = 1
            self.orderView.transform = CGAffineTransform.identity
        })
    }
    
    func animateOrderOut() {
        UIView.animate(withDuration: 0.3, animations: {
            self.orderView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            self.orderView.alpha = 0
            
            self.visualEffectView.effect = nil
            
        }, completion: { (success: Bool) in
            self.orderView.removeFromSuperview()
            self.view.sendSubview(toBack: self.visualEffectView)
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locationManager.location?.coordinate {
            rawUserLocation = locationManager.location
            userLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            let region = MKCoordinateRegion(center: userLocation!, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            
            mapView.setRegion(region, animated: true)
            mapView.removeAnnotations(mapView.annotations)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = userLocation
            annotation.title = "Location"
            mapView.addAnnotation(annotation)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        if !(annotation is MKPointAnnotation) {
            return nil
        }
        
        let annotationIdentifier = "AnnotationIdentifier"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView!.canShowCallout = true
        }
        else {
            annotationView!.annotation = annotation
        }
        
        let pinImage = UIImage(named: "annotation")
        annotationView!.image = pinImage
        
        return annotationView
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func goOnlineTapped(_ sender: Any) {
        if GlobalVariables.DRIVER_STATUS == "OFFLINE" {
            let alert = UIAlertController(title: "Confirm", message: "Are you sure you would like to go online?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
                
                GlobalVariables.DRIVER_STATUS = "ONLINE"
                
                // PERFORM UI UPDATES
                self.statusButton.backgroundColor = UIColor.red
                self.statusButton.setTitle("GO OFFLINE", for: .normal)
                self.driverStatusLabel.text = "WAITING FOR ORDERS..."
                
                // UPDATE DRIVER STATUS ON FIREBASE
                self.receiveOrders()
            }))
            alert.view.tintColor = UIColor.red
            self.present(alert, animated: true, completion: nil)
        } else if GlobalVariables.DRIVER_STATUS == "ONLINE" {
            let alert = UIAlertController(title: "Confirm", message: "Are you sure you would like to go offline?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
                
                GlobalVariables.DRIVER_STATUS = "OFFLINE"
                
                // PERFORM UI UPDATES
                self.statusButton.backgroundColor = UIColor(red: 49/255, green: 136/255, blue: 210/255, alpha: 1.0)
                self.statusButton.setTitle("GO ONLINE", for: .normal)
                self.driverStatusLabel.text = "YOU ARE CURRENTLY OFFLINE."
                
                // UPDATE DRIVER STATUS ON FIREBASE
                self.circleQuery.removeAllObservers()
            }))
            alert.view.tintColor = UIColor.red
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func receiveOrders() {
        let geofire = GeoFire.init(firebaseRef: Database.database().reference().child("orders_locations"))
        circleQuery = geofire?.query(at: rawUserLocation, withRadius: 1000.0)
        circleQuery?.observe(.keyEntered, with: { (key, location) in
            if let orderKey = key as? String {
                print("ORDER KEY: \(orderKey) HAS BEEN PLACED.")
                Database.database().reference().child("orders").child(orderKey).observeSingleEvent(of: .value, with: { (snapshot) in
                    if let orderDictionary = snapshot.value as? [String: Any] {
                        let userUID = orderDictionary["uid"] as? String
                        let retreiveUserData = Database.database().reference().child("users").child(userUID!).observe(.value, with: { (snapshot) in
                            if let userDictionary = snapshot.value as? [String: Any] {
                                if let fullName = userDictionary["fullname"] as? String, let address = userDictionary["address"] as? String {
                                    print("DETAILS: \(fullName), \(address)")
                                    self.currentOrderRequest = orderDictionary
                                    self.currentOrderID = orderKey
                                    self.fullNameOrderView.text = fullName
                                    self.addressOrderView.text = address
                                    self.animateOrderIn()
                                    self.startOrderButtonTimer()
                                }
                            }
                        })
                    }
                })
            }
        })
    }
    
    func startOrderButtonTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateCounting), userInfo: nil, repeats: true)
    }
    
    func updateCounting() {
        currentOrderTimerCount-=1
        if currentOrderTimerCount == 0 {
            timer.invalidate()
            currentOrderTimerCount = 60
            self.animateOrderOut()
        } else {
            self.buttonOrderView.setTitle("Accept? (\(currentOrderTimerCount))", for: .normal)
        }
    }
    
    @IBAction func acceptOrderTapped(_ sender: Any) {
        // SET VARIABLE FOR NEXT VC
        GlobalVariables.CURRENT_ORDER_REQUEST = self.currentOrderRequest
        GlobalVariables.CURRENT_ORDER_ID = self.currentOrderID
        
        // UPDATE DRIVER AND ORDER STATUS
        
        // NEXT VIEWCONTROLLER
        self.navigationController?.performSegue(withIdentifier: "SegueToConfirmOrder", sender: self)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
