import UIKit
import Combine

class AdminSetupViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let stepLabel = UILabel()
    
    // Admin Password Setup
    private let adminPasswordContainer = UIView()
    private let adminPasswordLabel = UILabel()
    private let adminPasswordField = UITextField()
    private let adminPasswordConfirmField = UITextField()
    private let adminPasswordButton = UIButton(type: .system)
    
    // WiFi Admin Password Setup
    private let wifiPasswordContainer = UIView()
    private let wifiPasswordLabel = UILabel()
    private let wifiPasswordField = UITextField()
    private let wifiPasswordButton = UIButton(type: .system)
    
    // Complete Setup
    private let completeSetupButton = UIButton(type: .system)
    
    // MARK: - Properties
    
    private let adminService = AdminService.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentStep = 1
    private var keyboardHeight: CGFloat = 0
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupObservers()
        setupKeyboardObservers()
        updateUIForCurrentStep()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeKeyboardObservers()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Configure scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Configure title
        titleLabel.text = "Admin Setup"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure step label
        stepLabel.font = .systemFont(ofSize: 16, weight: .medium)
        stepLabel.textAlignment = .center
        stepLabel.textColor = .secondaryLabel
        stepLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure admin password container
        setupAdminPasswordSection()
        
        // Configure WiFi password container
        setupWiFiPasswordSection()
        
        // Configure complete setup button
        completeSetupButton.setTitle("Complete Setup", for: .normal)
        completeSetupButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        completeSetupButton.backgroundColor = .systemBlue
        completeSetupButton.setTitleColor(.white, for: .normal)
        completeSetupButton.layer.cornerRadius = 12
        completeSetupButton.translatesAutoresizingMaskIntoConstraints = false
        completeSetupButton.addTarget(self, action: #selector(completeSetupTapped), for: .touchUpInside)
        
        // Add all views to content view
        [titleLabel, stepLabel, adminPasswordContainer, wifiPasswordContainer, completeSetupButton].forEach {
            contentView.addSubview($0)
        }
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupAdminPasswordSection() {
        adminPasswordContainer.translatesAutoresizingMaskIntoConstraints = false
        adminPasswordContainer.backgroundColor = .secondarySystemBackground
        adminPasswordContainer.layer.cornerRadius = 16
        adminPasswordContainer.layer.shadowColor = UIColor.black.cgColor
        adminPasswordContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        adminPasswordContainer.layer.shadowRadius = 4
        adminPasswordContainer.layer.shadowOpacity = 0.1
        
        adminPasswordLabel.text = "Set Admin Password"
        adminPasswordLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        adminPasswordLabel.textAlignment = .center
        adminPasswordLabel.translatesAutoresizingMaskIntoConstraints = false
        
        [adminPasswordField, adminPasswordConfirmField].forEach { field in
            field.borderStyle = .roundedRect
            field.font = .systemFont(ofSize: 16)
            field.isSecureTextEntry = true
            field.translatesAutoresizingMaskIntoConstraints = false
        }
        
        adminPasswordField.placeholder = "Enter admin password"
        adminPasswordConfirmField.placeholder = "Confirm admin password"
        
        adminPasswordButton.setTitle("Set Admin Password", for: .normal)
        adminPasswordButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        adminPasswordButton.backgroundColor = .systemBlue
        adminPasswordButton.setTitleColor(.white, for: .normal)
        adminPasswordButton.layer.cornerRadius = 8
        adminPasswordButton.translatesAutoresizingMaskIntoConstraints = false
        adminPasswordButton.addTarget(self, action: #selector(setAdminPasswordTapped), for: .touchUpInside)
        
        [adminPasswordLabel, adminPasswordField, adminPasswordConfirmField, adminPasswordButton].forEach {
            adminPasswordContainer.addSubview($0)
        }
    }
    
    private func setupWiFiPasswordSection() {
        wifiPasswordContainer.translatesAutoresizingMaskIntoConstraints = false
        wifiPasswordContainer.backgroundColor = .secondarySystemBackground
        wifiPasswordContainer.layer.cornerRadius = 16
        wifiPasswordContainer.layer.shadowColor = UIColor.black.cgColor
        wifiPasswordContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        wifiPasswordContainer.layer.shadowRadius = 4
        wifiPasswordContainer.layer.shadowOpacity = 0.1
        
        wifiPasswordLabel.text = "Set WiFi Relay Admin Password"
        wifiPasswordLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        wifiPasswordLabel.textAlignment = .center
        wifiPasswordLabel.translatesAutoresizingMaskIntoConstraints = false
        
        wifiPasswordField.borderStyle = .roundedRect
        wifiPasswordField.font = .systemFont(ofSize: 16)
        wifiPasswordField.isSecureTextEntry = true
        wifiPasswordField.placeholder = "Enter WiFi relay device admin password"
        wifiPasswordField.translatesAutoresizingMaskIntoConstraints = false
        
        wifiPasswordButton.setTitle("Set WiFi Password", for: .normal)
        wifiPasswordButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        wifiPasswordButton.backgroundColor = .systemBlue
        wifiPasswordButton.setTitleColor(.white, for: .normal)
        wifiPasswordButton.layer.cornerRadius = 8
        wifiPasswordButton.translatesAutoresizingMaskIntoConstraints = false
        wifiPasswordButton.addTarget(self, action: #selector(setWiFiPasswordTapped), for: .touchUpInside)
        
        [wifiPasswordLabel, wifiPasswordField, wifiPasswordButton].forEach {
            wifiPasswordContainer.addSubview($0)
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Step label
            stepLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            stepLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Admin password container
            adminPasswordContainer.topAnchor.constraint(equalTo: stepLabel.bottomAnchor, constant: 40),
            adminPasswordContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            adminPasswordContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Admin password label
            adminPasswordLabel.topAnchor.constraint(equalTo: adminPasswordContainer.topAnchor, constant: 20),
            adminPasswordLabel.centerXAnchor.constraint(equalTo: adminPasswordContainer.centerXAnchor),
            
            // Admin password field
            adminPasswordField.topAnchor.constraint(equalTo: adminPasswordLabel.bottomAnchor, constant: 20),
            adminPasswordField.leadingAnchor.constraint(equalTo: adminPasswordContainer.leadingAnchor, constant: 20),
            adminPasswordField.trailingAnchor.constraint(equalTo: adminPasswordContainer.trailingAnchor, constant: -20),
            adminPasswordField.heightAnchor.constraint(equalToConstant: 44),
            
            // Admin password confirm field
            adminPasswordConfirmField.topAnchor.constraint(equalTo: adminPasswordField.bottomAnchor, constant: 12),
            adminPasswordConfirmField.leadingAnchor.constraint(equalTo: adminPasswordContainer.leadingAnchor, constant: 20),
            adminPasswordConfirmField.trailingAnchor.constraint(equalTo: adminPasswordContainer.trailingAnchor, constant: -20),
            adminPasswordConfirmField.heightAnchor.constraint(equalToConstant: 44),
            
            // Admin password button
            adminPasswordButton.topAnchor.constraint(equalTo: adminPasswordConfirmField.bottomAnchor, constant: 20),
            adminPasswordButton.centerXAnchor.constraint(equalTo: adminPasswordContainer.centerXAnchor),
            adminPasswordButton.widthAnchor.constraint(equalToConstant: 200),
            adminPasswordButton.heightAnchor.constraint(equalToConstant: 44),
            adminPasswordButton.bottomAnchor.constraint(equalTo: adminPasswordContainer.bottomAnchor, constant: -20),
            
            // WiFi password container
            wifiPasswordContainer.topAnchor.constraint(equalTo: adminPasswordContainer.bottomAnchor, constant: 30),
            wifiPasswordContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            wifiPasswordContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // WiFi password label
            wifiPasswordLabel.topAnchor.constraint(equalTo: wifiPasswordContainer.topAnchor, constant: 20),
            wifiPasswordLabel.centerXAnchor.constraint(equalTo: wifiPasswordContainer.centerXAnchor),
            
            // WiFi password field
            wifiPasswordField.topAnchor.constraint(equalTo: wifiPasswordLabel.bottomAnchor, constant: 20),
            wifiPasswordField.leadingAnchor.constraint(equalTo: wifiPasswordContainer.leadingAnchor, constant: 20),
            wifiPasswordField.trailingAnchor.constraint(equalTo: wifiPasswordContainer.trailingAnchor, constant: -20),
            wifiPasswordField.heightAnchor.constraint(equalToConstant: 44),
            
            // WiFi password button
            wifiPasswordButton.topAnchor.constraint(equalTo: wifiPasswordField.bottomAnchor, constant: 20),
            wifiPasswordButton.centerXAnchor.constraint(equalTo: wifiPasswordContainer.centerXAnchor),
            wifiPasswordButton.widthAnchor.constraint(equalToConstant: 200),
            wifiPasswordButton.heightAnchor.constraint(equalToConstant: 44),
            wifiPasswordButton.bottomAnchor.constraint(equalTo: wifiPasswordContainer.bottomAnchor, constant: -20),
            
            // Complete setup button
            completeSetupButton.topAnchor.constraint(equalTo: wifiPasswordContainer.bottomAnchor, constant: 40),
            completeSetupButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            completeSetupButton.widthAnchor.constraint(equalToConstant: 250),
            completeSetupButton.heightAnchor.constraint(equalToConstant: 50),
            completeSetupButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    private func setupObservers() {
        adminService.$isSetupComplete
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isComplete in
                self?.updateUIForCurrentStep()
            }
            .store(in: &cancellables)
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - UI Updates
    
    private func updateUIForCurrentStep() {
        let hasAdminPassword = adminService.hasAdminPassword
        let hasWiFiPassword = adminService.hasWiFiAdminPassword
        
        if !hasAdminPassword {
            currentStep = 1
            stepLabel.text = "Step 1 of 2: Set Admin Password"
            adminPasswordContainer.alpha = 1.0
            wifiPasswordContainer.alpha = 0.5
            completeSetupButton.alpha = 0.5
            completeSetupButton.isEnabled = false
        } else if !hasWiFiPassword {
            currentStep = 2
            stepLabel.text = "Step 2 of 2: Set WiFi Admin Password"
            adminPasswordContainer.alpha = 0.5
            wifiPasswordContainer.alpha = 1.0
            completeSetupButton.alpha = 0.5
            completeSetupButton.isEnabled = false
            
            // Mark admin password as complete
            adminPasswordButton.setTitle("✓ Admin Password Set", for: .normal)
            adminPasswordButton.backgroundColor = .systemGreen
            adminPasswordButton.isEnabled = false
        } else {
            stepLabel.text = "Setup Complete"
            adminPasswordContainer.alpha = 0.5
            wifiPasswordContainer.alpha = 0.5
            completeSetupButton.alpha = 1.0
            completeSetupButton.isEnabled = true
            
            // Mark both as complete
            adminPasswordButton.setTitle("✓ Admin Password Set", for: .normal)
            adminPasswordButton.backgroundColor = .systemGreen
            adminPasswordButton.isEnabled = false
            
            wifiPasswordButton.setTitle("✓ WiFi Password Set", for: .normal)
            wifiPasswordButton.backgroundColor = .systemGreen
            wifiPasswordButton.isEnabled = false
        }
    }
    
    // MARK: - Actions
    
    @objc private func setAdminPasswordTapped() {
        guard let password = adminPasswordField.text, !password.isEmpty,
              let confirmPassword = adminPasswordConfirmField.text, !confirmPassword.isEmpty else {
            showAlert(title: "Error", message: "Please enter and confirm your admin password")
            return
        }
        
        guard password == confirmPassword else {
            showAlert(title: "Error", message: "Passwords do not match")
            return
        }
        
        guard adminService.setAdminPassword(password) else {
            showAlert(title: "Error", message: "Password must be at least 6 characters long")
            return
        }
        
        adminPasswordField.text = ""
        adminPasswordConfirmField.text = ""
        updateUIForCurrentStep()
    }
    
    @objc private func setWiFiPasswordTapped() {
        guard let password = wifiPasswordField.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Please enter the WiFi admin password")
            return
        }
        
        // Test authentication with the relay device first
        wifiPasswordButton.isEnabled = false
        wifiPasswordButton.setTitle("Testing Connection...", for: .normal)
        
        Task {
            do {
                let wifiService = WiFiRelayService()
                try await wifiService.login(password: password)
                
                // If login succeeds, save the password
                await MainActor.run {
                    guard adminService.setWiFiAdminPassword(password) else {
                        self.showAlert(title: "Error", message: "Failed to save WiFi admin password")
                        self.resetWiFiPasswordButton()
                        return
                    }
                    
                    self.wifiPasswordField.text = ""
                    self.updateUIForCurrentStep()
                }
            } catch {
                await MainActor.run {
                    self.showAlert(title: "Authentication Failed", message: "Cannot connect to WiFi relay device. Please check:\n\n• The device is powered on and accessible\n• The password is correct\n• You're connected to the same network\n\nError: \(error.localizedDescription)")
                    self.resetWiFiPasswordButton()
                }
            }
        }
    }
    
    private func resetWiFiPasswordButton() {
        wifiPasswordButton.isEnabled = true
        wifiPasswordButton.setTitle("Set WiFi Password", for: .normal)
    }
    
    @objc private func completeSetupTapped() {
        guard adminService.isInitialSetupComplete else {
            showAlert(title: "Setup Incomplete", message: "Please complete all setup steps")
            return
        }
        
        let alert = UIAlertController(title: "Setup Complete", message: "Admin setup has been completed successfully. You can now proceed to event setup.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { [weak self] _ in
            self?.navigationController?.pushViewController(EventSelectionViewController(), animated: true)
        })
        present(alert, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardHeight = keyboardFrame.cgRectValue.height
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        
        UIView.animate(withDuration: duration) {
            self.scrollView.contentInset.bottom = keyboardHeight
            self.scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
            
            // Scroll to active text field if needed
            if let activeField = self.findFirstResponder() {
                let rect = activeField.convert(activeField.bounds, to: self.scrollView)
                self.scrollView.scrollRectToVisible(rect, animated: false)
            }
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        
        UIView.animate(withDuration: duration) {
            self.scrollView.contentInset.bottom = 0
            self.scrollView.verticalScrollIndicatorInsets.bottom = 0
        }
    }
    
    private func findFirstResponder() -> UIView? {
        if adminPasswordField.isFirstResponder { return adminPasswordField }
        if adminPasswordConfirmField.isFirstResponder { return adminPasswordConfirmField }
        if wifiPasswordField.isFirstResponder { return wifiPasswordField }
        return nil
    }
}