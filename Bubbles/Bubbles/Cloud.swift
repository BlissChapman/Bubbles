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

    static func fetchAllBubbles(completion: ([CKRecord]?, NSError?)->()) {
//        NSPredicate *predicate = [NSPredicate predicateWithValue:YES];
//        CKQuery *query = [[CKQuery alloc] initWithRecordType:@"Strings" predicate:predicate];
//
//        [_privateDatabase performQuery:query inZoneWithID:nil completionHandler:^(NSArray *results, NSError *error) {
//
//        for (CKRecord *record in results) {
//        NSLog(@"Contents: %@", [record objectForKey:@"stringArray"]);
//        }
//        
//        }];

        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "BubbleRecord", predicate: predicate)

        database.performQuery(query, inZoneWithID: nil, completionHandler: completion)
    }
}