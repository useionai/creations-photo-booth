//
//  PhotoBoothAppApp.swift
//  PhotoBoothApp
//
//  Created by grandebrothers on 2025-09-28.
//

import SwiftUI

@main
struct PhotoBoothAppApp: App {
    @StateObject private var coordinator = MainCoordinator(window: nil)
    
    var body: some Scene {
        WindowGroup {
            MainAppView()
                .environmentObject(coordinator)
        }
    }
}
