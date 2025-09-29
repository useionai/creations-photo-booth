import SwiftUI
import UIKit

struct UIKitBridge: UIViewControllerRepresentable {
    let coordinator: MainCoordinator
    
    func makeUIViewController(context: Context) -> UIViewController {
        // Create a container view controller
        let containerVC = UIViewController()
        containerVC.view.backgroundColor = .systemBackground
        
        // Start the coordinator which will set up the proper navigation
        DispatchQueue.main.async {
            self.coordinator.start()
        }
        
        return containerVC
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
}