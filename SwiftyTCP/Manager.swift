//
//  Manager.swift
//  SwiftyTCP
//
//  Created by Jean-Christophe Paris on 04/10/15.
//  Copyright © 2015 Jean-Christophe Paris. All rights reserved.
//

import Foundation
//import SwiftyJSON

public typealias NotificationHandler = (NSData -> Bool)

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
    
    public func closeSession() {
        socketStream?.close()
        socketStream = nil
        delegate.handlers = [:]
        delegate.empty()
        requestId = 0
    }
    
    public func request(type type: String, method: String, parameters: [String: AnyObject]) -> Request {
        let tcpRequestId = requestId++
        let tcpRequest = TCPRequest(id: "\(tcpRequestId)", type: type, method: method, args: parameters)
        return request(tcpRequest)
    }
    
    public func request(tcpRequest: TCPRequest) -> Request {
        let request = Request(tcpRequest: tcpRequest)
        delegate[tcpRequest] = request.delegate
        if socketStream?.streamsOpened == true {
            socketStream?.write()
        } else {
            let failureReason = "Session is not open"
            let error = Error.errorWithCode(.SessionClosed, failureReason: failureReason)
            request.delegate.didCompleteWithError(error)
        }
        return request
    }

    public func handler(name name: String, handler: NotificationHandler) {
        delegate.handlers[name] = handler
    }

    public func removeHandler(name name: String) {
        delegate.handlers[name] = nil
    }
    
    public class SessionDelegate: NSObject, SocketStreamDelegate {
        private var subdelegates: [String: Request.RequestDelegate] = [:]
        private var handlers: [String: NotificationHandler] = [:]
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
        
        func empty() {
            for (requestId , requestDelegate) in subdelegates {
                self[requestId] = nil
                requestDelegate.state = .Completed
                let failureReason = "Session has been invalidate"
                let error = Error.errorWithCode(.SessionInvalidate, failureReason: failureReason)
                requestDelegate.didCompleteWithError(error)
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
                    if let type = json["type"] as? String, let method = json["method"] as? String {
                        if let handler = handlers["\(type):\(method)"] {
                            let result = handler(data)
                            if result == false {
                                print("SwiftyTCP: Warning: Hanlder failed to handle notification `\(type):\(method)`: \(json)")
                            } else {
                                print("SwiftyTCP: Notifcation: \(NSString(bytes: data.bytes, length: data.length, encoding: NSUTF8StringEncoding) as! String)")
                            }
                        } else {
                            print("!>!>!>!>!> SwiftyTCP: Warning: No handler for `\(type):\(method)`. Should unsubscribe !")
                        }
                    } else {
                        print("SwiftyTCP: Error: Unknown TCP response: \(json)")
                    }
                }
            } catch let error {
                print("SwiftyTCP: Unable to parse JSON: \((error as NSError).localizedDescription)")
                if let string = NSString(bytes: data.bytes, length: data.length, encoding: NSUTF8StringEncoding) as? String {
                    print("JSONString: \(string)")
                }
            }
            
        }
    }
    
}