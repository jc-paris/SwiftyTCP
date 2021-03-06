//
//  SwiftyTCP.swift
//  SwiftyTCP
//
//  Created by Jean-Christophe Paris on 04/10/15.
//  Copyright © 2015 Jean-Christophe Paris. All rights reserved.
//

import Foundation

// Improve by init with data / string / ...
// Request id by subclassing Manager and asking for a custom id
// This behavior should be a custom one by user

public func request(type type: String, method: String, parameters: [String: AnyObject])-> Request
{
    return Manager.sharedInstance.request(type: type, method: method, parameters: parameters)
}

public func request(type type: String, method: String)-> Request
{
    return Manager.sharedInstance.request(type: type, method: method, parameters: [:])
}

public func addHandler(name name: String, handler: NotificationHandler) {
    Manager.sharedInstance.handler(name: name, handler: handler)
}

public func removeHandler(name name: String) {
    Manager.sharedInstance.removeHandler(name: name)
}