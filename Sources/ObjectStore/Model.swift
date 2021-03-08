//
//  Model.swift
//  
//
//  Created by Maddie Schipper on 2/27/21.
//

import Foundation
import CoreData

open class Model : NSManagedObject {
    public var localID: UUID! {
        self.value(forKey: "localID") as? UUID
    }
    
    public var createdAt: Date! {
        self.value(forKey: "createdAt") as? Date
    }
    
    public var updatedAt: Date! {
        self.value(forKey: "updatedAt") as? Date
    }
    
    open override func awakeFromInsert() {
        super.awakeFromInsert()
        
        if self.entity.propertiesByName["localID"] != nil {
            self.setValue(UUID(), forKey: "localID")
        }
        
        if self.entity.propertiesByName["createdAt"] != nil {
            self.setValue(Date(), forKey: "createdAt")
        }
        
        if self.entity.propertiesByName["updatedAt"] != nil {
            self.setValue(Date(), forKey: "updatedAt")
        }
    }
    
    open override func willSave() {
        if self.entity.propertiesByName["updatedAt"] != nil {
            self.setPrimitiveValue(Date(), forKey: "updatedAt")
        }
        
        super.willSave()
    }
}

public enum ModelError : Error {
    case notFound(UUID)
}

extension Model {
    public final class func find(_ id: UUID, inContext context: NSManagedObjectContext) throws -> Self {
        let fetchRequest = NSFetchRequest<Self>(entityName: String(describing: Self.self))
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "localID = %@", id as CVarArg)

        let results = try context.fetch(fetchRequest)
        guard let first = results.first else {
            throw ModelError.notFound(id)
        }
        
        return first
    }
    
    public final class func existing(objectWithID objectID: NSManagedObjectID, inContext context: NSManagedObjectContext) throws -> Self {
        return try context.existingObject(with: objectID) as! Self
    }
}

extension Model {
    public static func createEntityDescription(_ block: (NSEntityDescription) -> Void) -> NSEntityDescription {
        let desc = NSEntityDescription()
        desc.name = String(describing: Self.self)
        desc.managedObjectClassName = NSStringFromClass(Self.self)
        
        let localID = desc.addAttribute("localID", .UUIDAttributeType, isOptional: false)
        desc.addAttribute("createdAt", .dateAttributeType, isOptional: false)
        desc.addAttribute("updatedAt", .dateAttributeType, isOptional: false)
        
        desc.index(property: localID)
        desc.uniquenessConstraints.append([localID])
        
        block(desc)
        
        return desc
    }
}

extension NSEntityDescription {
    public typealias ValidationPredicate = (NSPredicate, String)
    
    @discardableResult
    public func addAttribute(_ name: String, _ type: NSAttributeType, isOptional: Bool = true, validators: Array<ValidationPredicate> = [], default defaultValue: Any? = nil) -> NSAttributeDescription {
        let property = NSAttributeDescription()
        property.name = name
        property.attributeType = type
        property.isOptional = isOptional
        property.defaultValue = defaultValue
        
        var predicates = Array<NSPredicate>()
        var messages = Array<String>()
        
        for (predicate, message) in validators {
            predicates.append(predicate)
            messages.append(message)
        }
        
        property.setValidationPredicates(predicates, withValidationWarnings: messages)
        
        self.properties.append(property)
        
        return property
    }
    
    public func unique(_ names: String...) {
        self.uniquenessConstraints.append(names)
    }
    
    public func index(propertyWithName name: String) {
        self.index(propertiesWithNames: [name])
    }
    
    public func index(propertiesWithNames names: String...) {
        self.index(propertiesWithNames: names)
    }
    
    public func index(propertiesWithNames names: Array<String>) {
        let elements = names.map { name -> NSFetchIndexElementDescription in
            guard let property = self.propertiesByName[name] else {
                fatalError("Failed to find a property with the given name: \(name)")
            }
            
            return NSFetchIndexElementDescription(property: property, collationType: .binary)
        }
        
        self.index(name: "\(self.name ?? "_UNKNOWN_")_index_\(names.joined(separator: "_"))", elements: elements)
    }
    
    public func index(property: NSPropertyDescription) {
        self.index(name: "\(self.name ?? "_UNKNOWN_")_index_\(property.name)", elements: [
            NSFetchIndexElementDescription(property: property, collationType: .binary)
        ])
    }
    
    public func index(name: String, elements: Array<NSFetchIndexElementDescription>) {
        let index = NSFetchIndexDescription(name: name, elements: elements)
        
        self.indexes.append(index)
    }
    
    public func belongsTo(_ destination: NSEntityDescription, property: String, inverse: String, isRequired: Bool = true, deleteRule: NSDeleteRule = .nullifyDeleteRule, inverseDeleteRule: NSDeleteRule = .nullifyDeleteRule) {
        let source = NSRelationshipDescription()
        source.destinationEntity = destination
        source.name = property
        source.deleteRule = deleteRule
        source.maxCount = 1
        source.minCount = isRequired ? 1 : 0
        
        let dest = NSRelationshipDescription()
        dest.destinationEntity = self
        dest.name = inverse
        dest.deleteRule = inverseDeleteRule
        dest.minCount = 0
        dest.maxCount = 0
        
        source.inverseRelationship = dest
        dest.inverseRelationship = source
        
        self.properties.append(source)
        destination.properties.append(dest)
    }
    
    public func hasMany(_ destination: NSEntityDescription, property: String, inverse: String, deleteRule: NSDeleteRule = .nullifyDeleteRule, inverseDeleteRule: NSDeleteRule = .nullifyDeleteRule) {
        let source = NSRelationshipDescription()
        source.destinationEntity = destination
        source.name = property
        source.deleteRule = deleteRule
        source.maxCount = 0
        source.minCount = 0
        
        let dest = NSRelationshipDescription()
        dest.destinationEntity = self
        dest.name = inverse
        dest.deleteRule = inverseDeleteRule
        dest.minCount = 0
        dest.maxCount = 1
        
        source.inverseRelationship = dest
        dest.inverseRelationship = source
        
        self.properties.append(source)
        destination.properties.append(dest)
    }
}
