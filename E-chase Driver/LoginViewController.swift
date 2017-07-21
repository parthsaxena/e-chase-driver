//
//  LoginViewController.swift
//  E-chase Driver
//
//  Created by Parth Saxena on 7/3/17.
//  Copyright © 2017 Parth Saxena. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logInUser(sender: Any) {
        let email = self.emailTextField.text
        let password = self.passwordTextField.text
        
        Auth.auth().signIn(withEmail: email!, password: password!) { (user, error) in
            if (error != nil) {
                // ERROR
                let alert = UIAlertController(title: "Whoops!", message: "There was an error logging you in. Please check your e-mail or password.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                alert.view.tintColor = UIColor.red
                self.present(alert, animated: true, completion: nil)
            } else {
                // SUCCESS
                print("Logged in to E-chase account.")
                // CHECK IF USER IS OF DRIVER STATUS
                Database.database().reference().child("users").child((user?.uid)!).observeSingleEvent(of: .value, with: { (snapshot) in
                    if let userDictionary = snapshot.value as? [String: Any] {
                        if let userType = userDictionary["userType"] as? String {
                            if userType == "driver" {
                                // USER IS A DRIVER, PROCEED
                                print("USER IS A DRIVER.")
                                self.performSegue(withIdentifier: "LogInToTutorial", sender: nil)
                            }
                        } else {
                            // USER IS NOT OF DRIVER STATUS
                            let alert = UIAlertController(title: "Whoops!", message: "It appears that you are not registered as an E-chase Driver.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            alert.view.tintColor = UIColor.red
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                })
            }
        }
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
