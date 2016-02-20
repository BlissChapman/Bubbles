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
}