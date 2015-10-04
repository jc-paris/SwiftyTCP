//
//  SwiftyTCP.swift
//  SwiftyTCP
//
//  Created by Jean-Christophe Paris on 04/10/15.
//  Copyright © 2015 Jean-Christophe Paris. All rights reserved.
//

import Foundation

public func request(type type: String, method: String, parameters: [String: AnyObject])-> Request
{
    return Manager.sharedInstance.request(type: type, method: method, parameters: parameters)
}