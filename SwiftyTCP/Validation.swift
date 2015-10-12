//
//  Validation.swift
//  SwiftyTCP
//
//  Created by Jean-Christophe Paris on 09/10/15.
//  Copyright © 2015 Jean-Christophe Paris. All rights reserved.
//

import Foundation

extension Request {
    
    public enum ValidationResult {
        case Success
        case Failure(ErrorType)
    }
    
    public typealias Validation = (TCPRequest, NSData) -> ValidationResult

    public func validate(validation: Validation) -> Self {
        delegate.queue.addOperationWithBlock {
            if let
                response = self.delegate.data where self.delegate.error == nil,
                case let .Failure(error) = validation(self.request, response)
            {
                self.delegate.error = error
            }
        }
        
        return self
    }

}