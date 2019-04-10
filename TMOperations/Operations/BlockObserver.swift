/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows how to implement the OperationObserver protocol.
*/

import Foundation

/**
    The `BlockObserver` is a way to attach arbitrary blocks to significant events
    in an `Operation`'s lifecycle.
*/
public struct BlockObserver: OperationObserver {
    // MARK: Properties
    
    private let startHandler: ((Operation) -> Void)?
    private let produceHandler: ((Operation, Operation) -> Void)?
    private let finishHandler: ((Operation, [Error]) -> Void)?
    
    public init(startHandler: ((Operation) -> Void)? = nil, produceHandler: ((Operation, Operation) -> Void)? = nil, finishHandler: ((Operation, [Error]) -> Void)? = nil) {
        self.startHandler = startHandler
        self.produceHandler = produceHandler
        self.finishHandler = finishHandler
    }
    
    // MARK: OperationObserver
    
    public func operationDidStart(operation: TMOperation) {
        startHandler?(operation)
    }
    
    public func operation(operation: TMOperation, didProduceOperation newOperation: Operation) {
        produceHandler?(operation, newOperation)
    }
    
    public func operationDidFinish(operation: TMOperation, errors: [Error]) {
        finishHandler?(operation, errors)
    }
}
