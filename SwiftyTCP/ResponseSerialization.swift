//
//  ResponseSerialization.swift
//  SwiftyTCP
//
//  Created by Jean-Christophe Paris on 04/10/15.
//  Copyright © 2015 Jean-Christophe Paris. All rights reserved.
//

import Foundation

// MARK: ResponseSerializer

public protocol ResponseSerializer {
    typealias SerializedObject

    var serializeResponse: (NSData?) -> Result<SerializedObject> { get }
}

public struct GenericResponseSerializer<T>: ResponseSerializer {
    public typealias SerializedObject = T

    public var serializeResponse: (NSData?) -> Result<SerializedObject>

    public init(serializeResponse: (NSData?) -> Result<SerializedObject>) {
        self.serializeResponse = serializeResponse
    }
}

// MARK: - Default

extension Request {
    public func response(
        queue queue: dispatch_queue_t? = nil,
        completionHandler: (TCPRequest?, NSData?, ErrorType?) -> Void)
        -> Self
    {
        self.delegate.queue.addOperationWithBlock {
            dispatch_async(queue ?? dispatch_get_main_queue()) {
                completionHandler(self.delegate.tcpRequest, self.delegate.data, self.delegate.error)
            }
        }

        return self
    }


    public func response<T: ResponseSerializer, V where T.SerializedObject == V>(
        queue queue: dispatch_queue_t? = nil,
        responseSerializer: T,
        completionHandler: (TCPRequest?, Result<V>) -> Void)
        -> Self
    {
        self.delegate.queue.addOperationWithBlock {
            let result: Result<T.SerializedObject> = {
                if let error = self.delegate.error {
                    return .Failure(self.delegate.data, error)
                } else {
                    return responseSerializer.serializeResponse(self.delegate.data)
                }
                }()

            dispatch_async(queue ?? dispatch_get_main_queue()) {
                completionHandler(self.delegate.tcpRequest, result)
            }
        }

        return self
    }
}


// MARK: - JSON

extension Request {
    
    public static func JSONResponseSerializer(
        options options: NSJSONReadingOptions = .AllowFragments)
        -> GenericResponseSerializer<AnyObject>
    {
        return GenericResponseSerializer { data in
            guard let validData = data else {
                let failureReason = "JSON could not be serialized because input data was nil."
                let error = Error.errorWithCode(.JSONSerializationFailed, failureReason: failureReason)
                return .Failure(data, error)
            }
            
            do {
                let JSON = try NSJSONSerialization.JSONObjectWithData(validData, options: options)
                return .Success(JSON)
            } catch {
                return .Failure(data, error as NSError)
            }
        }
    }
    
    public func responseJSON(
        options options: NSJSONReadingOptions = .AllowFragments,
        completionHandler: (TCPRequest?, Result<AnyObject>) -> Void)
        -> Self
    {
        return response(
            responseSerializer: Request.JSONResponseSerializer(options: options),
            completionHandler: completionHandler
        )
    }
}