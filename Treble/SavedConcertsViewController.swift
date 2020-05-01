//
//  SavedConcertsViewController.swift
//  Treble
//
//  Created by Aidan Shea on 4/26/20.
//  Copyright © 2020 Aidan Shea. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase
import FirebaseUI
import GoogleSignIn

class SavedConcertsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var concerts: Concerts!
    var authUI: FUIAuth!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        authUI = FUIAuth.defaultAuthUI()
        authUI?.delegate = self
        
        concerts = Concerts()
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        concerts.loadData {
            self.tableView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowSavedDetail" {
            let destination = segue.destination as! ConcertDetailTableViewController
            let selectedIndexPath = tableView.indexPathForSelectedRow
            destination.concert = concerts.concertArray[selectedIndexPath!.row]
        }
    }
    
    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
}
extension SavedConcertsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return concerts.concertArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SavedCell", for: indexPath)
        if concerts.concertArray[indexPath.row].save == true {
            cell.textLabel?.text = concerts.concertArray[indexPath.row].concertTitle
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if concerts.concertArray[indexPath.row].save == false {
            return 0
        } else {
            return 60
        }
    }
    
}

extension SavedConcertsViewController: FUIAuthDelegate {
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        let sourceApplication = options[UIApplication.OpenURLOptionsKey.sourceApplication] as! String?
        if FUIAuth.defaultAuthUI()?.handleOpen(url, sourceApplication: sourceApplication) ?? false {
            return true
        }
        // other URL handling goes here.
        return false
    }
}
