import Foundation
import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "PhotoBoothDataModel")
        
        // Load persistent stores synchronously to catch errors early
        let group = DispatchGroup()
        group.enter()
        
        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
            group.leave()
        }
        
        group.wait()
        
        if let error = loadError as NSError? {
            print("Core Data error: \(error), \(error.userInfo)")
            // Instead of fatal error, create an in-memory store for development
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
            
            container.loadPersistentStores { _, error in
                if let error = error {
                    fatalError("Failed to create in-memory store: \(error)")
                }
            }
        }
        
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Core Data save error: \(nsError), \(nsError.userInfo)")
                // Don't crash on save errors in development
            }
        }
    }
    
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }
}