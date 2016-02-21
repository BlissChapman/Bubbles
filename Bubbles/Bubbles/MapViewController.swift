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
import CloudKit

class MapViewController: UIViewController {


    @IBOutlet weak var conflictButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var blowingLoadingSymbol: UIActivityIndicatorView!

    @IBOutlet weak var bubbleTextField: UITextView!
    @IBOutlet weak var bubbleContainer: UIView!
    @IBOutlet var addPressGestureRecognizer: UILongPressGestureRecognizer!
    @IBOutlet weak var blowBubbleButton: ZFRippleButton!
    @IBOutlet weak var mapBackground: MKMapView!

    private let locationManager = CLLocationManager()
    private var usersLocation: CLLocation?
    var newBubbleFrame: CGRect!
    var originalBubbleFrame: CGRect!
    var firstUpdate = true

    var nearbyBubbles: [CKRecord]? {
        didSet {
            print("THERE ARE \(nearbyBubbles!.count) BUBBLES TO POP HERE")
        }
    }

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
        bubbleContainer.layer.cornerRadius = bubbleContainer.bounds.size.height/10
        bubbleContainer.backgroundColor = PURPLE_COLOR

        blowBubbleButton.enabled = false

        addPressGestureRecognizer.minimumPressDuration = kBubbleBlowLength

