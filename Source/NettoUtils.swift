//
//  NettoUtils.swift
//  Netto
//
//  Created by Puran Singh on 9/22/16.
//  Copyright © 2016 Huma Labs. All rights reserved.
//

import Foundation


func isNil(obj:AnyObject?) -> Bool {
    return (obj == nil || obj is NSNull)
}

func isNotNil(obj:AnyObject?) -> Bool {
    return (obj != nil && !(obj is NSNull))
}

func isEmpty(obj:AnyObject?) -> Bool {
    return !notEmpty(obj)
}

func notEmpty(obj:AnyObject?) -> Bool {
    var result = (obj != nil && !(obj is NSNull))

    if let str = obj as? String {
        result = (str != "")
    }
    return result
}