//
//  NSManagedObjectContext.swift
//  
//
//  Created by Maddie Schipper on 3/7/21.
//

import Foundation
import CoreData
import Combine

extension NSManagedObjectContext {
    public typealias ManagedObjectContextChangedObjects = (inserted: Array<NSManagedObjectID>, updated: Array<NSManagedObjectID>, delted: Array<NSManagedObjectID>)
    
    public var objectsDidChangePublisher: AnyPublisher<ManagedObjectContextChangedObjects, Never> {
        return NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: self).map { (n) -> ManagedObjectContextChangedObjects in
            let inserted = (n.userInfo?[NSInsertedObjectsKey] as? Array<NSManagedObject> ?? []).map { $0.objectID }
            let updated = (n.userInfo?[NSUpdatedObjectsKey] as? Array<NSManagedObject> ?? []).map { $0.objectID }
            let deleted = (n.userInfo?[NSDeletedObjectsKey] as? Array<NSManagedObject> ?? []).map { $0.objectID }
            
            return ManagedObjectContextChangedObjects(inserted, updated, deleted)
        }.eraseToAnyPublisher()
    }
    
    public func objectChangePublisher(objectID: NSManagedObjectID) -> AnyPublisher<NSManagedObjectID, Never> {
        return self.objectsDidChangePublisher.filter { (results) in
            let (inserted, updated, deleted) = results
            
            return inserted.contains(objectID) || updated.contains(objectID) || deleted.contains(objectID)
        }.flatMap { (_) -> AnyPublisher<NSManagedObjectID, Never> in
            return Just(objectID).eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
}
