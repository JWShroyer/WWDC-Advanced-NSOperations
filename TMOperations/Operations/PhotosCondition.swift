/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows an example of implementing the OperationCondition protocol.
*/

#if os(iOS)

import Photos

/// A condition for verifying access to the user's Photos library.
public struct PhotosCondition: OperationCondition {
    
    public static let name = "Photos"
    public static let isMutuallyExclusive = false
    
    public init() { }
    
    public func dependencyForOperation(operation: Operation) -> Operation? {
        return PhotosPermissionOperation()
    }
    
    public func evaluateForOperation(operation: Operation, completion: (OperationConditionResult) -> Void) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
                completion(.satisfied)

            default:
                let error = NSError(code: .conditionFailed, userInfo: [
                    OperationConditionKey: type(of: self).name
                ])

                completion(.failed(error))
        }
    }
}

/**
    A private `Operation` that will request access to the user's Photos, if it
    has not already been granted.
*/
private class PhotosPermissionOperation: TMOperation {
    override init() {
        super.init()

        addCondition(condition: AlertPresentation())
    }
    
    override func execute() {
        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined:
            DispatchQueue.main.async {
                PHPhotoLibrary.requestAuthorization { status in
                    self.finish()
                }
            }
            
            default:
                finish()
        }
    }
    
}

#endif
