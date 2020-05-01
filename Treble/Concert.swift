//
//  Concert.swift
//  Treble
//
//  Created by Aidan Shea on 4/25/20.
//  Copyright © 2020 Aidan Shea. All rights reserved.
//

import Foundation
import CoreLocation
import Firebase
import MapKit

class Concert: NSObject, MKAnnotation {
    var concertTitle: String
    var concertDescription: String
    var time: String
    var location: String
    var address: String
    var coordinate: CLLocationCoordinate2D
    var size: String
    var appImage: UIImage
    var appImageUUID: String
    var createdOn: Date
    var postingUserID: String
    var documentID: String
    var save: Bool
    
    var latitude: CLLocationDegrees {
        return coordinate.latitude
    }
    
    var longitude: CLLocationDegrees {
        return coordinate.longitude
    }
    
    var title: String? {
        return concertTitle
    }
    
    var subtitle: String? {
        return location
    }
    
    var dictionary: [String: Any] {
        // Convert from Apple date to a TimeInterval
        let timeIntervalDate = createdOn.timeIntervalSince1970
        
        return ["concertTitle": concertTitle, "concertDescription": concertDescription, "time": time, "location": location, "address": address, "latitude": latitude, "longitude": longitude, "size": size, "appImageUUID": appImageUUID, "createdOn": timeIntervalDate, "postingUserID": postingUserID, "documentID": documentID, "save": save]
    }
    
    init(concertTitle: String, concertDescription: String, time: String, location: String, address: String, coordinate: CLLocationCoordinate2D, size: String, appImage: UIImage, appImageUUID: String, createdOn: Date, postingUserID: String, documentID: String, save: Bool) {
        self.concertTitle = concertTitle
        self.concertDescription = concertDescription
        self.time = time
        self.location = location
        self.address = address
        self.coordinate = coordinate
        self.size = size
        self.appImage = appImage
        self.appImageUUID = appImageUUID
        self.createdOn = createdOn
        self.postingUserID = postingUserID
        self.documentID = documentID
        self.save = save
    }
    
    convenience init(dictionary: [String: Any]) {
        let concertTitle = dictionary["concertTitle"] as! String? ?? ""
        let concertDescription = dictionary["concertDescription"] as! String? ?? ""
        let time = dictionary["time"] as! String? ?? ""
        let location = dictionary["location"] as! String? ?? ""
        let address = dictionary["address"] as! String? ?? ""
        let latitude = dictionary["latitude"] as! CLLocationDegrees? ?? 0.0
        let longitude = dictionary["longitude"] as! CLLocationDegrees? ?? 0.0
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let size = dictionary["size"] as! String? ?? ""
        let appImageUUID = dictionary["appImageUUID"] as! String? ?? ""
        let timeIntervalDate = dictionary["createdOn"] as! TimeInterval? ?? TimeInterval()
        let createdOn = Date(timeIntervalSince1970: timeIntervalDate)
        let postingUserID = dictionary["postingUserID"] as! String? ?? ""
        let save = dictionary["save"] as! Bool? ?? false
        
        self.init(concertTitle: concertTitle, concertDescription: concertDescription, time: time, location: location, address: address, coordinate: coordinate, size: size, appImage: UIImage(), appImageUUID: appImageUUID, createdOn: createdOn, postingUserID: postingUserID, documentID: "", save: save)
    }
    
    convenience override init() {
        self.init(concertTitle: "", concertDescription: "", time: "", location: "", address: "", coordinate: CLLocationCoordinate2D(), size: "", appImage: UIImage(), appImageUUID: "", createdOn: Date(), postingUserID: "", documentID: "", save: false)
        
    }
    
    func saveData(completion: @escaping (Bool) -> ())  {
        let db = Firestore.firestore()
        // Grab the user ID
        guard let postingUserID = (Auth.auth().currentUser?.uid) else {
            print("*** ERROR: Could not save data because we don't have a valid postingUserID")
            return completion(false)
        }
        self.postingUserID = postingUserID
        // Create the dictionary representing data we want to save
        let dataToSave: [String: Any] = self.dictionary
        // if we HAVE saved a record, we'll have an ID
        if self.documentID != "" {
            let ref = db.collection("concerts").document(self.documentID)
            ref.setData(dataToSave) { (error) in
                if let error = error {
                    print("ERROR: updating document \(error.localizedDescription)")
                    completion(false)
                } else { // It worked!
                    completion(true)
                }
            }
        } else { // Otherwise create a new document via .addDocument
            var ref: DocumentReference? = nil // Firestore will creat a new ID for us
            ref = db.collection("concerts").addDocument(data: dataToSave) { (error) in
                if let error = error {
                    print("ERROR: adding document \(error.localizedDescription)")
                    completion(false)
                } else { // It worked! Save the documentID in Concert's documentID property
                    self.documentID = ref!.documentID
                    completion(true)
                }
            }
        }
    }
    
    func saveImage(completed: @escaping (Bool) -> ()) {
        let db = Firestore.firestore()
        let storage = Storage.storage()
        
        // Convert appImage to a Data type so it can be saved by Firebase Storage
        guard let imageToSave = self.appImage.jpegData(compressionQuality: 0.5) else {
            print("Error: Could not convert image to data format")
            return completed(false)
        }
        
        let uploadMetaData = StorageMetadata()
        uploadMetaData.contentType = "image/jpeg"
        if appImageUUID == "" { // if there is no UUID
            appImageUUID = UUID().uuidString
        }
        
        // create a reference to upload storage with the UUID we created
        let storageRef = storage.reference().child(documentID).child(self.appImageUUID)
        let uploadTask = storageRef.putData(imageToSave, metadata: uploadMetaData) { (metaData, error) in
            guard error == nil else {
                print("Error: Could not .putData storage upload for reference \(storageRef). Error = \(error?.localizedDescription ?? "Unknown error")")
                return completed(false)
            }
            print("Upload worked")
        }
        
        uploadTask.observe(.success) { (snapshot) in
            // Create dictionary representing the data we want to save
            let dataToSave = self.dictionary
            let ref = db.collection("concerts").document(self.documentID)
            ref.setData(dataToSave) { (error) in
                if let error = error {
                    print("Error: Could not save document \(self.documentID) in success observer. Error = \(error.localizedDescription)")
                    completed(false)
                } else {
                    print("Document updated with ref ID \(ref.documentID)")
                    completed(true)
                }
            }
        }
        
        uploadTask.observe(.failure) { (snapshot) in
            if let error = snapshot.error {
                print("Error: Could not upload task for file \(self.appImageUUID). Error = \(error.localizedDescription)")
            }
            return completed(false)
        }
    }
    
    func loadImage(completed: @escaping () -> ()) {
        let storage = Storage.storage()
        let storageRef = storage.reference().child(self.documentID).child(self.appImageUUID)
        // maxSize = 5MB = 5 * 1024 * 1024
        storageRef.getData(maxSize: 5 * 1024 * 1024) { (data, error) in
            guard error == nil else {
                print("Error: Could not load image from bucket \(self.documentID) for file \(self.appImageUUID)")
                return completed()
            }
            guard let downloadedImage = UIImage(data: data!) else {
                print("Error: Could not convert data to image image from bucket \(self.documentID) for file \(self.appImageUUID)")
                return completed()
            }
            self.appImage = downloadedImage
            completed()
        }
    }
}
