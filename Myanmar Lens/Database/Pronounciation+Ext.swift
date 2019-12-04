//
//  Pronounciation+Ext.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 27/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import Foundation
import CoreData

extension Pronounciation {
    
    static func fetch(word: String, context: NSManagedObjectContext) -> String? {
        let encoded = word.urlEncoded
        let requeset: NSFetchRequest<Pronounciation> = Pronounciation.fetchRequest()
        requeset.predicate = NSPredicate(format: "word == %@", encoded)
        requeset.fetchLimit = 1
        do {
            return try context.fetch(requeset).first?.voice
        }catch {
            print(error)
            return nil
        }
    }
}
