//
//  SceneDelegate.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 20/11/19.
//  Copyright © 2019 Aung Ko Min. All rights reserved.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    static var sharedInstance: SceneDelegate? {
        struct Singleton {
            static let instance = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate
        }
        return Singleton.instance
    }



    fileprivate func applyCustomUIThemes() {
        let navBar = UINavigationBar.appearance()
//        navBar.barTintColor = .clear
        navBar.setBackgroundImage(UIImage(), for: .default)
        navBar.isTranslucent = true
        navBar.prefersLargeTitles = true
        navBar.shadowImage = UIImage()
        navBar.titleTextAttributes = [.foregroundColor: UIColor.secondaryLabel]
        
        let toolBar = UIToolbar.appearance()
        toolBar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        toolBar.clipsToBounds = true
        toolBar.barTintColor = .clear
        
        let tableView = UITableView.appearance()
        tableView.backgroundColor = nil
        tableView.separatorStyle = .none
        
        let tableCell = UITableViewCell.appearance()
        tableCell.backgroundColor = nil

    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        if let windowScene = scene as? UIWindowScene {
            applyCustomUIThemes()
            window = UIWindow(windowScene: windowScene)
            window?.overrideUserInterfaceStyle = .dark
            window?.tintColor = UIColor.lightText
            window?.makeKeyAndVisible()
            let userSettings = UserSettings()
            PersistanceManager.shared.loadContainer {
                let context = PersistanceManager.shared.viewContext
                let contentView = MainView().environment(\.managedObjectContext, context).environmentObject(userSettings)
                let rootViewController = UIHostingController(rootView: contentView)
                let nav = UINavigationController(rootViewController: rootViewController)
                
                self.window?.rootViewController = nav
                StartUpManager.checkVersion()
            }
        }
    }
    

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        PersistanceManager.shared.saveContext()
    }


}

