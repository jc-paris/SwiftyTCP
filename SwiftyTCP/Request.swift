//
//  Request.swift
//  SwiftyTCP
//
//  Created by Jean-Christophe Paris on 04/10/15.
//  Copyright © 2015 Jean-Christophe Paris. All rights reserved.
//

import Foundation

public class TCPRequest {
    let requestId: String?
    public var type: String!
    public var method: String!
    public var args: [String: AnyObject]?
    
    init(id: String, type: String, method: String, args: [String: AnyObject]) {
        self.requestId = id
        self.type = type
        self.method = method
        self.args = args
    }
}

public class Request {
    public var delegate: RequestDelegate
    public var request: TCPRequest { return self.delegate.tcpRequest }
    
    init(tcpRequest: TCPRequest) {
        self.delegate = RequestDelegate(request: tcpRequest)
    }
    
    public class RequestDelegate {
        var tcpRequest: TCPRequest
        public let queue: NSOperationQueue
        
        var data: NSData? { return nil }
        var error: ErrorType?
        
        init(request: TCPRequest) {
            self.tcpRequest = request
            self.queue = {
                let operationQueue = NSOperationQueue()
                operationQueue.maxConcurrentOperationCount = 1
                operationQueue.suspended = true
                
                if #available(OSX 10.10, *) {
                    operationQueue.qualityOfService = NSQualityOfService.Utility
                }
                
                return operationQueue
                }()
        }
        
        deinit {
            queue.cancelAllOperations()
            queue.suspended = false
        }
        
        func complete() {
            queue.suspended = false
        }
    }
}

// MARK: - CustomStringConvertible

extension Request: CustomStringConvertible {

    public var description: String {
        var components: [String] = []
        components.append("TCP")

        if let requestId = request.requestId {
            components.append("[\(requestId)]")
        }
        components.append("\(request.type):\(request.method)")
        
        return components.joinWithSeparator(" ")
    }
}


