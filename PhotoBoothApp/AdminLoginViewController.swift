import UIKit
import Combine

class AdminLoginViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let passwordField = UITextField()
    private let loginButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    // MARK: - Properties
    
    private let adminService = AdminService.shared
    private var cancellables = Set<AnyCancellable>()
    private var completion: ((Bool) -> Void)?
    
    // MARK: - Initializers
    
    init(completion: @escaping (Bool) -> Void) {
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupObservers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        passwordField.becomeFirstResponder()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // Configure container
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 20
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 12
        containerView.layer.shadowOpacity = 0.3
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure title
        titleLabel.text = "Admin Access"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure subtitle
        subtitleLabel.text = "Enter admin password to continue"
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure password field
        passwordField.borderStyle = .roundedRect
        passwordField.font = .systemFont(ofSize: 18)
        passwordField.isSecureTextEntry = true
        passwordField.placeholder = "Admin password"
        passwordField.textAlignment = .center
        passwordField.returnKeyType = .done
        passwordField.delegate = self
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure login button
        loginButton.setTitle("Login", for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        loginButton.backgroundColor = .systemBlue
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.layer.cornerRadius = 12
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        
        // Configure cancel button
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        cancelButton.setTitleColor(.systemRed, for: .normal)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        // Configure activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        
        // Add subviews
        view.addSubview(containerView)
        [titleLabel, subtitleLabel, passwordField, loginButton, cancelButton, activityIndicator].forEach {
            containerView.addSubview($0)
        }
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),
            containerView.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            // Password field
            passwordField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 30),
            passwordField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 30),
            passwordField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -30),
            passwordField.heightAnchor.constraint(equalToConstant: 50),
            
            // Login button
            loginButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 25),
            loginButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            loginButton.widthAnchor.constraint(equalToConstant: 120),
            loginButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Cancel button
            cancelButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 15),
            cancelButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -25),
            
            // Activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: loginButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: loginButton.centerYAnchor)
        ])
    }
    
    private func setupObservers() {
        adminService.$isAdminLoggedIn
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoggedIn in
                if isLoggedIn {
                    self?.handleSuccessfulLogin()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    @objc private func loginTapped() {
        guard let password = passwordField.text, !password.isEmpty else {
            showError("Please enter your admin password")
            return
        }
        
        setLoading(true)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let success = self?.adminService.authenticateAdmin(password: password) ?? false
            
            DispatchQueue.main.async {
                self?.setLoading(false)
                
                if success {
                    self?.handleSuccessfulLogin()
                } else {
                    self?.showAuthenticationFailedAlert()
                }
            }
        }
    }
    
    @objc private func cancelTapped() {
        completion?(false)
        dismiss(animated: true)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Helper Methods
    
    private func setLoading(_ loading: Bool) {
        if loading {
            activityIndicator.startAnimating()
            loginButton.setTitle("", for: .normal)
            loginButton.isEnabled = false
            passwordField.isEnabled = false
            cancelButton.isEnabled = false
        } else {
            activityIndicator.stopAnimating()
            loginButton.setTitle("Login", for: .normal)
            loginButton.isEnabled = true
            passwordField.isEnabled = true
            cancelButton.isEnabled = true
        }
    }
    
    private func handleSuccessfulLogin() {
        completion?(true)
        dismiss(animated: true)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showAuthenticationFailedAlert() {
        showError("Invalid admin password. Please try again.")
        passwordField.text = ""
        passwordField.becomeFirstResponder()
    }
}

// MARK: - UITextFieldDelegate

extension AdminLoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == passwordField {
            loginTapped()
        }
        return true
    }
}