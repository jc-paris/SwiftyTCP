# SwiftyTCP

## Requirements

- Swift 2.0
- iOS 7/8 ?

## Usage

### 1. Connect on server IP:port
```swift
Manager.sharedInstance.openSessionWithHost(game.ip, onPort: game.port)
```

Optionnally, you may want to set a couple of configuration before:
```swift
Manager.sharedInstance.delegate.sessionDidOpen = nil // (Void) -> Void
Manager.sharedInstance.delegate.sessionDidFailToOpenWithError = nil // (NSError) -> Void
Manager.sharedInstance.delegate.sessionDidClose = nil // (Void) -> Void
```
You can also remove debug mode
```swift
Manager.sharedInstance.debug = false
```

### 2. Send pakckage
Use one of the following:
```swift
public func request(type type: String, method: String, parameters: [String: AnyObject])-> Request
public func request(type type: String, method: String)-> Request
```

Example:
```swift
request(type:"player", method:"join", parameters: parameters).debug()
.validate()
.responseJSON { _, result in
  switch result {
    case .Success(let data):
      let json = SwiftyJSON.JSON(data)
      // do your work
    case .Failure(_, let error):
      return completion(nil, error as NSError)
    }
}
```

### 3. Handle server notification
When you want to subscribe to notification (package automatically send by server
```swift
public func addHandler(name name: String, handler: NotificationHandler)
public func removeHandler(name name: String)

// NotificationHandler is a closure that takes an NSData and return a boolean.
// The return represent if the notification has been handle or not (for not, it only provoc silent wanring)
public typealias NotificationHandler = (NSData -> Bool)
```

```swift
addHandler(name: "game:start", handler: { data in
  // Do some work
  return true
})
```

### 4. Close connection
```swift
Manager.sharedInstance.closeSession()
```
