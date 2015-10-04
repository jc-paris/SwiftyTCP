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

    var socketStream : SocketStream?
    
    var requestId = 1
    var delegate = SessionDelegate()
    

    public func openSessionWithHost(host: String, onPort port: Int) {
        socketStream = SocketStream(delegate: delegate)
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
        // TODO: write request on TCP Stream
        // Should check if SocketStream is open, else fill error with SocketStream not open an complete task
        self.complete(tcpRequest)
        return request
    }

//    -- In case it's needed late

    public class SessionDelegate: SocketStreamDelegate {
        private var subdelegates: [String: Request.RequestDelegate] = [:]
        private let subdelegateQueue = dispatch_queue_create(nil, DISPATCH_QUEUE_CONCURRENT)

        subscript(request: TCPRequest) -> Request.RequestDelegate? {
            get {
                if let requestId = request.requestId {
                    var subdelegate: Request.RequestDelegate?
                    dispatch_sync(subdelegateQueue) {
                        subdelegate = self.subdelegates[requestId]
                    }
                    return subdelegate
                }
                return nil
            }
            
            set {
                dispatch_barrier_async(subdelegateQueue) {
                    if let requestId = request.requestId {
                        self.subdelegates[requestId] = newValue
                    }
                }
            }
        }
        
        var sessionDidOpen: (Void -> Void)?
        var sessionDidFailToOpenWithError: (NSError -> Void)?
        var sessionDidClose: (Void -> Void)?
        
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
    }
    
}

extension Manager { // SocketStream Delegate
    func complete(request: TCPRequest) {
        if let _ = request.requestId { // Check if there is a re
            if let delegate = delegate[request] {
                delegate.complete()
            }
            delegate[request] = nil
        }
        else {
            // Handle notification request
        }
    }
}