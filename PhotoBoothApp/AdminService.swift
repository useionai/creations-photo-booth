import Foundation
import Combine

class AdminService: ObservableObject {
    static let shared = AdminService()
    private init() {}
    
    @Published var isAdminLoggedIn = false
    @Published var isSetupComplete = false
    
    private let keychain = KeychainService.shared
    private var sessionTimer: Timer?
    private let sessionTimeout: TimeInterval = 300 // 5 minutes
    
    var hasAdminPassword: Bool {
        keychain.exists(for: .adminPassword)
    }
    
    var hasWiFiAdminPassword: Bool {
        keychain.exists(for: .wifiAdminPassword)
    }
    
    var isInitialSetupComplete: Bool {
        hasAdminPassword && hasWiFiAdminPassword
    }
    
    func setAdminPassword(_ password: String) -> Bool {
        guard isValidPassword(password) else { return false }
        let success = keychain.save(password, for: .adminPassword)
        updateSetupStatus()
        return success
    }
    
    func setWiFiAdminPassword(_ password: String) -> Bool {
        guard !password.isEmpty else { return false }
        let success = keychain.save(password, for: .wifiAdminPassword)
        updateSetupStatus()
        return success
    }
    
    func authenticateAdmin(password: String) -> Bool {
        guard let storedPassword = keychain.load(for: .adminPassword) else {
            print("Admin authentication failed: No stored password found")
            return false
        }
        
        print("Attempting admin authentication...")
        print("Entered password length: \(password.count)")
        print("Stored password length: \(storedPassword.count)")
        print("Entered password prefix: \(String(password.prefix(3)))...")
        print("Stored password prefix: \(String(storedPassword.prefix(3)))...")
        
        // Check for any hidden characters or encoding issues
        print("Entered password data: \(password.data(using: .utf8)?.base64EncodedString() ?? "nil")")
        print("Stored password data: \(storedPassword.data(using: .utf8)?.base64EncodedString() ?? "nil")")
        
        let isAuthenticated = storedPassword == password
        if isAuthenticated {
            print("Admin authentication successful")
            startAdminSession()
        } else {
            print("Admin authentication failed: Passwords do not match")
            // Character by character comparison for debugging
            let minLength = min(password.count, storedPassword.count)
            for i in 0..<minLength {
                let enteredChar = password[password.index(password.startIndex, offsetBy: i)]
                let storedChar = storedPassword[storedPassword.index(storedPassword.startIndex, offsetBy: i)]
                if enteredChar != storedChar {
                    print("First difference at position \(i): entered='\(enteredChar)' stored='\(storedChar)'")
                    break
                }
            }
        }
        return isAuthenticated
    }
    
    func getWiFiAdminPassword() -> String? {
        return keychain.load(for: .wifiAdminPassword)
    }
    
    func logoutAdmin() {
        isAdminLoggedIn = false
        sessionTimer?.invalidate()
        sessionTimer = nil
    }
    
    func extendSession() {
        guard isAdminLoggedIn else { return }
        startAdminSession()
    }
    
    private func startAdminSession() {
        isAdminLoggedIn = true
        sessionTimer?.invalidate()
        
        sessionTimer = Timer.scheduledTimer(withTimeInterval: sessionTimeout, repeats: false) { [weak self] _ in
            self?.logoutAdmin()
        }
    }
    
    private func updateSetupStatus() {
        isSetupComplete = isInitialSetupComplete
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        // Password must be at least 6 characters long
        return password.count >= 6
    }
    
    func resetAdminSettings() -> Bool {
        let adminSuccess = keychain.delete(for: .adminPassword)
        let wifiSuccess = keychain.delete(for: .wifiAdminPassword)
        logoutAdmin()
        updateSetupStatus()
        return adminSuccess && wifiSuccess
    }
}

enum AdminError: Error, LocalizedError {
    case invalidPassword
    case authenticationFailed
    case notAuthenticated
    case setupIncomplete
    
    var errorDescription: String? {
        switch self {
        case .invalidPassword:
            return "Password must be at least 6 characters long"
        case .authenticationFailed:
            return "Invalid admin password"
        case .notAuthenticated:
            return "Admin authentication required"
        case .setupIncomplete:
            return "Admin setup is not complete"
        }
    }
}