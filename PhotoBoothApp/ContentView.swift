//
//  ContentView.swift
//  PhotoBoothApp
//
//  Created by grandebrothers on 2025-09-28.
//

import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var coordinator: MainCoordinator
    @StateObject private var adminService = AdminService.shared
    
    var body: some View {
        MainAppViewControllerWrapper()
            .environmentObject(coordinator)
            .onAppear {
                // Update coordinator with window reference when available
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    coordinator.window = window
                    coordinator.start()
                }
            }
    }
}

struct MainAppViewControllerWrapper: UIViewControllerRepresentable {
    @EnvironmentObject var coordinator: MainCoordinator
    
    func makeUIViewController(context: Context) -> UIViewController {
        return UIViewController() // Placeholder - coordinator will replace this
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
}

// Keep the old ContentView for preview compatibility
struct ContentView: View {
    var body: some View {
        MainAppView()
            .environmentObject(MainCoordinator(window: nil))
    }
}

#Preview {
    ContentView()
}
