/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows an example of implementing the OperationCondition protocol.
*/

import EventKit

/// A condition for verifying access to the user's calendar.
struct CalendarCondition: OperationCondition {
    
    static let name = "Calendar"
    static let entityTypeKey = "EKEntityType"
    static let isMutuallyExclusive = false
    
    let entityType: EKEntityType
    
    init(entityType: EKEntityType) {
        self.entityType = entityType
    }
    
    func dependencyForOperation(operation: Operation) -> Operation? {
        return CalendarPermissionOperation(entityType: entityType)
    }
    
    func evaluateForOperation(operation: Operation, completion: (OperationConditionResult) -> Void) {
        switch EKEventStore.authorizationStatus(for: entityType) {
        case .authorized:
                completion(.Satisfied)

            default:
                // We are not authorized to access entities of this type.
                let typeOfSelf = type(of: self)
                
                let error = NSError(code: .ConditionFailed, userInfo: [
                    OperationConditionKey: typeOfSelf.name,
                    typeOfSelf.entityTypeKey: entityType.rawValue
                ])
                
                completion(.Failed(error))
        }
    }
}

/**
    `EKEventStore` takes a while to initialize, so we should create
    one and then keep it around for future use, instead of creating
    a new one every time a `CalendarPermissionOperation` runs.
*/
private let SharedEventStore = EKEventStore()

/**
    A private `Operation` that will request access to the user's Calendar/Reminders,
    if it has not already been granted.
*/
private class CalendarPermissionOperation: UKOperation {
    let entityType: EKEntityType
    
    init(entityType: EKEntityType) {
        self.entityType = entityType
        super.init()
        addCondition(condition: AlertPresentation())
    }
    
    override func execute() {
        let status = EKEventStore.authorizationStatus(for: entityType)
        
        switch status {
        case .notDetermined:
            DispatchQueue.main.async {
                SharedEventStore.requestAccess(to: self.entityType) { granted, error in
                    self.finish()
                }
            }

            default:
                finish()
        }
    }
    
}
