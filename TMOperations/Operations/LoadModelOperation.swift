/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file contains the code to create the Core Data stack.
*/

import CoreData

/**
    An `Operation` subclass that loads the Core Data stack. If this operation fails,
    it will produce an `AlertOperation` that will offer to retry the operation.
*/
open class LoadModelOperation: TMOperation {
    // MARK: Properties

    let loadHandler: (NSManagedObjectContext) -> Void
    let databaseName: String
    
    // MARK: Initialization
    
    public init(databaseName: String, loadHandler: @escaping (NSManagedObjectContext) -> Void) {
        self.loadHandler = loadHandler
        self.databaseName = databaseName
        
        super.init()
        
        // We only want one of these going at a time.
        addCondition(condition: MutuallyExclusive<LoadModelOperation>())
    }
    
    override open func execute() {
        /*
            We're not going to handle catching the error here, because if we can't
            get the Caches directory, then your entire sandbox is broken and
            there's nothing we can possibly do to fix it.
        */
        let cachesFolder = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let storeURL = cachesFolder.appendingPathComponent(self.databaseName).appendingPathExtension("sqlite")
        
        /*
            Force unwrap this model, because this would only fail if we haven't
            included the xcdatamodel in our app resources. If we forgot that step,
            we deserve to crash. Plus, there's really no easy way to recover from
            a missing model without reconstructing it programmatically
        */
        let model = NSManagedObjectModel.mergedModel(from: nil)!

        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = persistentStoreCoordinator
        
        var error = createStore(persistentStoreCoordinator: persistentStoreCoordinator, atURL: storeURL)

        if persistentStoreCoordinator.persistentStores.isEmpty {
            /*
                Our persistent store does not contain irreplaceable data (which
                is why it's in the Caches folder). If we fail to add it, we can
                delete it and try again.
            */
            destroyStore(persistentStoreCoordinator: persistentStoreCoordinator, atURL: storeURL)
            error = createStore(persistentStoreCoordinator: persistentStoreCoordinator, atURL: storeURL)
        }
        
        if persistentStoreCoordinator.persistentStores.isEmpty {
            print("Error creating SQLite store: \(error!).")
            print("Falling back to `.InMemory` store.")
            error = createStore(persistentStoreCoordinator: persistentStoreCoordinator, atURL: nil, type: NSInMemoryStoreType)
        }
        
        if !persistentStoreCoordinator.persistentStores.isEmpty {
            loadHandler(context)
            error = nil
        }
        
        finishWithError(error: error)
    }
    
    private func createStore(persistentStoreCoordinator: NSPersistentStoreCoordinator, atURL URL: URL?, type: String = NSSQLiteStoreType) -> NSError? {
        var error: NSError?
        do {
            let _ = try persistentStoreCoordinator.addPersistentStore(ofType: type, configurationName: nil, at: URL, options: nil)
        }
        catch let storeError as NSError {
            error = storeError
        }
        
        return error
    }
    
    private func destroyStore(persistentStoreCoordinator: NSPersistentStoreCoordinator, atURL URL: URL, type: String = NSSQLiteStoreType) {
        do {
            let _ = try persistentStoreCoordinator.destroyPersistentStore(at: URL, ofType: type, options: nil)
        }
        catch { }
    }
    
    override open func finished(errors: [Error]) {
        guard let firstError = errors.first, userInitiated else { return }

        /*
            We failed to load the model on a user initiated operation try and present
            an error.
        */
        
        let alert = AlertOperation()

        alert.title = "Unable to load database"
        
        alert.message = "An error occurred while loading the database. \(firstError.localizedDescription). Please try again later."
        
        // No custom action for this button.
        alert.addAction(title: "Retry Later", style: .cancel)
        
        // Declare this as a local variable to avoid capturing self in the closure below.
        let handler = loadHandler
        
        /*
            For this operation, the `loadHandler` is only ever invoked if there are
            no errors, so if we get to this point we know that it was not executed.
            This means that we can offer to the user to try loading the model again,
            simply by creating a new copy of the operation and giving it the same
            loadHandler.
        */
        alert.addAction(title: "Retry Now") { [weak self] alertOperation in
            guard let strongSelf = self else { return }
            let retryOperation = LoadModelOperation(databaseName: strongSelf.databaseName, loadHandler: handler)

            retryOperation.userInitiated = true
            
            alertOperation.produceOperation(operation: retryOperation)
        }

        produceOperation(operation: alert)
    }
}
