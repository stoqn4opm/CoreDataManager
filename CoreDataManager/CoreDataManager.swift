//
//  CoreDataManager.swift
//  BrainCoach
//
//  Created by Stoyan Stoyanov on 26.09.18.
//  Copyright © 2018 Stoyan Stoyanov. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Configuration from Info.plist

extension String {
    
    fileprivate static var databaseModelFileName: String {
        return (Bundle.main.object(forInfoDictionaryKey: "CoreDataManager") as! [String: String])["DatabaseModelFileName"]!
    }
    
    fileprivate static var databaseModelExtension: String {
        return (Bundle.main.object(forInfoDictionaryKey: "CoreDataManager") as! [String: String])["DatabaseModelFileExtension"]!
    }
    
    fileprivate static var databaseFolderName: String {
        return (Bundle.main.object(forInfoDictionaryKey: "CoreDataManager") as! [String: String])["DatabaseFolderName"]!
    }
    
    fileprivate static var databaseName: String {
        return (Bundle.main.object(forInfoDictionaryKey: "CoreDataManager") as! [String: String])["DatabaseFileName"]!
    }
    
    fileprivate static var databaseExtension: String {
        return (Bundle.main.object(forInfoDictionaryKey: "CoreDataManager") as! [String: String])["DatabaseFileExtension"]!
    }
}

// MARK: - Public Interface

extension CoreDataManager {
    
    /// Reference to the one and only instance of `CoreDataManager`.
    public static let shared = CoreDataManager()
}

// MARK: - Class Definition

/// `CoreDataManager` is a `CoreData` wrapper, that configures a very commonly used CoreData environment - one `.mainContext` and one `.privateContext`.
///
/// Both contexts are listening for `.NSManagedObjectContextDidSave` notification by the other and update themselves appropriately. There is no parent - child relationship between them. During the lifetime of an application that uses `CoreDataManager` **only one** instance of this class exists and can be accessed through `CoreDataManager.shared`.
///
/// `CoreDataManager` framework also provides convenience method for generating ids of `NSManagedObject`s called `static func nextId(inContext:, withCompletion:)`. If you have a `NSManagerObject` subclass called `Subclass` you can use it like:
/// ```
/// // `subclassObject` and `completion` are passed from somewhere.
///
/// Subclass.nextId(inContext: context) { (id, error) in
///     guard let id = id else { completion(nil, error!); context.delete(subclassObject!); return }
///     subclassObject?.id = id
///     if saveContext {
///         do {
///             if context.hasChanges {
///                 try context.save()
///             }
///             DispatchQueue.main.async { completion(subclassObject, nil) }
///         } catch {
///             DispatchQueue.main.async { completion(nil, error) }
///         }
///     } else {
///           DispatchQueue.main.async { completion(subclassObject, nil) }
///       }
/// }
/// ```
/// **In order to use CoreDataManager in your app, you have to add Dictionary named 'CoreDataManager' with the following keys to your target's** `Info.plist` **file:**
/// - DatabaseModelFileName - the file name of your core data model inside your project
/// - DatabaseModelFileExtension - the file extension of your core data model inside your project
/// - DatabaseFileName - the name of the file you want core data to persist its context (SQLite persistent store)
/// - DatabaseFileExtension - the extension of the file you want core data to persist its context (SQLite persistent store)
/// - DatabaseFolderName - the folder in which you want your database persistance file to be contained. Describe it as a relative directory, from the context of the App's Bundle root directory.

final class CoreDataManager {
    
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(mainContextDidSave),    name: .NSManagedObjectContextDidSave, object: mainContext)
        NotificationCenter.default.addObserver(self, selector: #selector(privateContextDidSave), name: .NSManagedObjectContextDidSave, object: privateContext)
    }
    
    deinit {
         NotificationCenter.default.removeObserver(self, name: .NSManagedObjectContextDidSave, object: nil)
    }
    
    /// `NSManagedObjectContext` that is with `concurrencyType` = `.mainQueueConcurrencyType`
    public private(set) lazy var mainContext: NSManagedObjectContext = {
        let result = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        result.persistentStoreCoordinator = cordinator
        result.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return result
    }()
    
    /// `NSManagedObjectContext` that is with `concurrencyType` = `.privateQueueConcurrencyType`
    public private(set) lazy var privateContext: NSManagedObjectContext = {
        let result = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        result.persistentStoreCoordinator = cordinator
        result.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        return result
    } ()
    
    private var model: NSManagedObjectModel? {
        if let modelURL = Bundle.main.url(forResource: .databaseModelFileName, withExtension: .databaseModelExtension) {
            let result = NSManagedObjectModel(contentsOf: modelURL)
            return result
        }
        return nil
    }
    
    private lazy var databaseURL: URL? = {
        let fileManager = FileManager.default
        var databaseURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        databaseURL = databaseURL.appendingPathComponent(.databaseFolderName, isDirectory: true)
        if fileManager.fileExists(atPath: databaseURL.path) == false {
            do {
                try fileManager.createDirectory(at: databaseURL, withIntermediateDirectories: true, attributes: nil)
            }
            catch { return nil }
        }
        databaseURL = databaseURL.appendingPathComponent(.databaseName)
        databaseURL = databaseURL.appendingPathExtension(.databaseExtension)
        return databaseURL
    }()
    
    private lazy var cordinator: NSPersistentStoreCoordinator? = {
        
        guard let model = model else { return nil }
        let result = NSPersistentStoreCoordinator(managedObjectModel: model)
        let options = [NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true]
        do{
            try result.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: databaseURL, options: options)
            return result
        } catch {
            #if DEBUG
            print("[CoreDataManager] exeption during \(error.localizedDescription)")
            #endif
            return nil
        }
    }()
}

//MARK: - Notification Updates

extension CoreDataManager {
    
    @objc private func privateContextDidSave(notification : Notification) {
        mainContext.perform { [weak self] in
            self?.mainContext.mergeChanges(fromContextDidSave: notification)
        }
    }
    
    @objc private func mainContextDidSave(notification : Notification) {
        privateContext.perform { [weak self] in
            self?.privateContext.mergeChanges(fromContextDidSave: notification)
        }
    }
}
