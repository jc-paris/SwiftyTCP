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

protocol SocketStreamDelegate: class {
    func didOpenSession()
    func didFailToOpenSessionWithError(error: NSError)
    func sessionHasEnded()
    func hasSomethingToWrite() -> String?
    func didReceiveData(data: NSData)
}

class SocketStream: NSObject {
    var debug = false
    var inputStream: NSInputStream?
    var inputDataBuffer = [UInt8]()
    var inputTotalBytesRead: Int = 0
    var inputTotalBytesExpectedToRead: Int = 0

    var outputStream: NSOutputStream?
    var outputDataBuffer = [UInt8]()
    var outputTotalBytesWritten: Int = 0
    var outputTotalBytesExpectedToWrite: Int = 0
    
    var streamsOpened = false
    weak var delegate: SocketStreamDelegate?
    
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

extension SocketStream {
    func write() {
        if outputStream?.hasSpaceAvailable == true {
            if outputDataBuffer.count != 0 {
                let bytesToWrite = outputTotalBytesExpectedToWrite - outputTotalBytesWritten
                let bytesWritten = outputStream!.write(outputDataBuffer, maxLength: bytesToWrite)
                if bytesWritten == -1 {
                    // Handle error
                } else if bytesWritten == 0 {
                    if debug == true {
                        print("Socket: EndEncountered (disconnected)")
                    }
                    self.delegate?.sessionHasEnded()
                } else {
                    outputTotalBytesWritten += bytesWritten
                    if outputTotalBytesExpectedToWrite == outputTotalBytesWritten {
                        let readbleData: [UInt8] = Array(outputDataBuffer[4..<outputDataBuffer.count])
                        let data = NSData(bytes: readbleData, length: outputDataBuffer.count - 4)
                        
                        if debug == true, let string = NSString(bytes: data.bytes, length: data.length, encoding: NSUTF8StringEncoding) as? String {
                            print("## TCP: Write: [\(string)]")
                        }
                        outputTotalBytesExpectedToWrite = 0
                        outputTotalBytesWritten = 0
                        outputDataBuffer = []
                    }
                }
            } else if let string = delegate?.hasSomethingToWrite() where string.characters.count != 0 {
                let size = UInt32(string.characters.count).bigEndian
                outputDataBuffer.appendContentsOf(Utility.toByteArray(size))
                outputDataBuffer.appendContentsOf([UInt8](string.utf8))
                outputTotalBytesExpectedToWrite = outputDataBuffer.count
                self.write()
            }
        }
    }
}

extension SocketStream: NSStreamDelegate {
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        switch eventCode {
        case NSStreamEvent.OpenCompleted:
            if inputStream?.streamStatus == .Open && outputStream?.streamStatus == .Open && streamsOpened == false {
                if debug == true {
                    print("Socket: OpenCompleted (connected)")
                }
                streamsOpened = true
                self.delegate?.didOpenSession()
            }
        case NSStreamEvent.ErrorOccurred:
            if debug == true {
                print("Socket: ErrorOccurred (\(aStream.streamError?.localizedDescription))")
            }
            if streamsOpened == false {
                self.delegate?.didFailToOpenSessionWithError(aStream.streamError!)
            }
        case NSStreamEvent.EndEncountered:
            if debug == true {
                print("Socket: EndEncountered (disconnected)")
            }
            self.delegate?.sessionHasEnded()
        case NSStreamEvent.HasBytesAvailable:
            if debug == true {
                print("Socket: HasBytesAvailable (read)")
            }
            
            if inputDataBuffer.count < sizeof(UInt32.self) {
                let bytesToRead = sizeof(UInt32.self) - inputDataBuffer.count
                var buffer = Array<UInt8>(count: bytesToRead, repeatedValue: 0) // init a empty buffer
                let bytesRead = inputStream!.read(&buffer, maxLength: bytesToRead)
                if bytesRead == -1 {
                    // Handle error
                } else if bytesRead == 0 {
                    if debug == true {
                        print("Socket: EndEncountered (disconnected)")
                    }
                    self.delegate?.sessionHasEnded()
                } else {
                    inputTotalBytesRead += bytesRead
                    inputDataBuffer.appendContentsOf(buffer)
                    if inputTotalBytesRead == sizeof(UInt32.self) {
                        inputTotalBytesExpectedToRead = Int(Utility.fromByteArray(inputDataBuffer, UInt32.self).bigEndian)
                        inputTotalBytesRead = 0
                        inputDataBuffer = []
                    }
                }
            }
            if inputStream?.hasBytesAvailable == true && inputTotalBytesExpectedToRead != 0 {
                let bytesToRead = inputTotalBytesExpectedToRead - inputTotalBytesRead
                var buffer = Array<UInt8>(count: bytesToRead, repeatedValue: 0)
                let bytesRead = inputStream!.read(&buffer, maxLength: bytesToRead)
                if bytesRead == -1 {
                    // Handle error
                } else if bytesRead == 0 {
                    if debug == true {
                        print("Socket: EndEncountered (disconnected)")
                    }
                    self.delegate?.sessionHasEnded()
                } else {
                    inputTotalBytesRead += bytesRead
                    inputDataBuffer.appendContentsOf(buffer)
                    if inputTotalBytesExpectedToRead == inputTotalBytesRead {
                        if debug == true, let string = NSString(bytes: inputDataBuffer, length: inputDataBuffer.count, encoding: NSUTF8StringEncoding) as? String {
                            print("## TCP: Read: [\(string)]")
                        }
                        let data = NSData(bytes: inputDataBuffer, length: inputTotalBytesRead)
                        delegate?.didReceiveData(data)
                        inputDataBuffer = []
                        inputTotalBytesRead = 0
                        inputTotalBytesExpectedToRead = 0
                    }
                }
            }
        case NSStreamEvent.HasSpaceAvailable:
            if debug == true {
                print("Socket: HasSpaceAvailable (write)")
            }
            self.write()
            break
        default:
            break
        }
    }
}
