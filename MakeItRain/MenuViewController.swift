//
//  MenuViewController.swift
//  MakeItRain
//
//  Created by LunarLincoln on 7/21/17.
//  Copyright © 2017 LunarLincoln. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {
    
    
    @IBAction func pumpkinButton(_ sender: UIButton) {
    }
    
    @IBAction func mushroomAction(_ sender: UIButton) {
    }
    
    @IBAction func moneyAction(_ sender: UIButton) {
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "rainPumpkinSegue" {
            if let destination = segue.destination as? RainViewController {
                destination.itemNum = 0
            }
        }
        else if segue.identifier == "rainMushroomSegue" {
            if let destination = segue.destination as? RainViewController {
                destination.itemNum = 1
            }
        }
        else if segue.identifier == "rainMoneySegue" {
            if let destination = segue.destination as? RainViewController {
                destination.itemNum = 2
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
