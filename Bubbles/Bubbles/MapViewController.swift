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


    @IBOutlet weak var conflictButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var blowingLoadingSymbol: UIActivityIndicatorView!

    @IBOutlet weak var bubbleTextField: UITextView!
    @IBOutlet weak var bubbleContainer: UIView!
    @IBOutlet var addPressGestureRecognizer: UILongPressGestureRecognizer!
    @IBOutlet weak var blowBubbleButtonLabel: UILabel!
    @IBOutlet weak var blowBubbleButton: ZFRippleButton!
    @IBOutlet weak var mapBackground: MKMapView!

    private let locationManager = CLLocationManager()
    private var usersLocation: CLLocation?
    var newBubbleFrame: CGRect!
    var originalBubbleFrame: CGRect!

    //MARK: View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        configureUI()
        originalBubbleFrame = bubbleContainer.frame
        newBubbleFrame = CGRectMake(self.view.frame.width * 1/16, self.view.frame.width * 2/16, self.view.frame.width * 7/8, self.view.frame.height * 1/3)
    }

    private func configureUI() {
        blowBubbleButton.backgroundColor = .grayColor()
        blowBubbleButton.layer.masksToBounds = true
        //bubbleContainer.layer.masksToBounds = true
        bubbleContainer.layer.cornerRadius = bubbleContainer.bounds.size.height/10
        bubbleContainer.backgroundColor = PURPLE_COLOR

        blowBubbleButton.enabled = false

        addPressGestureRecognizer.minimumPressDuration = kBubbleBlowLength

        bubbleTextField.editable = false
        bubbleTextField.alpha = 0

        blowBubbleButton.buttonCornerRadius = Float(blowBubbleButton.bounds.size.height/2)
        blowBubbleButton.rippleBackgroundColor = ORANGE_COLOR
        blowBubbleButton.rippleColor = PURPLE_COLOR
        blowBubbleButton.rippleOverBounds = false
        blowBubbleButton.trackTouchLocation = false
        blowBubbleButton.ripplePercent = 1.1
        blowBubbleButton.shadowRippleEnable = true

        conflictButton.alpha = 0.0
        confirmButton.alpha = 0.0

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

    @IBAction func addBubbleTapped(sender: UILongPressGestureRecognizer) {
        guard usersLocation != nil else {
            let alert = SCLAlertView()
            alert.showError("Location Update Necessary", subTitle: "Please wait to blow a bubble until we've located you!")
            return
        }


        if sender.state == .Began {
            blowBubbleButton.enabled = false
            blowBubbleButton.backgroundColor = .grayColor()

            let newBubbleFrame = CGRectMake(self.view.frame.width * 1/16, self.view.frame.width * 2/16, self.view.frame.width * 7/8, self.view.frame.height * 1/3)
            UIView.animateWithDuration(3, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 1.5, options: [.CurveEaseOut, .AllowUserInteraction], animations: { () -> Void in

                self.bubbleContainer.transform = translatedAndScaledTransformUsingViewRect(newBubbleFrame, fromRect: self.originalBubbleFrame)

                UIView.animateWithDuration(1.0, delay: 1.5, options: .CurveEaseOut, animations: { () -> Void in
                    self.confirmButton.alpha = 1.0
                    self.conflictButton.alpha = 1.0

                    }, completion: nil)

                }, completion: { (completed) -> Void in



                    self.bubbleTextField.alpha = 1.0
                    self.bubbleTextField.editable = true
                    self.bubbleTextField.becomeFirstResponder()
                    //self.bubbleTextField.sizeToFit()

            })

        } else if sender.state == .Failed {
            sender.enabled = false
            sender.enabled = true
        }
    }

    @IBAction func blowButtonTapped(sender: UIButton) {

        let newBubble = Bubble(withMessage: bubbleTextField.text, andLocation: usersLocation!)
        blowingLoadingSymbol.startAnimating()
        newBubble.blow({ (record, error) -> Void in

            =>~{
                self.bubbleTextField.resignFirstResponder()
                self.blowingLoadingSymbol.stopAnimating()

                guard error == nil else {
                    debugPrint(error)
                    return
                }

                self.bubbleTextField.text = ""
                UIView.animateWithDuration(1.5, delay: 0.0, options: .CurveEaseIn, animations: { () -> Void in
                    self.bubbleContainer.frame = CGRect(x: self.bubbleContainer.frame.minX, y: -self.bubbleContainer.frame.height, width: self.bubbleContainer.frame.width / 2, height: self.bubbleContainer.frame.height)

                    }, completion: { (completed) -> Void in
                        self.bubbleContainer.transform = translatedAndScaledTransformUsingViewRect(self.newBubbleFrame, fromRect: self.originalBubbleFrame)
                })

                self.conflictButton.alpha = 0
                self.confirmButton.alpha = 0
            }



//            guard error == nil else {
//
//            }
            print(record)
            print(error)

            //UIView.animateWithDuration(<#T##duration: NSTimeInterval##NSTimeInterval#>, delay: <#T##NSTimeInterval#>, options: <#T##UIViewAnimationOptions#>, animations: <#T##() -> Void#>, completion: <#T##((Bool) -> Void)?##((Bool) -> Void)?##(Bool) -> Void#>)


        })
    }


    //MARK: UI
    //    @IBAction private func addBubbleTapped() {
    //        guard CONNECTED_TO_INTERNET else {
    //            let alert = SCLAlertView()
    //            alert.showError("Error", subTitle: "Please connect to the internet.")
    //            return
    //        }
    //    }

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
        usersLocation = locations.last!
        blowBubbleButton.enabled = true
        blowBubbleButton.backgroundColor = ORANGE_COLOR
    }
}