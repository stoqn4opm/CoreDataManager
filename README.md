
### Summary

`CoreDataManager`  is a  `CoreData`  wrapper, that configures a very commonly used CoreData environment - one  `.mainContext`  and one  `.privateContext`. Written in Swift 4.2 in XCode 10. 

### Discussion

Both contexts are listening for  `.NSManagedObjectContextDidSave`  notification by the other and update themselves appropriately. There is no parent - child relationship between them. During the lifetime of an application that uses  `CoreDataManager`  **only one**  instance of this class exists and can be accessed through  `CoreDataManager.shared`.

`CoreDataManager`  framework also provides convenience method for generating ids of  `NSManagedObject`s called  `static func nextId(inContext:, withCompletion:)`. If you have a  `NSManagerObject`  subclass called  `Subclass`  you can use it like:

```swift
// `subclassObject` and `completion` are passed from somewhere.

Subclass.nextId(inContext: context) { (id, error) in
    guard let id = id else { completion(nil, error!); context.delete(subclassObject!); return }
    subclassObject?.id = id
    if saveContext {
        do {
            if context.hasChanges {
                try context.save()
            }
            DispatchQueue.main.async { completion(subclassObject, nil) }
        } catch {
            DispatchQueue.main.async { completion(nil, error) }
        }
    } else {
          DispatchQueue.main.async { completion(subclassObject, nil) }
      }
}
```

**In order to use CoreDataManager in your app, you have to add Dictionary named ‘CoreDataManager’ with the following keys to your target’s**  `Info.plist`  **file:**

-   DatabaseModelFileName - the file name of your core data model inside your project
    
-   DatabaseModelFileExtension - the file extension of your core data model inside your project
    
-   DatabaseFileName - the name of the file you want core data to persist its context (SQLite persistent store)
    
-   DatabaseFileExtension - the extension of the file you want core data to persist its context (SQLite persistent store)
    
-   DatabaseFolderName - the folder in which you want your database persistance file to be contained. Describe it as a relative directory, from the context of the App’s Bundle root directory.


### Licence
Licenced under MIT
