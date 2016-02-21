//
//  SquidViewController.swift
//
//
//  Created by Bliss Chapman on 2/21/16.
//
//

import UIKit
import CoreLocation
import SCLAlertView
import MapKit
import CloudKit


class SquidViewController: UIViewController {

    @IBOutlet weak var bubbleBlowingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var map: MKMapView! {
        didSet { map.delegate = self }
    }
    @IBOutlet weak var textViewBubble: UITextView!
    @IBOutlet weak var squidButton: ZFRippleButton!

    private let locationManager = CLLocationManager()
    private var lastUsersLocation: CLLocation?
    private var firstLocationUpdate = true

    private var nearbyPoppableBubbles: [CKRecord]?


    //MARK: View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configureLocationManager()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        configureUI()
    }

    private func configureUI() {
        //configure textViewBubble
        textViewBubble.backgroundColor = PURPLE_COLOR
        textViewBubble.alpha = 0.0
        textViewBubble.layer.masksToBounds = true
        textViewBubble.layer.cornerRadius = 20

        //configure squid button
        squidButtonEnabled(false)
        squidButton.layer.masksToBounds = true
        squidButton.buttonCornerRadius = Float(squidButton.bounds.size.height/2)

        squidButton.rippleBackgroundColor = ORANGE_COLOR
        squidButton.rippleColor = PURPLE_COLOR
        squidButton.rippleOverBounds = false
        squidButton.trackTouchLocation = false
        squidButton.ripplePercent = 1.1
        squidButton.shadowRippleEnable = true

        //set up initial state
        resetBubble(withAnimationDuration: 0)
    }

    private func configureLocationManager() {
        //configure location manager
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
    ///updates nearbyPoppableBubbles and updates the map
    func updatePoppableBubbles(withCompletion completion: (()->())? = nil) {
        let annotationsToRemove = map.annotations.filter { $0 !== map.userLocation }
        map.removeAnnotations( annotationsToRemove )

        guard let lastUsersLoc = lastUsersLocation else {
            print("last users location not known when reloading map pins")
            return
        }

        Cloud.fetchAllPoppableBubbles(withLocation: lastUsersLoc, andKilometerRadius: 2) { (records, error) -> () in

            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), { () -> Void in
                self.nearbyPoppableBubbles = records

                guard let records = records else { return }

                var allAnnotations = [MKAnnotation]()
                for record in records {
                    if let recordLocation = record["location"] as? CLLocation {
                        let defaultPinAnnotation = MKPointAnnotation()
                        defaultPinAnnotation.coordinate = recordLocation.coordinate
                        allAnnotations.append(defaultPinAnnotation)
                    }
                }

                =>~{
                    self.map.addAnnotations(allAnnotations)
                    completion?()
                }
            })
        }
    }

    func squidButtonEnabled(enabled: Bool) {
        self.squidButton.enabled = enabled
        self.squidButton.backgroundColor = enabled ? ORANGE_COLOR : .grayColor()
    }

    func bubbleTextViewEnabled(enabled: Bool) {
        textViewBubble.editable = enabled
        textViewBubble.alpha = enabled ? 1.0 : 0.0
    }



    @IBAction func squidButtonLongPressed(sender: UILongPressGestureRecognizer) {

        //at this point the user must have a location and they blew their bubble up!
        if sender.state == .Ended {
            //play noises depending on pop or blow!
            if let poppableBubbles = nearbyPoppableBubbles where poppableBubbles.count > 0 {
                popBubble(withRecord: poppableBubbles.first!)
            } else {
                blowNewBubble()
            }
        }
    }

    @IBAction func confirmButtonTapped(sender: UIButton) {
        let newBubble = Bubble(withMessage: textViewBubble.text, andLocation: lastUsersLocation!)
        bubbleBlowingIndicator.startAnimating()
        textViewBubble.editable = false
        cancelButton.enabled = false
        confirmButton.enabled = false
        newBubble.blow({ (record, error) -> Void in
            self.updatePoppableBubbles(withCompletion: { () -> () in

                =>~{
                    self.cancelButton.enabled = true

                    self.textViewBubble.editable = true
                    self.textViewBubble.resignFirstResponder()
                    self.bubbleBlowingIndicator.stopAnimating()

                    guard error == nil else {
                        debugPrint(error)
                        return
                    }

                    //successful blow
                    self.textViewBubble.text = ""
                    //let currentFrame = self.textViewBubble.frame
                    UIView.animateWithDuration(0.5, delay: 0.0, options: .CurveEaseOut, animations: { () -> Void in
                        let animatedNewBubbleRect = CGRect(x: self.textViewBubble.frame.minX + (self.textViewBubble.frame.width / 4), y: -self.textViewBubble.frame.height, width: self.textViewBubble.frame.width / 2, height: self.textViewBubble.frame.height)
                        self.textViewBubble.frame = animatedNewBubbleRect
                        self.cancelButton.transform = CGAffineTransformIdentity
                        self.confirmButton.transform = CGAffineTransformIdentity

                        }, completion: { (completed) -> Void in
                            //self.textViewBubble.frame = currentFrame
                            self.resetBubble(withAnimationDuration: 0)
                    })
                }

            })
        })
    }

    @IBAction func cancelButtonSelected(sender: UIButton) {
        self.resetBubble(withAnimationDuration: 3)
    }


    //MARK: Bubble Animation
    private func blowNewBubble() {
        print("DECIDED TO BLOW NEW BUBBLE")
        squidButtonEnabled(false)
        animateInTextViewBubble()
    }

    private func popBubble(withRecord record: CKRecord) {
        print("DECIDED TO POP BUBBLE")
        Cloud.popBubble(record, completionHandler: { (record, error) -> () in
            guard error == nil else {
                debugPrint(error)
                return
            }

            let message = record!["message"] as! String
            print("POPPING BUBBLE WITH MESSAGE: \(message)")

            =>~{
                self.updatePoppableBubbles(withCompletion: { () -> () in

                    self.animateInTextViewBubble(withMessage: message, withCancelButton: true, withConfirmButton: false)
                })
            }
        })
    }

    private func resetBubble(withAnimationDuration duration: NSTimeInterval) {
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(duration)
        UIView.setAnimationCurve(.EaseInOut)

        let scale = CGAffineTransformMakeScale(0.001, 0.001)
        let translation = CGAffineTransformMakeTranslation(0, squidButton.frame.minY - textViewBubble.frame.maxY)
        textViewBubble.transform = CGAffineTransformConcat(scale, translation)

        confirmButton.transform = CGAffineTransformMakeTranslation(view.frame.width, 0)
        cancelButton.transform = CGAffineTransformMakeTranslation(-view.frame.width, 0)

        UIView.commitAnimations()


        textViewBubble.text = ""
        textViewBubble.editable = false
        textViewBubble.resignFirstResponder()

        squidButtonEnabled(true)
    }

    private func animateInTextViewBubble(withMessage message: String? = nil, withCancelButton cancel: Bool = true, withConfirmButton confirm: Bool = true) {

        textViewBubble.text = (message != nil) ? message : ""
        textViewBubble.editable = confirm

        UIView.animateWithDuration(3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: [.CurveEaseOut, .AllowUserInteraction], animations: { () -> Void in

            self.textViewBubble.alpha = 0.75
            self.textViewBubble.transform = CGAffineTransformIdentity

            }) { (completed) -> Void in

                self.textViewBubble.becomeFirstResponder()
        }

        UIView.animateWithDuration(1, delay: 1.5, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.CurveEaseOut], animations: { () -> Void in

            if cancel {
            self.cancelButton.transform = CGAffineTransformIdentity
            }
            if confirm {
            self.confirmButton.transform = CGAffineTransformIdentity
            }

            }) { (completion) -> Void in
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
        let adjustedRegion = map.regionThatFits(viewRegion)
        map.setRegion(adjustedRegion, animated: true)
        map.showsUserLocation = true
    }
}

extension SquidViewController: CLLocationManagerDelegate {
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
        locationManager.requestLocation()
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastUsersLocation = locations.last!
        zoomMap(withLocation: locations.last!)

        if firstLocationUpdate {
            updatePoppableBubbles(withCompletion: { _ in
                self.squidButtonEnabled(true)
            })
            
            firstLocationUpdate = false
        }
        
        locationManager.requestLocation()
    }
}

extension SquidViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKindOfClass(MKUserLocation) { return nil }
        
        let annotation = MKAnnotationView(annotation: nil, reuseIdentifier: "BUBBLETHING")
        annotation.image = UIImage(named: "BubblePin")
        return annotation
    }
}