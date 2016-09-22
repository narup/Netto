//
//  Strings.swift
//  Netto
//
//  Created by Puran Singh on 9/22/16.
//  Copyright © 2016 Huma Labs. All rights reserved.
//
import Foundation

public extension String {

    var encodeUrl: String {
        return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet(charactersInString: ":/?&=;!@#$()',*"))!
    }

    func contains(find: String) -> Bool{
        return self.rangeOfString(find) != nil
    }

    func localizedString() -> String {
        return NSLocalizedString(self, tableName: nil, bundle: NSBundle.mainBundle(), value: "", comment: self)
    }
}

public class Strings {

    /* Convinience method for doing substring replacement */
    public class func render (str: String, dict: Dictionary<String, String>) -> String {
        var finalString = str
        for (key, value) in dict {
            finalString = finalString.stringByReplacingOccurrencesOfString("{\(key)}", withString: value)
        }
        return finalString
    }
}