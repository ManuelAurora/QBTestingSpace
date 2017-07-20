//
//  String + Extension.swift
//  CoreKPI
//
//  Created by Мануэль on 20.02.17.
//  Copyright © 2017 SmiChrisSoft. All rights reserved.
//

import Foundation

extension String
{
    func addingPercentEncodingForURLQueryValue() -> String? {
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        
        return self.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
    }
}

