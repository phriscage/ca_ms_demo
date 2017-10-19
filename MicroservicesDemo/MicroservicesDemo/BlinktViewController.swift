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
  @IBOutlet var blinktCounterField: UITextField!
  @IBOutlet var blinktColorButton: UIButton!
  
//  "brown":  {139, 69, 19},
//  "red":    {255, 0, 0},
//  "orange": {255, 69, 0},
//  "yellow": {255, 255, 0},
//  "green":  {0, 255, 0},
//  "blue":   {0, 0, 255},
//  "violet": {128, 0, 128},
//  "grey":   {255, 255, 100},
//  "white":  {255, 255, 255},
  
  var blinktColors: [String: UIColor] = [
    "red": UIColor.init(red: 255/255, green: 0/255, blue: 0/255, alpha: 1),
    "white": UIColor.init(red: 255/255, green: 255/255, blue: 255/255, alpha: 1),
    "blue": UIColor.init(red: 0/255, green: 0/255, blue: 255/255, alpha: 1),
    "green": UIColor.init(red: 0/255, green: 255/255, blue: 0/255, alpha: 1)
  ]
  var blinktColorItem = 0
  var blinktColor = "green"
  
  var timer: Timer!
  var defaultBlinktCount = 20
  var blinktCount = 20
  var requestPauseTime = 1.0
  var requestTimeInterval = 0.10

  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
    // These could be added in the Storyboard instead if you mark

    self.navigationItem.title = "IoT Blinkt"
    // custom field attributes not global
    blinktCounterField.attributedPlaceholder = NSAttributedString(string: "Name", attributes: [NSForegroundColorAttributeName : UIColor.lightGray])
    blinktCounterField.textColor = UIColor.white
    blinktCounterField.text = String(blinktCount)
    // default colors
    blinktColorButton.isSelected = false
    blinktColorButton.setTitle(blinktColor.capitalized, for: .normal)
    blinktColorButton.setTitleColor(blinktColors[blinktColor], for: .normal)

    // buttonDown and buttonUp with @IBAction
    blinktButton.addTarget(self, action: #selector(BlinktViewController.buttonDown(sender:)), for: .touchDown)
    blinktButton.addTarget(self, action: #selector(BlinktViewController.buttonUp(sender:)), for: [.touchUpInside, .touchUpOutside])
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  // let's change the color and title after each click based off the blinktColors dict
  // also set the default blinktColor
  @IBAction func blinktColorButtonClicked(_ sender: UIButton) {
    let keys = Array(blinktColors.keys)
    sender.tintColor = UIColor.clear
    sender.setTitle(keys[blinktColorItem].capitalized, for: .normal)
    sender.setTitle(keys[blinktColorItem].capitalized, for: .selected)
    sender.setTitleColor(blinktColors[keys[blinktColorItem]], for: .selected)
    sender.setTitleColor(blinktColors[keys[blinktColorItem]], for: .normal)
    blinktColor = keys[blinktColorItem]
    if blinktColorItem >= keys.count - 1 {
      blinktColorItem = 0
    } else {
      blinktColorItem += 1
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
  
  // send a POST to the Blinkts API
  func postBlinkt() {
    
    if (MASUser.current() != nil) {
      print(MASUser.current()?.accessToken as Any)
    }
    let blinktUrl = Common.Constants.urlIoTBlinktRandomWithAuth + "&color=\(blinktColor)"
    
    MAS.post(to: blinktUrl, withParameters: [:], andHeaders: [:], completion:  { (response, error) in
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
        
        print(response?[MASResponseInfoBodyInfoKey]! as Any)
        
      }
      
    })
  }

  // MARK -- local methods
  
  // Button is pressed
  func buttonDown(sender: AnyObject) {
    singleFire()
    timer = Timer.scheduledTimer(timeInterval: self.requestTimeInterval, target: self, selector: #selector(BlinktViewController.rapidFire), userInfo: nil, repeats: true)
  }
  
  // Button is released
  func buttonUp(sender: AnyObject) {
    if timer != nil {
      timer.invalidate()
    }
    blinktCount = defaultBlinktCount
    self.blinktCounterField.text = String(blinktCount)
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
      self.blinktCounterField.text = String(blinktCount)
    } else {
      print("out of blinkts, dude!")
      timer.invalidate()
    }
  }
  
}
