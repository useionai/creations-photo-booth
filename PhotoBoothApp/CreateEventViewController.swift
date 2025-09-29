import UIKit

class CreateEventViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    
    // Event Name Section
    private let nameContainer = UIView()
    private let nameLabel = UILabel()
    private let nameField = UITextField()
    
    // Event Date Section
    private let dateContainer = UIView()
    private let dateLabel = UILabel()
    private let datePicker = UIDatePicker()
    
    // Action Buttons
    private let createButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    
    // MARK: - Properties
    
    private let eventService = EventService.shared
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupKeyboardHandling()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nameField.becomeFirstResponder()
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
        titleLabel.text = "Create New Event"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup name section
        setupNameSection()
        
        // Setup date section
        setupDateSection()
        
        // Configure create button
        createButton.setTitle("Create Event", for: .normal)
        createButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        createButton.backgroundColor = .systemBlue
        createButton.setTitleColor(.white, for: .normal)
        createButton.layer.cornerRadius = 12
        createButton.translatesAutoresizingMaskIntoConstraints = false
        createButton.addTarget(self, action: #selector(createEventTapped), for: .touchUpInside)
        
        // Configure cancel button
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        cancelButton.setTitleColor(.systemRed, for: .normal)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        // Add all views to content view
        [titleLabel, nameContainer, dateContainer, createButton, cancelButton].forEach {
            contentView.addSubview($0)
        }
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupNameSection() {
        nameContainer.translatesAutoresizingMaskIntoConstraints = false
        nameContainer.backgroundColor = .secondarySystemBackground
        nameContainer.layer.cornerRadius = 16
        nameContainer.layer.shadowColor = UIColor.black.cgColor
        nameContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        nameContainer.layer.shadowRadius = 4
        nameContainer.layer.shadowOpacity = 0.1
        
        nameLabel.text = "Event Name"
        nameLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        nameField.borderStyle = .roundedRect
        nameField.font = .systemFont(ofSize: 18)
        nameField.placeholder = "Enter event name"
        nameField.textAlignment = .center
        nameField.returnKeyType = .next
        nameField.delegate = self
        nameField.translatesAutoresizingMaskIntoConstraints = false
        
        [nameLabel, nameField].forEach {
            nameContainer.addSubview($0)
        }
    }
    
    private func setupDateSection() {
        dateContainer.translatesAutoresizingMaskIntoConstraints = false
        dateContainer.backgroundColor = .secondarySystemBackground
        dateContainer.layer.cornerRadius = 16
        dateContainer.layer.shadowColor = UIColor.black.cgColor
        dateContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        dateContainer.layer.shadowRadius = 4
        dateContainer.layer.shadowOpacity = 0.1
        
        dateLabel.text = "Event Date"
        dateLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        dateLabel.textAlignment = .center
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.minimumDate = Date()
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        
        [dateLabel, datePicker].forEach {
            dateContainer.addSubview($0)
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
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Name container
            nameContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            nameContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Name label
            nameLabel.topAnchor.constraint(equalTo: nameContainer.topAnchor, constant: 20),
            nameLabel.centerXAnchor.constraint(equalTo: nameContainer.centerXAnchor),
            
            // Name field
            nameField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 20),
            nameField.leadingAnchor.constraint(equalTo: nameContainer.leadingAnchor, constant: 20),
            nameField.trailingAnchor.constraint(equalTo: nameContainer.trailingAnchor, constant: -20),
            nameField.heightAnchor.constraint(equalToConstant: 50),
            nameField.bottomAnchor.constraint(equalTo: nameContainer.bottomAnchor, constant: -20),
            
            // Date container
            dateContainer.topAnchor.constraint(equalTo: nameContainer.bottomAnchor, constant: 30),
            dateContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            dateContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Date label
            dateLabel.topAnchor.constraint(equalTo: dateContainer.topAnchor, constant: 20),
            dateLabel.centerXAnchor.constraint(equalTo: dateContainer.centerXAnchor),
            
            // Date picker
            datePicker.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 20),
            datePicker.leadingAnchor.constraint(equalTo: dateContainer.leadingAnchor, constant: 20),
            datePicker.trailingAnchor.constraint(equalTo: dateContainer.trailingAnchor, constant: -20),
            datePicker.bottomAnchor.constraint(equalTo: dateContainer.bottomAnchor, constant: -20),
            
            // Create button
            createButton.topAnchor.constraint(equalTo: dateContainer.bottomAnchor, constant: 40),
            createButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            createButton.widthAnchor.constraint(equalToConstant: 200),
            createButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Cancel button
            cancelButton.topAnchor.constraint(equalTo: createButton.bottomAnchor, constant: 20),
            cancelButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }
    
    private func setupKeyboardHandling() {
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Actions
    
    @objc private func createEventTapped() {
        guard let eventName = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !eventName.isEmpty else {
            showAlert(title: "Error", message: "Please enter an event name")
            return
        }
        
        let eventDate = datePicker.date
        let event = eventService.createEvent(name: eventName, date: eventDate)
        
        dismiss(animated: true) { [weak self] in
            // Navigate to event setup
            if let presentingVC = self?.presentingViewController as? UINavigationController,
               let eventSelectionVC = presentingVC.topViewController as? EventSelectionViewController {
                let setupVC = EventSetupViewController(event: event)
                eventSelectionVC.navigationController?.pushViewController(setupVC, animated: true)
            }
        }
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
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
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        
        UIView.animate(withDuration: duration) {
            self.scrollView.contentInset.bottom = 0
            self.scrollView.verticalScrollIndicatorInsets.bottom = 0
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension CreateEventViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameField {
            nameField.resignFirstResponder()
            return false
        }
        return true
    }
}