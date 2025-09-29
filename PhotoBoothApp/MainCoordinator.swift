import UIKit
import SwiftUI
import CoreData

class MainCoordinator: ObservableObject {
    private let adminService = AdminService.shared
    weak var window: UIWindow?
    
    init(window: UIWindow?) {
        self.window = window
    }
    
    func start() {
        guard let window = window else { 
            // Try to find the window if not set
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let foundWindow = windowScene.windows.first {
                self.window = foundWindow
                start() // Retry with the found window
            }
            return 
        }
        
        // Initialize Core Data early
        _ = CoreDataStack.shared.persistentContainer
        
        // Debug admin setup status
        print("=== Admin Setup Status ===")
        print("Has admin password: \(adminService.hasAdminPassword)")
        print("Has WiFi admin password: \(adminService.hasWiFiAdminPassword)")
        print("Setup complete: \(adminService.isInitialSetupComplete)")
        
        if adminService.isInitialSetupComplete {
            print("Showing event selection")
            showEventSelection()
        } else {
            print("Showing admin setup")
            showAdminSetup()
        }
        
        window.makeKeyAndVisible()
    }
    
    private func showAdminSetup() {
        let adminSetupVC = AdminSetupViewController()
        let navigationController = UINavigationController(rootViewController: adminSetupVC)
        navigationController.navigationBar.isHidden = true
        window?.rootViewController = navigationController
    }
    
    private func showEventSelection() {
        let eventSelectionVC = EventSelectionViewController()
        let navigationController = UINavigationController(rootViewController: eventSelectionVC)
        navigationController.navigationBar.isHidden = true
        window?.rootViewController = navigationController
    }
    
    func showAdminLogin(completion: @escaping (Bool) -> Void) {
        guard let rootVC = window?.rootViewController else {
            completion(false)
            return
        }
        
        let adminLoginVC = AdminLoginViewController { success in
            completion(success)
        }
        
        rootVC.present(adminLoginVC, animated: true)
    }
}