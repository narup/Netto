//
//  ViewController.swift
//  Example
//
//  Created by Puran Singh on 9/22/16.
//  Copyright © 2016 Huma Labs. All rights reserved.
//

import UIKit
import Netto

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let netto = NettoPodManager()
        print("\(netto.getName("Netto"))")
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

