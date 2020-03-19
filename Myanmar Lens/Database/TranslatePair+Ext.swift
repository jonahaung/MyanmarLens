//
//  TranslatePair+Ext.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 25/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation
import CoreData
import NaturalLanguage

extension TranslatePair {
    
    static var historyFetchRequest: NSFetchRequest<TranslatePair> = {
        let x: NSFetchRequest<TranslatePair> = TranslatePair.fetchRequest()
        x.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        x.returnsObjectsAsFaults = false
        return x
    }()
    
    static var favoriteFetchRequest: NSFetchRequest<TranslatePair> = {
        let x: NSFetchRequest<TranslatePair> = TranslatePair.fetchRequest()
        x.predicate = NSPredicate(format: "isFavourite == TRUE")
        x.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return x
    }()
    
    static func save(_ from: String, _ to: String, language: String, date: Date, isFavourite: Bool, context: NSManagedObjectContext) {
        let x = TranslatePair(context: context)
        x.from = from
        x.to = to
        x.language = language
        x.date = date
        x.isFavourite = isFavourite
        context.saveIfHasChanges()
    }
    
    static func find(from: String, language: String, context: NSManagedObjectContext) -> TranslatePair? {
        let requeset: NSFetchRequest<TranslatePair> = TranslatePair.fetchRequest()
        requeset.predicate = NSPredicate(format: "from ==[c] %@ && language ==[c] %@", argumentArray: [from, language])
        requeset.fetchLimit = 1
        requeset.returnsObjectsAsFaults = false
        requeset.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        do {
            return try context.fetch(requeset).first
        }catch {
            print(error)
            return nil
        }
    }
    
    func delete() {
        PersistanceManager.shared.viewContext.delete(self)
    }
    
    var nlLanguage: NLLanguage {
        if let x = language {
            return NLLanguage(x)
        }
        return .english
    }
}
