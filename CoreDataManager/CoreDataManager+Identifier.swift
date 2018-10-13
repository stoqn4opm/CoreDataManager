//
//  EntityUniqueIdentifier.swift
//  CoreDataManager
//
//  Created by Stoyan Stoyanov on 5.10.18.
//  Copyright © 2018 Stoyan Stoyanov. All rights reserved.
//

import CoreData

// MARK: - Possible Errors

extension NSManagedObject {
    
    /// Possible errors when generating `id`s of `NSManagedObject`s.
    public enum Error: Swift.Error {
        
        /// Occurs when you are trying to generate an `id` for `NSManagedObject` subclass which it does not have set entity name.
        case noEntityName
        
        /// Occurs when core data throws an error.
        case fetchError(Swift.Error?)
    }
}

// MARK: - ID Generation

extension NSManagedObject {
    
    /// It returns you the smallest free id not used by any other object from this `NSManagedObject` subclass. **NOTE: your** `NSManagedObject`s **has to store their** `id`**s in attribute name called 'id'.**
    ///
    /// How it works:
    /// - it fetches the object with the biggest `id` currently stored on in `CoreData`
    /// - it returns this biggest `id` + 1
    /// - if there are no records for this Entity in `CoreData` then it returns 1.
    ///
    /// - Parameters:
    ///   - context: the context in which you want to search for free id.
    ///   - completion: returns you either free `id` or error.
    public static func nextId(inContext context: NSManagedObjectContext, withCompletion completion: @escaping (Int32?, Error?) -> ()) {
                
        context.perform {
            do {
                guard let entityName = entity().name else { completion(nil, nil); return }
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
                fetchRequest.propertiesToFetch = ["id"]
                fetchRequest.fetchLimit = 1
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]

                let results = try context.fetch(fetchRequest) as! [NSManagedObject]
                let lastObject = results.first
                
                guard lastObject != nil else { completion(1, nil); return }
                
                let nextId = lastObject?.value(forKey: "id") as! Int32 + 1
                completion(nextId, nil)
                
            } catch {
                completion(nil, .fetchError(error))
            }
        }
    }
}
