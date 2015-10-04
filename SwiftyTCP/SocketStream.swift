//
//  SocketStream.swift
//  SwiftyTCP
//
//  Created by Jean-Christophe Paris on 04/10/15.
//  Copyright © 2015 Jean-Christophe Paris. All rights reserved.
//

import Foundation

class Utility {
    class func toByteArray<T>(var value: T) -> [UInt8] {
        return withUnsafePointer(&value) {
            Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(T)))
        }
    }
    
    class func fromByteArray<T>(value: [UInt8], _: T.Type) -> T {
        return value.withUnsafeBufferPointer {
            return UnsafePointer<T>($0.baseAddress).memory
        }
    }
}

protocol SocketStreamDelegate {
    func didOpenSession()
    func didFailToOpenSessionWithError(error: NSError)
    func sessionHasEnded()
}

class SocketStream: NSObject {
    var inputStream: NSInputStream?
    var outputStream: NSOutputStream?
    var streamsOpened = false
    
    var delegate: SocketStreamDelegate
    
    init(delegate: SocketStreamDelegate) {
        self.delegate = delegate
    }
    
    deinit {
        inputStream?.close()
        outputStream?.close()
    }
    
    func connectToHost(host: String, withPort port: Int) {
        
        autoreleasepool {
            NSStream.getStreamsToHostWithName(host, port: port, inputStream: &inputStream, outputStream: &outputStream)
        }
        
        
        inputStream?.delegate = self
        inputStream?.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        inputStream?.open()
        
        outputStream?.delegate = self
        outputStream?.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        outputStream?.open()
    }
}

extension SocketStream: NSStreamDelegate {
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        switch eventCode {
        case NSStreamEvent.OpenCompleted:
            if inputStream?.streamStatus == .Open && outputStream?.streamStatus == .Open {
                print("Socket: OpenCompleted (connected)")
                streamsOpened = true
                self.delegate.didOpenSession()
            }
        case NSStreamEvent.ErrorOccurred:
            print("Socket: ErrorOccurred (\(aStream.streamError?.localizedDescription))")
            if streamsOpened == false {
                self.delegate.didFailToOpenSessionWithError(aStream.streamError!)
            }
        case NSStreamEvent.EndEncountered:
            print("Socket: EndEncountered (disconnected)")
            self.delegate.sessionHasEnded()
        case NSStreamEvent.HasBytesAvailable:
            print("Socket: HasBytesAvailable (read)")
            
            let bufferSize = 4
            var buffer = Array<UInt8>(count: bufferSize, repeatedValue: 0)
            let bytesRead = inputStream?.read(&buffer, maxLength: bufferSize)
            _ = bytesRead
            let size = Int(Utility.fromByteArray(buffer, UInt32.self).bigEndian)
            var buffer2 = Array<UInt8>(count: size, repeatedValue: 0)
            let bytesRead2 = inputStream?.read(&buffer2, maxLength: size)
            _ = bytesRead2
            
            let result = NSString(bytes: buffer2, length: buffer2.count, encoding: NSUTF8StringEncoding)
            print("Socket: Read: \(result)")
            
        case NSStreamEvent.HasSpaceAvailable:
            print("Socket: HasSpaceAvailable (write)")

            break
        default:
            break
        }
    }
}
