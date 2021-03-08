//
//  ManagedObjectModel.swift
//  
//
//  Created by Maddie Schipper on 2/27/21.
//

import Foundation
import CoreData
import ObjectStore

class Person : Model {
    @NSManaged var firstName: String?
    @NSManaged var lastName: String?
}

func CreateTestManagedObjectModel() -> NSManagedObjectModel {
    let model = NSManagedObjectModel()
    
    let person = Person.createEntityDescription { desc in
        desc.addAttribute("firstName", .stringAttributeType)
        desc.addAttribute("lastName", .stringAttributeType)
    }
    
    model.entities.append(person)
    
    return model
}
