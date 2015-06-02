//
//  LocationDetailsTableViewController.swift
//  nostalgia
//
//  Created by Jae Hoon Lee on 4/17/15.
//  Copyright (c) 2015 Jae Hoon Lee. All rights reserved.
//

import UIKit
import CoreLocation

class LocationDetailsTableViewController: UITableViewController {
    
    // MARK: Outlets
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    // MARK: Actions
    @IBAction func doneBarButtonPressed() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cancelBarButtonPressed() {
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        descriptionTextView.text = ""
        latitudeLabel.text = String(format: "%.8f", coordinate.latitude)
        longitudeLabel.text = String(format: "%.8f", coordinate.longitude)
        
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .ShortStyle
        
        if let placemark = placemark {
            addressLabel.text = stringFromPlacemark(placemark)
        } else {
            addressLabel.text = "No Address Found"
        }
        
        dateLabel.text = formatDate(NSDate())
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Properties
    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var placemark: CLPlacemark?
    let dateFormatter = NSDateFormatter()
    
    // MARK : Methods
    func stringFromPlacemark(placemark: CLPlacemark) -> String { return
        "\(placemark.subThoroughfare) \(placemark.thoroughfare), " + "\(placemark.locality), " +
        "\(placemark.administrativeArea) \(placemark.postalCode)," + "\(placemark.country)"
    }
    
    func formatDate(date: NSDate) -> String {
        return dateFormatter.stringFromDate(date)
    }
}
