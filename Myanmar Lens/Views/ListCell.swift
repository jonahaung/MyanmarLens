//
//  ListCell.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 26/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import SwiftUI

struct ListCell: View {
    
    let item: TranslatePair
    
    private var dateString: String { return item.date?.dateString ?? "" }
    private var langage: String { return item.language?.uppercased() ?? "" }
   
    var body: some View {
        VStack(alignment: .leading, spacing: 5){
            Text(item.to.string).font((item.to.string).titleFont)
            Text(item.from.string).font(.system(size: 16, weight: .light))
            HStack{
                Image(systemName: "flag.fill").padding(.leading)
                Text(langage)
                Spacer()
                Text(dateString)
                if item.isFavourite {
                    Image(systemName: "heart.fill").foregroundColor(.red)
                }
            }.font(.system(size: 14, weight: .thin, design: .monospaced))
        }
        .padding(.vertical)
        .onTapGesture(perform: ontap)
    }
    
    private func ontap() {
        SoundManager.playSound(tone: .Tock)
        var actions = [ActionPair]()
        let item = self.item
        
        
        if item.isFavourite {
            let action = {
                TranslatePair.save(item.from.string, item.to.string, language: item.language.string, date: item.date ?? Date(), isFavourite: false, context: PersistanceManager.shared.viewContext)
                item.delete()
            }
            actions.append(("Remove from Favourites", action))
        } else {
            let action = {
                TranslatePair.save(item.from.string, item.to.string, language: item.language.string, date: Date(), isFavourite: true, context: PersistanceManager.shared.viewContext)
                item.delete()
            }
            actions.append(("Add to Favourites", action))
        }
        
        let delete = {
            item.delete()
        }
        actions.append(("Delete this Record", delete))
        
        AlertPresenter.presentActionSheet(title: item.nlLanguage.localName, message: item.date?.relativeString, actions: actions)
    }
    
}


extension String {
    var titleFont: Font {
        return Font(self.EXT_isMyanmarCharacters ? UIFont(name: "MyanmarPhetsot", size: 22)! : UIFont.monospacedSystemFont(ofSize: 22, weight: .medium))
    }
}
