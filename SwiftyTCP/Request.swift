//
//  Request.swift
//  SwiftyTCP
//
//  Created by Jean-Christophe Paris on 04/10/15.
//  Copyright © 2015 Jean-Christophe Paris. All rights reserved.
//

import Foundation

public class TCPRequest {
    var requestId: String?
    public var type: String!
    public var method: String?
    public var args: [String: AnyObject]?
    
    init(id: String, type: String, method: String, args: [String: AnyObject]) {
        self.requestId = id
        self.type = type
        self.method = method
        self.args = args
    }
    
    func toJSON() -> String {
        var dct: [String: AnyObject] = ["type": type]
        if let method = self.method {
            dct["method"] = method
        }
        if let requestId = self.requestId {
            dct["id"] = requestId
        }
        if let args = self.args {
            dct["args"] = args
        }
        do {
            let data = try NSJSONSerialization.dataWithJSONObject(dct, options: NSJSONWritingOptions())
            return NSString(data: data, encoding: NSUTF8StringEncoding) as! String
        } catch {
            return ""
        }
    }
    
    init?(jsonData: String) {
        let data = jsonData.dataUsingEncoding(NSUTF8StringEncoding)!
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
            if let type = json["type"] as? String {
                self.type = type
                self.method = json["method"] as? String
                self.requestId = json["id"] as? String
                self.args = json["args"] as? [String: AnyObject]
                return
            }
        } catch {
            return nil
        }
    }
}

enum RequestState : Int {
    case Waiting
    case Running
    case Suspended
    case Canceling
    case Completed
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
        
        var state: RequestState = .Waiting
        var data: NSData?
        var error: ErrorType?
        var time: NSDate?
        
        init(request: TCPRequest) {
            self.tcpRequest = request
            self.queue = {
                let operationQueue = NSOperationQueue()
                operationQueue.maxConcurrentOperationCount = 1
                operationQueue.suspended = true
                return operationQueue
            }()
        }
        
        deinit {
            queue.cancelAllOperations()
            queue.suspended = false
        }
        
        func didReceivedData(data: NSData) {
            self.data = data
        }
        
        func didCompleteWithError(error: NSError?) {
            self.error = error
            state = .Completed
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
        if let method = request.method {
            components.append("\(request.type):\(method)")
        } else {
            components.append("\(request.type)")
        }
        
        return components.joinWithSeparator(" ")
    }
}


