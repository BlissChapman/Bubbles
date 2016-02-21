//
//  Utilities.swift
//  Bubbles
//
//  Created by Bliss Chapman on 2/20/16.
//  Copyright © 2016 Bliss Chapman. All rights reserved.
//

import Foundation
import UIKit

prefix operator =>~{ }
/// Run the given closure asynchronously on the main thread.
public prefix func =>~ (closure: Void -> Void) {
    dispatch_async(dispatch_get_main_queue(), closure)
}


let TEAL_COLOR = UIColor(red: 30/255, green: 255/255, blue: 244/255, alpha: 1.0)
let ORANGE_COLOR = UIColor(red: 255/255, green: 148/255, blue: 84/255, alpha: 1.0)
let PURPLE_COLOR = UIColor(red: 199/255, green: 141/255, blue: 232/255, alpha: 1.0)

var CONNECTED_TO_INTERNET: Bool {
get {
    return Reachability.reachabilityForInternetConnection().currentReachabilityStatus().rawValue != NotReachable.rawValue
}
}

func translatedAndScaledTransformUsingViewRect(viewRect: CGRect, fromRect: CGRect) -> CGAffineTransform {
    //    CGSize scales = CGSizeMake(viewRect.size.width/fromRect.size.width, viewRect.size.height/fromRect.size.height);
    //    CGPoint offset = CGPointMake(CGRectGetMidX(viewRect) - CGRectGetMidX(fromRect), CGRectGetMidY(viewRect) - CGRectGetMidY(fromRect));
    //    return CGAffineTransformMake(scales.width, 0, 0, scales.height, offset.x, offset.y);

    let scales = CGSizeMake(viewRect.size.width/fromRect.size.width, viewRect.size.height/fromRect.size.height)
    let offset = CGPointMake(CGRectGetMidX(viewRect) - CGRectGetMidX(fromRect), CGRectGetMidY(viewRect) - CGRectGetMidY(fromRect))
    return CGAffineTransformMake(scales.width, 0, 0, scales.height, offset.x, offset.y)
}
//
//- (CGAffineTransform)translatedAndScaledTransformUsingViewRect:(CGRect)viewRect fromRect:(CGRect)fromRect {
//

//    
//}