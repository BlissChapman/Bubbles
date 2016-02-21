//
//  Cloud.swift
//  Bubbles
//
//  Created by Bliss Chapman on 2/19/16.
//  Copyright © 2016 Bliss Chapman. All rights reserved.
//

import Foundation
import CloudKit

final class Cloud {
    static let database = CKContainer.defaultContainer().publicCloudDatabase

    static func fetchAllPoppableBubbles(withLocation location: CLLocation, andKilometerRadius km: Int, completion: ([CKRecord]?, NSError?)->()) {

        let predicate = NSPredicate(format: "distanceToLocation:fromLocation:(location, %@) < \(km)", location)
        let query = CKQuery(recordType: "BubbleRecord", predicate: predicate)
        query.sortDescriptors = [CKLocationSortDescriptor(key: "location", relativeLocation: location)]
        database.performQuery(query, inZoneWithID: nil) { (records, error) -> Void in

            guard error == nil else {
                completion(nil, error!)
                return
            }

            var notPoppedBubbles = [CKRecord]()
            if let records = records {
                for record in records {
                    if record["isPopped"] as? Int == 0 {
                        notPoppedBubbles.append(record)
                    }
                }
            }

            =>~{ completion(notPoppedBubbles, nil) }
        }
    }

    static func popBubble(record: CKRecord, completionHandler: (CKRecord?, NSError?)->()) {
        record["isPopped"] = 1
        database.saveRecord(record, completionHandler: completionHandler)
    }
}