//
//  FirstViewController.swift
//  nostalgia
//
//  Created by Jae Hoon Lee on 4/16/15.
//  Copyright (c) 2015 Jae Hoon Lee. All rights reserved.
//

import UIKit
import CoreLocation

class LocationViewController: UIViewController, CLLocationManagerDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var statusMessageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var getMyLocationButton: UIButton!
    @IBOutlet weak var rememberButton: UIButton!
    
    // MARK: - Actions
    @IBAction func rememberButtonPressed(sender: UIButton) {
    }
    
    @IBAction func getMyLocationButtonPressed(sender: UIButton) {
        let authStatus = CLLocationManager.authorizationStatus()
        
        if authStatus == .NotDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        } else if authStatus == .Denied || authStatus == .Restricted {
            showLocationServicesDeniedAlert()
            return
        }
        
        if updatingLocation {
            stopLocationManager()
        } else {
            location = nil
            lastLocationError = nil
            placemark = nil
            lastGeocodingError = nil
            startLocationManager()
        }
        
        updateUI()
    }
    
    // MARK: - Properties
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError: NSError?
    
    // Object that will perform the geocoding
    let geocoder = CLGeocoder()
    // Object that contais the address results
    var placemark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: NSError?
    
    // MARK: - Methods
    func updateUI() {
        if let location = location {
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            if updatingLocation {
                statusMessageLabel.text = "Getting more accurate coordinates..."
                addressLabel.text = ""
            } else {
                statusMessageLabel.text = ""
            }
            
            if let placemark = placemark {
                addressLabel.text = stringFromPlacemark(placemark)
                rememberButton.setTitle("Remember", forState: .Normal)
                rememberButton.hidden = false
            } else if performingReverseGeocoding {
                addressLabel.text = "Searching for Address..."
            } else if lastGeocodingError != nil {
                addressLabel.text = "Error Finding Address"
            } else if updatingLocation {
                addressLabel.text = "Waiting for accurate GPS coordinates"
            } else {
                addressLabel.text = "No Address Found"
            }
        } else {
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
            rememberButton.hidden = true
            
            var statusMessage = ""
            
            if let error = lastLocationError {
                if error.domain == kCLErrorDomain && error.code == CLError.Denied.rawValue {
                    statusMessage = "Location Services Disabled"
                }
            } else if !CLLocationManager.locationServicesEnabled() {
                statusMessage = "Location Services Disabled"
            } else if updatingLocation {
                statusMessage = "Searching..."
            } else {
                statusMessage = "Tap 'Get My Location' to Start"
            }
            
            statusMessageLabel.text = statusMessage
        }
        configureGetButton()
    }
    
    func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
        }
    }
    
    func stopLocationManager() {
        if updatingLocation {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
        }
    }
    
    func configureGetButton() {
        if updatingLocation {
            getMyLocationButton.setTitle("Stop", forState: .Normal)
        } else {
            getMyLocationButton.setTitle("Get My Location", forState: .Normal)
        }
    }
    
    func stringFromPlacemark(placemark: CLPlacemark) -> String {
        
        return "\(placemark.subThoroughfare) \(placemark.thoroughfare)\n" + "\(placemark.locality) \(placemark.administrativeArea) " + "\(placemark.postalCode)"
    }
    
    
    // MARK: - Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "RememberLocation" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let controller = navigationController.topViewController as! LocationDetailsTableViewController
            
            controller.coordinate = location!.coordinate
            controller.placemark = placemark
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println("didFailWithError \(error)")
        
        if error.code == CLError.LocationUnknown.rawValue {
            return
        }
        
        lastLocationError = error
        
        stopLocationManager()
        updateUI()
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let newLocation = locations.last as! CLLocation
        println("didUpdateLocations \(newLocation)")
        
        // Ignore cached locations if they are too old
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        
        // Whenever the horizontal accuracy is a negative number, it is invalid
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        
        // Determine if the new reading is more accurate than the pervious one
        // Larger accuracy value means less accurate
        // If location is nil then this is the very first location we are receiving so we should update
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
            
            // Clears out any previous erros and updates the UI
            lastLocationError = nil
            location = newLocation
            updateUI()
            
            // If the new location's accuracy is equal to or better than the desired accuracy, stop
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
                println("done")
                stopLocationManager()
                
                if !performingReverseGeocoding {
                    self.updateUI()
                    println("*** Going to geocode")
                    performingReverseGeocoding = true
                    geocoder.reverseGeocodeLocation(location, completionHandler: {
                        placemarks, error in
                        
                        println("*** Found placemarks: \(placemarks), error: \(error)")
                        if error == nil && !placemarks.isEmpty {
                            self.placemark = placemarks.last as? CLPlacemark
                        } else {
                            self.placemark = nil
                        }
                        self.performingReverseGeocoding = false
                        self.updateUI()
                    })
                }
                self.updateUI()
            }
        }
    }
    
    // MARK: - Location Services Permissions
    func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable location services for this app in Settings", preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "Ok", style: .Default, handler: nil)
        
        alert.addAction(okAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
}