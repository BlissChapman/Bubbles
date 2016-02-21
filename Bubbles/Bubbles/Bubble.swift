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
        let record = CKRecord(recordType: "BubbleRecord", recordID: CKRecordID(recordName: NSUUID().UUIDString))
        record["isPopped"] = 0
        record["location"] = location
        record["message"] = message

        let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        operation.perRecordCompletionBlock = completionHandler
        operation.queuePriority = .VeryHigh
        operation.savePolicy = .AllKeys

        Cloud.database.addOperation(operation)
        Cloud.database.saveRecord(record) { (record, error) -> Void in
            print("NORMAL WAY")
        }
    }
}