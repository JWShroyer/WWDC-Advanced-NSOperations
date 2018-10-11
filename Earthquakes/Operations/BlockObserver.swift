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
struct BlockObserver: OperationObserver {
    // MARK: Properties
    
    private let startHandler: ((Operation) -> Void)?
    private let produceHandler: ((Operation, Operation) -> Void)?
    private let finishHandler: ((Operation, [Error]) -> Void)?
    
    init(startHandler: ((Operation) -> Void)? = nil, produceHandler: ((Operation, Operation) -> Void)? = nil, finishHandler: ((Operation, [Error]) -> Void)? = nil) {
        self.startHandler = startHandler
        self.produceHandler = produceHandler
        self.finishHandler = finishHandler
    }
    
    // MARK: OperationObserver
    
    func operationDidStart(operation: UKOperation) {
        startHandler?(operation)
    }
    
    func operation(operation: UKOperation, didProduceOperation newOperation: Operation) {
        produceHandler?(operation, newOperation)
    }
    
    func operationDidFinish(operation: UKOperation, errors: [Error]) {
        finishHandler?(operation, errors)
    }
}
