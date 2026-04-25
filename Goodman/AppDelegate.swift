//
//  AppDelegate.swift
//  Goodman
//
//  Created by Wooi on 2024/7/28.
//

import UIKit
import CoreData

class AppDelegate: UIResponder, UIApplicationDelegate {
    // 在这里添加你的 AppDelegate 代码，如 Core Data 栈的配置
    var window: UIWindow?
    
    lazy var persistentContainer: NSPersistentContainer = {
            let container = NSPersistentContainer(name: "MyModel")
            container.loadPersistentStores { (storeDescription, error) in
                if let error = error {
                    fatalError("Unresolved error \(error)")
                }
            }
            return container
        }()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 通常在这里初始化设置
        return true
    }

    func saveContext() {
            let context = persistentContainer.viewContext
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
