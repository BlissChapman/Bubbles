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


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.


        let newBubble = Bubble(withMessage: "HI Kajetan", andLocation: CLLocation(latitude: 50, longitude: 50))
        newBubble.blow { (record, error) -> Void in
            print(record)
            debugPrint(error)
        }

        //let greatID = CKRecordID(recordName: "Siebel 210")
        //let place = CKRecord(recordType: "Place", recordID: greatID)

//        let zoneID = CKRecordZoneID(
//        let record = CKRecord(recordType: p, zoneID: <#T##CKRecordZoneID#>)
//        publicDB.saveRecord(place) { (record, error) -> Void in
//            guard error == nil else {
//                debugPrint(error)
//                return
//            }
//
//            print(record)
////            if let retryAfterValue = error.userInfo[CKErrorRetryAfterKey] as? NSTimeInterval {
////                let retryAfterDate = NSDate(timeIntervalSinceNow: retryAfterValue)
////                // ...
////            }
//        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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