//
//  Concerts.swift
//  Treble
//
//  Created by Aidan Shea on 4/25/20.
//  Copyright © 2020 Aidan Shea. All rights reserved.
//

import Foundation
import Firebase

class Concerts {
    var concertArray: [Concert] = []
    var db: Firestore!
    
    init() {
        db = Firestore.firestore()
    }
    
    func loadData(completed: @escaping () -> ())  {
        db.collection("concerts").addSnapshotListener { (querySnapshot, error) in
            guard error == nil else {
                print("*** ERROR: adding the snapshot listener \(error!.localizedDescription)")
                return completed()
            }
            self.concertArray = []
            // there are querySnapshot!.documents.count documents in the spots snapshot
            for document in querySnapshot!.documents {
              // You'll have to be sure you've created an initializer in the singular class (Concert, below) that acepts a dictionary.
                let concert = Concert(dictionary: document.data())
                concert.documentID = document.documentID
                self.concertArray.append(concert)
            }
            completed()
        }
    }
}
