//
//  ConcertDetailTableViewController.swift
//  Treble
//
//  Created by Aidan Shea on 4/25/20.
//  Copyright © 2020 Aidan Shea. All rights reserved.
//

import UIKit
import GooglePlaces
import MapKit

class ConcertDetailTableViewController: UITableViewController {
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var timeField: UITextField!
    @IBOutlet weak var spotsAvailableField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var locationField: UITextField!
    @IBOutlet weak var addressField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var saveSwitch: UISwitch!
    
    var concert: Concert!
    let regionDistance: CLLocationDistance = 25000 // 25KM
    var imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        
        if concert == nil {
            concert = Concert()
        }
        
        concert.loadImage {
            self.imageView.image = self.concert.appImage
        }
        
        let region = MKCoordinateRegion(center: concert.coordinate, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
        mapView.setRegion(region, animated: true)
        
        updateUserInterface()
    }
    
    func updateUserInterface() {
        titleField.text = concert.concertTitle
        timeField.text = concert.time
        spotsAvailableField.text = concert.size
        descriptionTextView.text = concert.concertDescription
        locationField.text = concert.location
        addressField.text = concert.address
        saveSwitch.isOn = concert.save
        updateMap()
    }
    
    func updateFromUserInterface() {
        concert.concertTitle = titleField.text!
        concert.time = timeField.text!
        concert.size = spotsAvailableField.text!
        concert.concertDescription = descriptionTextView.text
        concert.location = locationField.text!
        concert.address = addressField.text!
        concert.save = saveSwitch.isOn
    }
    
    func updateMap() {
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(concert)
        mapView.setCenter(concert.coordinate, animated: true)
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        leaveViewController()
    }
    
    func leaveViewController() {
        let isPresentingInAddMode = presentingViewController is UINavigationController
        if isPresentingInAddMode {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        updateFromUserInterface()
        concert.saveData { success in
            if success {
                self.concert.saveImage { (success) in
                    if !success {
                        print("Warning: Could not save image")
                    }
                    self.leaveViewController()
                }
            } else {
                print("*** ERROR: Couldn't leave this view controller because data wasn't saved.")
            }
        }
    }
    
    @IBAction func findLocationPressed(_ sender: UIBarButtonItem) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    
    @IBAction func cameraButtonPressed(_ sender: UIBarButtonItem) {
        cameraOrLibraryAlert()
    }
    @IBAction func saveSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            concert.save = true
        } else {
            concert.save = false
        }
    }
    
}

extension ConcertDetailTableViewController: GMSAutocompleteViewControllerDelegate {

  // Handle the user's selection.
  func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
    
    updateFromUserInterface()
    
    concert.location = place.name ?? "Unknown Location"
    concert.address = place.formattedAddress ?? "Unknown Address"
    concert.coordinate = place.coordinate

    updateUserInterface()
    
    dismiss(animated: true, completion: nil)
  }

  func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
    // TODO: handle the error.
    print("Error: ", error.localizedDescription)
  }

  // User canceled the operation.
  func wasCancelled(_ viewController: GMSAutocompleteViewController) {
    dismiss(animated: true, completion: nil)
  }

  // Turn the network activity indicator on and off again.
  func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
  }

  func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
    UIApplication.shared.isNetworkActivityIndicatorVisible = false
  }

}

extension ConcertDetailTableViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            concert.appImage = editedImage
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            concert.appImage = originalImage
        }
        dismiss(animated: true) {
            self.imageView.image = self.concert.appImage
        }
            
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func cameraOrLibraryAlert() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .default) { (_) in
            self.accessLibrary()
        }
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { (_) in
            self.accessCamera()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(photoLibraryAction)
        alertController.addAction(cameraAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func accessLibrary() {
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    func accessCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.sourceType = .camera
            present(imagePicker, animated: true, completion: nil)
        } else {
            self.oneButtonAlert(title: "Camera Not Available", message: "There is no camera available on this device.")
        }
    }
}
