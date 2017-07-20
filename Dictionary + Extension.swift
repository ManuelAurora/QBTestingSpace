//
//  Dictionary + Extension.swift
//  CoreKPI
//
//  Created by Мануэль on 21.02.17.
//  Copyright © 2017 SmiChrisSoft. All rights reserved.
//

import Foundation

extension Dictionary
{    
    func stringFromHttpParameters() -> String {
        let parameterArray = self.map { (key, value) -> String in
            
            var percentEscapedKey = ""
            
            if let key = key as? String {
                percentEscapedKey = key.addingPercentEncodingForURLQueryValue()!
            }
            else if let key = key as? QBQueryParameterKeys {
                percentEscapedKey = key.rawValue
            }          
        
            let percentEscapedValue = (value as! String).addingPercentEncodingForURLQueryValue()!
            return "\(percentEscapedKey)=\(percentEscapedValue)"
        }
        
        return parameterArray.joined(separator: "&")
    }
}
