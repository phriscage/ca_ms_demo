//
//  BlinktViewController.swift
//  MicroservicesDemo
//
//  Created by Christopher Page on 10/16/17.
//  Copyright © 2017 CA Technologies. All rights reserved.
//

import UIKit
import MASFoundation


class BlinktViewController: UIViewController {
  
  @IBOutlet var blinktButton: UIButton!
  var timer: Timer!
  var blinktCount = 50
  var requestPauseTime = 1.0
  var requestTimeInterval = 0.10
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.navigationItem.title = "IoT Blinkt"
    
    // Do any additional setup after loading the view.
    // These could be added in the Storyboard instead if you mark
    // buttonDown and buttonUp with @IBAction
    blinktButton.addTarget(self, action: #selector(BlinktViewController.buttonDown(sender:)), for: .touchDown)
    blinktButton.addTarget(self, action: #selector(BlinktViewController.buttonUp(sender:)), for: [.touchUpInside, .touchUpOutside])
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  /*
   // MARK: - Navigation
   
   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   // Get the new view controller using segue.destinationViewController.
   // Pass the selected object to the new view controller.
   }
   */
  
  /*
   // MARK: - button actions
   */
  // Button is pressed
  func buttonDown(sender: AnyObject) {
    singleFire()
    let when = DispatchTime.now() + requestPauseTime // change 2 to desired number of seconds
    DispatchQueue.main.asyncAfter(deadline: when) {
      // Your code with delay
      self.timer = Timer.scheduledTimer(timeInterval: self.requestTimeInterval, target: self, selector: #selector(BlinktViewController.rapidFire), userInfo: nil, repeats: true)
    }
  }
  
  // Button is released
  func buttonUp(sender: AnyObject) {
    timer.invalidate()
    blinktCount = 100
  }
  
  // single execution
  func singleFire() {
    print("sending blinkt!")
    postBlinkt()
  }
  
  // multiple executions
  func rapidFire() {
    if blinktCount > 0 {
      blinktCount -= 1
      print("sending blinkt! blinktCount: \(blinktCount)")
      postBlinkt()
    } else {
      print("out of blinkts, dude!")
      blinktCount = 100
      timer.invalidate()
    }
  }
  
  // send a POST to the Blinkts API
  func postBlinkt() {
    
    if (MASUser.current() != nil) {
      print(MASUser.current()?.accessToken as Any)
    }
    
//    MAS.post(to: Common.Constants.urlIoTBlinktRandom, withParameters: ["auth":Common.Constants.lacAuthKey], andHeaders: [:], completion:  { (response, error) in
    MAS.post(to: Common.Constants.urlIoTBlinktRandomWithAuth, withParameters: [:], andHeaders: [:], completion:  { (response, error) in
      if (error != nil) {
        var message:String
        let errorCode:Int = (error! as NSError).code
        switch errorCode {
        case -1011:
          message = "URL:'\(Common.Constants.urlIoTBlinktRandom)'?:\n" +
            "message: \(error!.localizedDescription)\n" +
          "error: \(response![MASResponseInfoBodyInfoKey]!)"
        default:
          message = "\(error!.localizedDescription)"
        }
        
        print(error.debugDescription)
        // create the alert
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        // show the alert
        self.present(alert, animated: true, completion: nil)
        
      } else {
        
        if let headerResponse = response?[MASResponseInfoHeaderInfoKey] as? [String: AnyObject] {
          print(headerResponse)
        }
        print(response?[MASResponseInfoBodyInfoKey]! as Any)
        
      }
      
    })
  }
  
}
