/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows an example of implementing the OperationCondition protocol.
*/

#if os(iOS)
    
import HealthKit
import UIKit

/**
    A condition to indicate an `Operation` requires access to the user's health
    data.
*/
struct HealthCondition: OperationCondition {
    static let name = "Health"
    static let healthDataAvailable = "HealthDataAvailable"
    static let unauthorizedShareTypesKey = "UnauthorizedShareTypes"
    static let isMutuallyExclusive = false
    
    let shareTypes: Set<HKSampleType>
    let readTypes: Set<HKSampleType>
    
    /**
        The designated initializer.
        
        - parameter typesToWrite: An array of `HKSampleType` objects, indicating
            the kinds of data you wish to save to HealthKit.

        - parameter typesToRead: An array of `HKSampleType` objects, indicating
            the kinds of data you wish to read from HealthKit.
    */
    init(typesToWrite: Set<HKSampleType>, typesToRead: Set<HKSampleType>) {
        shareTypes = typesToWrite
        readTypes = typesToRead
    }
    
    func dependencyForOperation(operation: Operation) -> Operation? {
        guard HKHealthStore.isHealthDataAvailable() else {
            return nil
        }
        
        guard !shareTypes.isEmpty || !readTypes.isEmpty else {
            return nil
        }

        return HealthPermissionOperation(shareTypes: shareTypes, readTypes: readTypes)
    }
    
    func evaluateForOperation(operation: Operation, completion: (OperationConditionResult) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            failed(unauthorizedShareTypes: shareTypes, completion: completion)
            return
        }

        let store = HKHealthStore()
        /*
            Note that we cannot check to see if access to the "typesToRead"
            has been granted or not, as that is sensitive data. For example,
            a person with diabetes may choose to not allow access to Blood Glucose
            data, and the fact that this request has denied is itself an indicator
            that the user may have diabetes.
            
            Thus, we can only check to see if we've been given permission to
            write data to HealthKit.
        */
        let unauthorizedShareTypes = shareTypes.filter { shareType in
            return store.authorizationStatus(for: shareType) != .sharingAuthorized
        }

        if !unauthorizedShareTypes.isEmpty {
            failed(unauthorizedShareTypes: Set(unauthorizedShareTypes), completion: completion)
        }
        else {
            completion(.satisfied)
        }
    }
    
    // Break this out in to its own method so we don't clutter up the evaluate... method.
    private func failed(unauthorizedShareTypes: Set<HKSampleType>, completion: (OperationConditionResult) -> Void) {
        
        let typeOfSelf = type(of: self)
        
        let error = NSError(code: .conditionFailed, userInfo: [
            OperationConditionKey: typeOfSelf.name,
            typeOfSelf.healthDataAvailable: HKHealthStore.isHealthDataAvailable(),
            typeOfSelf.unauthorizedShareTypesKey: unauthorizedShareTypes
        ])

        completion(.failed(error))
    }
}

/**
    A private `Operation` that will request access to the user's health data, if
    it has not already been granted.
*/
private class HealthPermissionOperation: UKOperation {
    let shareTypes: Set<HKSampleType>
    let readTypes: Set<HKSampleType>
    
    init(shareTypes: Set<HKSampleType>, readTypes: Set<HKSampleType>) {
        self.shareTypes = shareTypes
        self.readTypes = readTypes
        
        super.init()

        addCondition(condition: MutuallyExclusive<HealthPermissionOperation>())
        addCondition(condition: MutuallyExclusive<UIViewController>())
        addCondition(condition: AlertPresentation())
    }
    
    override func execute() {
        DispatchQueue.main.async {
            let store = HKHealthStore()
            /*
             This method is smart enough to not re-prompt for access if access
             has already been granted.
             */
            
            store.requestAuthorization(toShare: self.shareTypes, read: self.readTypes) { completed, error in
                self.finish()
            }
        }
    }
    
}
    
#endif
