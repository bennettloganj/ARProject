//
//  MenuViewController.swift
//  MakeItRain
//
//  Created by LunarLincoln on 7/21/17.
//  Copyright © 2017 LunarLincoln. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {
    
    @IBOutlet weak var moneyButton: UIButton!
    @IBOutlet weak var pumpkinButton: UIButton!
    @IBOutlet weak var mushroomButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        moneyButton.layer.cornerRadius = 5
        pumpkinButton.layer.cornerRadius = 5
        mushroomButton.layer.cornerRadius = 5

    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
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
