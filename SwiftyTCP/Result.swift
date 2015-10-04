//
//  Result.swift
//  SwiftyTCP
//
//  Created by Jean-Christophe Paris on 04/10/15.
//  Copyright © 2015 Jean-Christophe Paris. All rights reserved.
//

import Foundation

public enum Result<Value> {
    case Success(Value)
    case Failure(NSData?, ErrorType)
    
    /// Returns `true` if the result is a success, `false` otherwise.
    public var isSuccess: Bool {
        switch self {
        case .Success:
            return true
        case .Failure:
            return false
        }
    }
    
    /// Returns `true` if the result is a failure, `false` otherwise.
    public var isFailure: Bool {
        return !isSuccess
    }
    
    /// Returns the associated value if the result is a success, `nil` otherwise.
    public var value: Value? {
        switch self {
        case .Success(let value):
            return value
        case .Failure:
            return nil
        }
    }
    
    /// Returns the associated data value if the result is a failure, `nil` otherwise.
    public var data: NSData? {
        switch self {
        case .Success:
            return nil
        case .Failure(let data, _):
            return data
        }
    }
    
    /// Returns the associated error value if the result is a failure, `nil` otherwise.
    public var error: ErrorType? {
        switch self {
        case .Success:
            return nil
        case .Failure(_, let error):
            return error
        }
    }
}

// MARK: - CustomStringConvertible

extension Result: CustomStringConvertible {
    public var description: String {
        switch self {
        case .Success:
            return "SUCCESS"
        case .Failure:
            return "FAILURE"
        }
    }
}

// MARK: - CustomDebugStringConvertible

extension Result: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .Success(let value):
            return "SUCCESS: \(value)"
        case .Failure(let data, let error):
            if let
                data = data,
                utf8Data = NSString(data: data, encoding: NSUTF8StringEncoding)
            {
                return "FAILURE: \(error) \(utf8Data)"
            } else {
                return "FAILURE with Error: \(error)"
            }
        }
    }
}