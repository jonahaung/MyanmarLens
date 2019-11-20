//
//  PersistanceManager.swift
//  BalarSarYwat
//
//  Created by Aung Ko Min on 2/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation
import CoreData

class PersistanceManager {
    
    static let shared = PersistanceManager()
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    init(){
        _ = container
    }
    
    lazy var container = NSPersistentCloudKitContainer(name: "Myanmar_Lens")
    
    func loadContainer(completion: @escaping () -> Void ) {
        container.loadPersistentStores { (_, err) in
            guard err == nil else {
                print("\(err!.localizedDescription)")
                return
            }
            DispatchQueue.main.async {
                self.container.viewContext.automaticallyMergesChangesFromParent = true
                completion()
            }
        }
    }
    
    
    func saveContext () {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}
