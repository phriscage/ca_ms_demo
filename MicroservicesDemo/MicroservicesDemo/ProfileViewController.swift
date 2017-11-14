//
//  ProfileViewController.swift
//  MicroservicesDemo
//
//  Created by Christopher Page on 6/29/17.
//  Copyright © 2017 CA Technologies. All rights reserved.
//

import UIKit
import MASFoundation

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var beerBlinktOnButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        beerBlinktOnButton.tintColor = UIColor.clear
        if Common.Constants.BeerBlinktOn == true {
            beerBlinktOnButton.isSelected = true
            beerBlinktOnButton.setTitle("Beer Blinkt On".capitalized, for: .selected)
            beerBlinktOnButton.setTitleColor(UIColor.green, for: .selected)
        } else {
            beerBlinktOnButton.isSelected = false
            beerBlinktOnButton.setTitle("Beer Blinkt Off".capitalized, for: .normal)
            beerBlinktOnButton.setTitleColor(UIColor.white, for: .normal)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func beerBlinktOnButtonClicked(_ sender: UIButton) {
        print("beerBlinktOnButton Clicked")
        sender.tintColor = UIColor.clear
        if !sender.isSelected {
            sender.isSelected = true
            sender.setTitle("Beer Blinkt On".capitalized, for: .selected)
            sender.setTitleColor(UIColor.green, for: .selected)
            Common.Constants.BeerBlinktOn = true
        } else {
            sender.isSelected = false
            sender.setTitle("Beer Blinkt Off".capitalized, for: .normal)
            sender.setTitleColor(UIColor.white, for: .normal)
            Common.Constants.BeerBlinktOn = false
        }
        print("Common.Constants.BeerBlinktOn: \(Common.Constants.BeerBlinktOn)")
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    
    //
    // Button Logout tapped
    //
    @IBAction func logout(_ sender: Any) {
        
        if (MASUser.current() != nil) {
            let user = MASUser.current()?.userName
            
            if (MASUser.current()?.isAuthenticated)! {
                MASUser.current()?.logout(completion: { (completed: Bool, error: Error?) in
                    if (error != nil) {
                        //Something went wrong
                        print("Error during user logout: \(error?.localizedDescription ?? "unknown")")
                    } else {
                        //No errors
                        print("User \(user ?? "unknown") logged out - Showing the LoginViewController")
                        //self.showLogin()
                        let controller:UIViewController = LoginViewController()
                        self.present(controller, animated: true, completion: nil)
                    }
                })
            }
            
        }
        
    }
}
