//
//  HistoryView.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 25/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import SwiftUI
import CoreData

struct HistoryView: View {
    
    @Environment(\.managedObjectContext) var context: NSManagedObjectContext
    @FetchRequest(fetchRequest: TranslatePair.historyFetchRequest)
    private var items: FetchedResults
    
    var body: some View {
        
        List {
            ForEach(items, id: \.self) { item in
                ListCell(item: item)
            }
            .onDelete(perform: delete)
        }
        .background(Image("background").resizable().scaledToFill())
        .navigationBarTitle("History")
    }
    
    private func delete(at offsets: IndexSet) {
        guard let index = Array(offsets).first else { return }
        let item = items[index]
        context.delete(item)
    }
}