        bubbleTextField.editable = false
        bubbleTextField.alpha = 0
        mapBackground.delegate = self

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
            //held it long enough
            scanOrAddBubble()

        } else if sender.state == .Failed {
            sender.enabled = false
            sender.enabled = true
        }
    }

    private func scanOrAddBubble() {

        let blowBubble: ()->() = {
            print("BLOWING NEW BUBBLE")
            self.blowBubbleButton.enabled = false
            self.blowBubbleButton.backgroundColor = .grayColor()

            UIView.animateWithDuration(3, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 1.5, options: [.CurveEaseOut, .AllowUserInteraction], animations: { () -> Void in

                self.bubbleContainer.transform = translatedAndScaledTransformUsingViewRect(self.newBubbleFrame, fromRect: self.originalBubbleFrame)

                UIView.animateWithDuration(1.0, delay: 1.5, options: .CurveEaseOut, animations: { () -> Void in
                    self.confirmButton.alpha = 1.0
                    self.conflictButton.alpha = 1.0
                    self.confirmButton.enabled = true
                    self.conflictButton.enabled = true

                    }, completion: nil)

                }, completion: { (completed) -> Void in

                    self.bubbleTextField.alpha = 1.0
                    self.bubbleTextField.editable = true
                    self.bubbleTextField.becomeFirstResponder()
            })
        }

        let popBubble: (record: CKRecord)->() = { record in

            Cloud.popBubble(record, completionHandler: { (record, error) -> () in
                guard error == nil else {
                    debugPrint(error)
                    return
                }

                let message = record!["message"] as! String

                =>~{
                    self.reloadMapPins()
                    print("POPPING BUBBLE WITH MESSAGE: \(message)")

                    self.bubbleTextField.text = message
                    UIView.animateWithDuration(3, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 1.5, options: [.CurveEaseOut, .AllowUserInteraction], animations: { () -> Void in

                        self.bubbleContainer.transform = translatedAndScaledTransformUsingViewRect(self.newBubbleFrame, fromRect: self.originalBubbleFrame)

                        UIView.animateWithDuration(1.0, delay: 1.5, options: .CurveEaseOut, animations: { () -> Void in
                            self.conflictButton.alpha = 1.0
                            self.conflictButton.enabled = true

                            }, completion: nil)

                        }, completion: { (completed) -> Void in

                            self.bubbleTextField.alpha = 1.0
                            self.bubbleTextField.editable = false
                    })
                }
            })
        }

        if let poppableBubbles = nearbyBubbles where poppableBubbles.count > 0 {
            popBubble(record: poppableBubbles.first!)
        } else {
            blowBubble()
        }
    }

    @IBAction func blowCanceledTapped(sender: UIButton) {
        resetBubbleContainer()
    }

    @IBAction func blowButtonTapped(sender: UIButton) {

        let newBubble = Bubble(withMessage: bubbleTextField.text, andLocation: usersLocation!)
        blowingLoadingSymbol.startAnimating()
        bubbleTextField.editable = false
        conflictButton.enabled = false
        confirmButton.enabled = false
        newBubble.blow({ (record, error) -> Void in

            print("NEW WAY")

            delay(2.0, AndExecuteClosure: { () -> Void in
                self.reloadMapPins(withCompletion: { () -> () in
                    =>~{
                        self.conflictButton.enabled = true

                        self.bubbleTextField.editable = true
                        self.bubbleTextField.resignFirstResponder()
                        self.blowingLoadingSymbol.stopAnimating()

                        guard error == nil else {
                            debugPrint(error)
                            return
                        }

                        //successful blow
                        self.bubbleTextField.text = ""
                        UIView.animateWithDuration(1.5, delay: 0.0, options: .CurveEaseIn, animations: { () -> Void in
                            let animatedNewBubbleRect = CGRect(x: self.bubbleContainer.frame.minX + (self.bubbleContainer.frame.width / 4), y: -self.bubbleContainer.frame.height, width: self.bubbleContainer.frame.width / 2, height: self.bubbleContainer.frame.height)
                            self.bubbleContainer.frame = animatedNewBubbleRect
                            self.conflictButton.alpha = 0
                            self.confirmButton.alpha = 0

                            }, completion: { (completed) -> Void in
                                //put frame back to where it was before animation
                                self.resetBubbleContainer()
                        })
                    }
                })
            })
        })
    }

    private func resetBubbleContainer() {
        bubbleTextField.text = ""
        bubbleTextField.editable = false
        bubbleTextField.resignFirstResponder()

        bubbleContainer.transform = translatedAndScaledTransformUsingViewRect(self.originalBubbleFrame, fromRect: self.bubbleContainer.frame)

        conflictButton.enabled = true
        confirmButton.enabled = true
        blowBubbleButton.enabled = true
        blowBubbleButton.backgroundColor = ORANGE_COLOR

        conflictButton.alpha = 0
        confirmButton.alpha = 0
        conflictButton.enabled = false
        confirmButton.enabled = false


    }

    //MARK: UI
    private func reloadMapPins(withCompletion completion: (()->())? = nil) {
        print("RELOADNG MAP PINS")
        let annotationsToRemove = mapBackground.annotations.filter { $0 !== mapBackground.userLocation }
        mapBackground.removeAnnotations( annotationsToRemove )
        Cloud.fetchAllPoppableBubbles(withLocation: usersLocation!) { (records, error) -> () in
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), { () -> Void in
                self.nearbyBubbles = records

                var allAnnotations = [MKAnnotation]()
                for record in records! {
                    if let recordLocation = record["location"] as? CLLocation {
                        let defaultPinAnnotation = MKPointAnnotation()
                        defaultPinAnnotation.coordinate = recordLocation.coordinate
                        allAnnotations.append(defaultPinAnnotation)
                    }
                }

                =>~{
                    self.mapBackground.addAnnotations(allAnnotations)
                    completion?()
                }
            })
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
        print("LOCATION UPDATE FAILED")
        //let alert = SCLAlertView()
        //alert.showError("Location Update Failed", subTitle: error.localizedDescription)
        locationManager.requestLocation()
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        usersLocation = locations.last!

        if firstUpdate {
            zoomMap(withLocation: locations.last!)

            reloadMapPins(withCompletion: { _ in
                self.blowBubbleButton.enabled = true
                self.blowBubbleButton.backgroundColor = ORANGE_COLOR
            })

            firstUpdate = false
        }

        locationManager.requestLocation()
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKindOfClass(MKUserLocation) { return nil }
        
        let annotation = MKAnnotationView(annotation: nil, reuseIdentifier: "BUBBLETHING")
        annotation.image = UIImage(named: "BubblePin")
        return annotation
    }
}
