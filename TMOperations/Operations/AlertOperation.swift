/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows how to present an alert as part of an operation.
*/

import UIKit

open class AlertOperation: TMOperation {
    // MARK: Properties

    private let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
    private let presentationContext: UIViewController?
    
    public var title: String? {
        get {
            return alertController.title
        }

        set {
            alertController.title = newValue
            name = newValue
        }
    }
    
    public var message: String? {
        get {
            return alertController.message
        }
        
        set {
            alertController.message = newValue
        }
    }
    
    // MARK: Initialization
    
    public init(presentationContext: UIViewController? = nil) {
        self.presentationContext = presentationContext ?? UIApplication.shared.keyWindow?.rootViewController

        super.init()
        
        addCondition(condition: AlertPresentation())
        
        /*
            This operation modifies the view controller hierarchy.
            Doing this while other such operations are executing can lead to
            inconsistencies in UIKit. So, let's make them mutally exclusive.
        */
        addCondition(condition: MutuallyExclusive<UIViewController>())
    }
    
    public func addAction(title: String, style: UIAlertAction.Style = .default, handler: @escaping (AlertOperation) -> Void = { _ in }) {
        let action = UIAlertAction(title: title, style: style) { [weak self] _ in
            if let strongSelf = self {
                handler(strongSelf)
            }

            self?.finish()
        }
        
        alertController.addAction(action)
    }
    
    override open func execute() {
        guard let presentationContext = presentationContext else {
            finish()

            return
        }

        DispatchQueue.main.async {
            if self.alertController.actions.isEmpty {
                self.addAction(title: "OK")
            }
            
            presentationContext.present(self.alertController, animated: true, completion: nil)
        }
    }
}
