/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows an example of implementing the OperationCondition protocol.
*/

#if os(iOS)

import UIKit
    
private let RemoteNotificationQueue = UKOperationQueue()

extension Notification.Name {
    fileprivate static let remoteNotification = Notification.Name(rawValue: "RemoteNotificationPermissionNotification")
}

private enum RemoteRegistrationResult {
    case Token(Data)
    case Error(Error)
}

/// A condition for verifying that the app has the ability to receive push notifications.
struct RemoteNotificationCondition: OperationCondition {
    static let name = "RemoteNotification"
    static let isMutuallyExclusive = false
    
    static func didReceiveNotificationToken(token: Data) {
        NotificationCenter.default.post(name: .remoteNotification, object: nil, userInfo: ["token": token])
    }
    
    static func didFailToRegister(error: Error) {
        NotificationCenter.default.post(name: .remoteNotification, object: nil, userInfo: ["error": error])
    }
    
    let application: UIApplication
    
    init(application: UIApplication) {
        self.application = application
    }
    
    func dependencyForOperation(operation: Operation) -> Operation? {
        return RemoteNotificationPermissionOperation(application: application, handler: { _ in })
    }
    
    func evaluateForOperation(operation: Operation, completion: @escaping (OperationConditionResult) -> Void) {
        /*
            Since evaluation requires executing an operation, use a private operation
            queue.
        */
        RemoteNotificationQueue.addOperation(RemoteNotificationPermissionOperation(application: application) { result in
            switch result {
                case .Token(_):
                    completion(.Satisfied)

                case .Error(let underlyingError):
                    let error = NSError(code: .ConditionFailed, userInfo: [
                        OperationConditionKey: type(of: self).name,
                        NSUnderlyingErrorKey: underlyingError
                    ])

                    completion(.Failed(error))
            }
        })
    }
}

/**
    A private `Operation` to request a push notification token from the `UIApplication`.
    
    - note: This operation is used for *both* the generated dependency **and**
        condition evaluation, since there is no "easy" way to retrieve the push
        notification token other than to ask for it.

    - note: This operation requires you to call either `RemoteNotificationCondition.didReceiveNotificationToken(_:)` or
        `RemoteNotificationCondition.didFailToRegister(_:)` in the appropriate
        `UIApplicationDelegate` method, as shown in the `AppDelegate.swift` file.
*/
private class RemoteNotificationPermissionOperation: UKOperation {
    let application: UIApplication
    private let handler: (RemoteRegistrationResult) -> Void
    
    fileprivate init(application: UIApplication, handler: @escaping (RemoteRegistrationResult) -> Void) {
        self.application = application
        self.handler = handler

        super.init()
        
        /*
            This operation cannot run at the same time as any other remote notification
            permission operation.
        */
        addCondition(condition: MutuallyExclusive<RemoteNotificationPermissionOperation>())
    }
    
    override func execute() {
        DispatchQueue.main.async {
            let notificationCenter = NotificationCenter.default
            
            notificationCenter.addObserver(self, selector: #selector(self.didReceiveResponse(notification:)), name: .remoteNotification, object: nil)
            
            self.application.registerForRemoteNotifications()
        }
    }
    
    @objc func didReceiveResponse(notification: NSNotification) {
        NotificationCenter.default.removeObserver(self)
        
        let userInfo = notification.userInfo

        if let token = userInfo?["token"] as? Data {
            handler(.Token(token))
        }
        else if let error = userInfo?["error"] as? Error {
            handler(.Error(error))
        }
        else {
            fatalError("Received a notification without a token and without an error.")
        }

        finish()
    }
}
    
#endif
