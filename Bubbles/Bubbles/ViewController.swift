//
//  ViewController.swift
//  Bubbles
//
//  Created by Bliss Chapman on 2/19/16.
//  Copyright © 2016 Bliss Chapman. All rights reserved.
//

import UIKit
import CloudKit

class ViewController: UIViewController {

    @IBOutlet weak var fetchButtonResultLabel: UILabel!
    @IBOutlet weak var fetchButtonLoadingSymbol: UIActivityIndicatorView!
    @IBOutlet weak var fetchButton: UIButton!
    @IBOutlet weak var blowButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var bubbleBlowing: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func fetchTapped(sender: AnyObject) {
        fetchButton.setTitle("", forState: .Normal)
        fetchButtonLoadingSymbol.startAnimating()
        fetchButton.enabled = false

        Cloud.fetchAllBubbles { (records, error) -> () in
            =>~{
                self.fetchButton.enabled = true
                self.fetchButtonLoadingSymbol.stopAnimating()
                self.fetchButton.setTitle("Fetch All Bubbles", forState: .Normal)

                guard error == nil else {
                    self.fetchButtonResultLabel.text = error?.localizedDescription
                    return
                }
                self.fetchButtonResultLabel.text = "There are \(records!.count) bubbles!"

                print(records)
            }
        }
    }

    @IBAction func blowTapped(sender: AnyObject) {
        let newBubble = Bubble(withMessage: "Test Bubble", andLocation: CLLocation(latitude: 25, longitude: 27))
        blowButton.setTitle("", forState: .Normal)
        bubbleBlowing.startAnimating()
        blowButton.enabled = false

        newBubble.blow { (record, error) -> Void in
            =>~{
                self.blowButton.enabled = true
                self.bubbleBlowing.stopAnimating()
                self.blowButton.setTitle("Blow it!", forState: .Normal)

                guard error == nil else {
                    self.messageLabel.text = error?.localizedDescription
                    return
                }
                self.messageLabel.text = record?.description
            }
        }
    }
}

//FETCH RECORDS BY LOCATION
/*
// Get the public database object
CKDatabase *publicDatabase = [[CKContainer defaultContainer] publicCloudDatabase];

// Create a predicate to retrieve records within a radius of the user's location
CLLocation *fixedLocation = [[CLLocation alloc] initWithLatitude:37.7749300 longitude:-122.4194200];
CGFloat radius = 100000; // meters
NSPredicate *predicate = [NSPredicate predicateWithFormat:@"distanceToLocation:fromLocation:(location, %@) < %f", fixedLocation, radius];

// Create a query using the predicate
CKQuery *query = [[CKQuery alloc] initWithRecordType:@"Artwork" predicate:predicate];

// Execute the query
[publicDatabase performQuery:query inZoneWithID:nil completionHandler:^(NSArray *results, NSError *error) {
if (error) {
// Error handling for failed fetch from public database
}
else {
// Display the fetched records
}
}];*/