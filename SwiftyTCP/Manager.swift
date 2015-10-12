//
//  Manager.swift
//  SwiftyTCP
//
//  Created by Jean-Christophe Paris on 04/10/15.
//  Copyright © 2015 Jean-Christophe Paris. All rights reserved.
//

import Foundation

public class Manager {
    public static let sharedInstance = Manager()
    public var debug = false
    var socketStream : SocketStream?
    
    var requestId = 1
    public var delegate = SessionDelegate()
    

    public func openSessionWithHost(host: String, onPort port: Int) {
        socketStream = SocketStream(delegate: delegate)
        socketStream?.debug = debug
        socketStream?.connectToHost(host, withPort: port)
    }
    
    public func request(type type: String, method: String, parameters: [String: AnyObject]) -> Request {
        let tcpRequestId = requestId++
        let tcpRequest = TCPRequest(id: "\(tcpRequestId)", type: type, method: method, args: parameters)
        return request(tcpRequest)
    }
    
    public func request(tcpRequest: TCPRequest) -> Request {
        let request = Request(tcpRequest: tcpRequest)
        delegate[tcpRequest] = request.delegate
        // Should check if SocketStream is open, else fill error with SocketStream not open an complete task
        socketStream?.write()
//        self.complete(tcpRequest)
        return request
    }

    public class SessionDelegate: NSObject, SocketStreamDelegate {
        private var subdelegates: [String: Request.RequestDelegate] = [:]
        private let subdelegateQueue = dispatch_queue_create(nil, DISPATCH_QUEUE_CONCURRENT)
        var timer: NSTimer!
        
        subscript(request: TCPRequest) -> Request.RequestDelegate? {
            get {
                if let requestId = request.requestId {
                    var subdelegate: Request.RequestDelegate?
                    subdelegate = self.subdelegates[requestId]
                    return subdelegate
                }
                return nil
            }
            
            set {
                if let requestId = request.requestId {
                    self.subdelegates[requestId] = newValue
                }
            }
        }

        subscript(requestId: String) -> Request.RequestDelegate? {
            get {
                var subdelegate: Request.RequestDelegate?
                subdelegate = self.subdelegates[requestId]
                return subdelegate
            }
            set {
                self.subdelegates[requestId] = newValue
            }
        }

        public var sessionDidOpen: (Void -> Void)?
        public var sessionDidFailToOpenWithError: (NSError -> Void)?
        public var sessionDidClose: (Void -> Void)?
        
        let timeout: NSTimeInterval = 5

        override init() {
            super.init()
            self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "checkRequests", userInfo: nil, repeats: true)
        }
        
        deinit {
            self.timer.invalidate()
        }
        
        func checkRequests() {
            for (requestId , requestDelegate) in subdelegates {
                if requestDelegate.state == .Running, let time = requestDelegate.time?.timeIntervalSinceNow where time < -(timeout) {
                    self[requestId] = nil
                    requestDelegate.state = .Completed
                    let failureReason = "TCP request has timed out"
                    let error = Error.errorWithCode(.RequestTimedOut, failureReason: failureReason)
                    requestDelegate.didCompleteWithError(error)
                }
            }
        }

        
        // Some delegate called from Socket stream call this blocks
        func didOpenSession() {
            sessionDidOpen?()
        }
        
        func didFailToOpenSessionWithError(error: NSError) {
            sessionDidFailToOpenWithError?(error)
        }
        
        func sessionHasEnded() {
            sessionDidClose?()
        }
        
        func hasSomethingToWrite() -> String? {
            for (_, requestDelegate) in subdelegates {
                if requestDelegate.state == .Waiting {
                    requestDelegate.time = NSDate()
                    requestDelegate.state = .Running
                    return requestDelegate.tcpRequest.toJSON()
                }
            }
            return nil
        }
        
        func didReceiveData(data: NSData) {
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
                if let requestId = json["id"] as? String {
                    if let delegate = self[requestId] {
                        delegate.didReceivedData(data)
                        delegate.didCompleteWithError(nil)
                    }
                    self[requestId] = nil
                }
                else {
                    // Handle notification request
                }
            } catch {
                // Do nothing
            }
            
        }
    }
    
}