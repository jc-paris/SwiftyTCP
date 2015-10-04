//
//  Manager.swift
//  SwiftyTCP
//
//  Created by Jean-Christophe Paris on 04/10/15.
//  Copyright © 2015 Jean-Christophe Paris. All rights reserved.
//

import Foundation

public class Manager {
    static let sharedInstance = Manager()
    
    var requestId = 1
    
    var requests: [String: Request.RequestDelegate] = [:]
    
    // var socketStream : SocketStream

    public func request(type type: String, method: String, parameters: [String: AnyObject]) -> Request {
        let tcpRequestId = requestId++
        let tcpRequest = TCPRequest(id: "\(tcpRequestId)", type: type, method: method, args: parameters)
        return request(tcpRequest)
    }
    
    public func request(tcpRequest: TCPRequest) -> Request {
        let request = Request(tcpRequest: tcpRequest)
        requests[tcpRequest.requestId!] = request.delegate
        // TODO: write request on TCP Stream
        self.complete(tcpRequest)
        return request
    }

//    -- In case it's needed late
//
//    public class SessionDelegate {
//        var sessionDidBegin: (Void -> Void)?
//        var sessionDidFinishWithError: (NSError? -> Void)?
//
//        // Some delegate called from Socket stream call this blocks
//    }
    
}

extension Manager { // SocketStream Delegate
    func complete(request: TCPRequest) {
        if let requestId = request.requestId {
            if let delegate = requests[requestId] {
                delegate.complete()
            }
            requests[requestId] = nil
        }
        else {
            // Handle notification request
        }
    }
}