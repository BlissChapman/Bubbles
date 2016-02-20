//
//  Bubble.swift
//  Bubbles
//
//  Created by Bliss Chapman on 2/19/16.
//  Copyright © 2016 Bliss Chapman. All rights reserved.
//

import Foundation
import CoreLocation
import CloudKit

final class Bubble {

    var isPopped = false
    var message: String
    var location: CLLocation

    init(withMessage message: String, andLocation location: CLLocation) {
        self.message = message
        self.location = location
    }

    func blow(completionHandler: (CKRecord?, NSError?) -> Void) {
        let record = CKRecord(recordType: "BubbleRecord", recordID: CKRecordID(recordName: "Bubble"))
        record["isPopped"] = false
        record["location"] = location
        record["message"] = message
        Cloud.database.saveRecord(record, completionHandler: completionHandler)
    }
}