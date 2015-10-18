//
//  Error.swift
//  SwiftyTCP
//
//  Created by Jean-Christophe Paris on 04/10/15.
//  Copyright © 2015 Jean-Christophe Paris. All rights reserved.
//

import Foundation

/// The `Error` struct provides a convenience for creating custom SwiftyTCP NSErrors.
public struct Error {
    /// The domain used for creating all SwiftyTCP errors.
    public static let Domain = "com.swiftytcp.error"
    
    /// The custom error codes generated by SwiftyTCP.
    public enum Code: Int {
        case InputStreamReadFailed           = -6000
        case OutputStreamWriteFailed         = -6001
        case JSONSerializationFailed         = -6002
        case RequestTimedOut                 = -6003
        case SessionClosed                   = -6004
        case SessionInvalidate               = -6005
    }
    
    public static func errorWithCode(code: Code, failureReason: String) -> NSError {
        return errorWithCode(code.rawValue, failureReason: failureReason)
    }
    
    public static func errorWithCode(code: Int, failureReason: String) -> NSError {
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
        return NSError(domain: Domain, code: code, userInfo: userInfo)
    }

    public static func errorWithCode(code: Int, failureReason: String, localizedDescription: String) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey: localizedDescription, NSLocalizedFailureReasonErrorKey: failureReason]
        return NSError(domain: Domain, code: code, userInfo: userInfo)
    }

}
