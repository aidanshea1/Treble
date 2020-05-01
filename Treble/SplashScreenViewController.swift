//
//  SplashScreenViewController.swift
//  Treble
//
//  Created by Aidan Shea on 4/26/20.
//  Copyright © 2020 Aidan Shea. All rights reserved.
//

import UIKit

class SplashScreenViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "ShowTableView", sender: nil)
    }
}
