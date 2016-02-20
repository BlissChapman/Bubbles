//
//  MapViewController.swift
//  Bubbles
//
//  Created by Bliss Chapman on 2/20/16.
//  Copyright © 2016 Bliss Chapman. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import SCLAlertView

class MapViewController: UIViewController {

    @IBOutlet weak var blowBubbleButtonLabel: UILabel!
    @IBOutlet weak var blowBubbleButton: ZFRippleButton!
    @IBOutlet weak var mapBackground: MKMapView!

    private let locationManager = CLLocationManager()

    //MARK: View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        configureUI()
    }

    private func configureUI() {
        blowBubbleButton.backgroundColor = ORANGE_COLOR
        blowBubbleButton.layer.masksToBounds = true
        //blowBubbleButton.layer.cornerRadius =  0.5 * blowBubbleButton.bounds.size.height

        blowBubbleButton.buttonCornerRadius = Float(blowBubbleButton.bounds.size.height/2)
        blowBubbleButton.rippleBackgroundColor = ORANGE_COLOR
        blowBubbleButton.rippleColor = PURPLE_COLOR
        blowBubbleButton.rippleOverBounds = false
        blowBubbleButton.trackTouchLocation = false
        blowBubbleButton.ripplePercent = 1.1
        blowBubbleButton.shadowRippleEnable = true

        locationManager.delegate = self

        //iOS intelligently sends a popup prompting the user to enable location services if this is disabled so I do not need to handle that case separately.
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .Denied, .Restricted: popLocationAlert()
            case .NotDetermined: locationManager.requestWhenInUseAuthorization()
            case .AuthorizedAlways, .AuthorizedWhenInUse:
                locationManager.requestLocation()
            }
        }
    }

    //MARK: UI
    @IBAction private func addBubbleTapped(sender: UIButton) {
        UIView.animateWithDuration(0.5) { () -> Void in
            self.blowBubbleButton.frame = self.view.frame
        }
        guard CONNECTED_TO_INTERNET else {
            let alert = SCLAlertView()
            alert.showError("Error", subTitle: "Please connect to the internet.")
            return
        }
    }

    //MARK: Location
    private func popLocationAlert() {
        let alert = SCLAlertView()
        alert.addButton("Open Settings", action: { () -> Void in
            if let appSettings = NSURL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.sharedApplication().openURL(appSettings)
            }
        })
        alert.showError("Location Required", subTitle: "Please open settings to revise your location privacy settings.")
    }

    private func zoomMap(withLocation location: CLLocation) {
        let viewRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 350, 350)
        let adjustedRegion = mapBackground.regionThatFits(viewRegion)
        mapBackground.setRegion(adjustedRegion, animated: true)
        mapBackground.showsUserLocation = true
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .Denied, .Restricted: popLocationAlert()
        case .NotDetermined: locationManager.requestWhenInUseAuthorization()
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            locationManager.requestLocation()
        }
    }

    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        let alert = SCLAlertView()
        alert.showError("Location Update Failed", subTitle: error.localizedDescription)
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        zoomMap(withLocation: locations.last!)
    }
}
