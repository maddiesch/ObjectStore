//
//  ObjectManager.swift
//  
//
//  Created by Maddie Schipper on 2/27/21.
//

import Foundation
import CoreData
import Combine

public final class ObjectManager {
    internal let container: NSPersistentContainer
    
    public var viewContext: NSManagedObjectContext {
        return self.container.viewContext
    }
    
    public init(name: String, managedObjectModel: NSManagedObjectModel) {
        let container = NSPersistentContainer(name: name, managedObjectModel: managedObjectModel)
        
        self.container = container
    }
    
    public func prepare(withPersistentStoreDescriptions descriptions: Array<NSPersistentStoreDescription>) {
        self.container.persistentStoreDescriptions = descriptions
    }
    
    public func loadStores(timeout: DispatchTime? = nil) throws {
        let waitGroup = DispatchGroup()
        
        for _ in (0..<self.container.persistentStoreDescriptions.count) {
            waitGroup.enter()
        }
        
        let errorQueue = DispatchQueue(label: "dev.schipper.LoadErrorQueue")
        var errors = Array<(NSPersistentStoreDescription, Error)>()
        
        self.container.loadPersistentStores { (desc, err) in
            defer { waitGroup.leave() }
            
            OMLog.trace("Loaded Persistent Store <\(desc.type)>")
            
            if let error = err {
                errorQueue.sync {
                    errors.append((desc, error))
                }
            }
        }
        
        guard waitGroup.wait(timeout: timeout ?? .now() + .milliseconds(250)) == .success else {
            throw ObjectManagerError.timeout
        }
        
        OMLog.trace("ObjectManager Loaded Stores with \(errors.count, privacy: .public) errors")
        
        guard errors.count == 0 else {
            throw ObjectManagerLoadError(errors: errors)
        }
    }
}

public struct ObjectManagerLoadError : Error {
    public let errors: Array<(NSPersistentStoreDescription, Error)>
}

public enum ObjectManagerError : Error {
    case timeout
}

extension ObjectManager {
    public func prepareWithInMemoryStore() {
        let desc = NSPersistentStoreDescription()
        desc.type = NSInMemoryStoreType
        
        self.prepare(withPersistentStoreDescriptions: [desc])
    }
}
