//
//  GoodmanApp.swift
//  Goodman
//
//  Created by Wooi on 2023/12/16.
//

import SwiftUI

@main
struct GoodmanApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
    }
}



