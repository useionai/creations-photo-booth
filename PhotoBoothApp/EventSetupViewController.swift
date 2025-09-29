import UIKit
import Combine

class EventSetupViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let eventNameLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let stepLabel = UILabel()
    
    // Step containers
    private let formatContainer = UIView()
    private let wifiContainer = UIView()
    private let printingContainer = UIView()
    
    // Complete button
    private let completeButton = UIButton(type: .system)
    
    // MARK: - Properties
    
    private let event: Event
    private let eventService = EventService.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentStep = 1
    private let totalSteps = 3
    
    // MARK: - Initializer
    
    init(event: Event) {
        self.event = event
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupStepContainers()
        updateProgress()
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
        titleLabel.text = "Event Setup"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure event name
        eventNameLabel.text = event.displayName
        eventNameLabel.font = .systemFont(ofSize: 18, weight: .medium)
        eventNameLabel.textAlignment = .center
        eventNameLabel.textColor = .secondaryLabel
        eventNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure progress view
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = .systemBlue
        
        // Configure step label
        stepLabel.font = .systemFont(ofSize: 16, weight: .medium)
        stepLabel.textAlignment = .center
        stepLabel.textColor = .secondaryLabel
        stepLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure containers
        [formatContainer, wifiContainer, printingContainer].forEach { container in
            container.translatesAutoresizingMaskIntoConstraints = false
            container.backgroundColor = .secondarySystemBackground
            container.layer.cornerRadius = 16
            container.layer.shadowColor = UIColor.black.cgColor
            container.layer.shadowOffset = CGSize(width: 0, height: 2)
            container.layer.shadowRadius = 4
            container.layer.shadowOpacity = 0.1
        }
        
        // Configure complete button
        completeButton.setTitle("Complete Setup", for: .normal)
        completeButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        completeButton.backgroundColor = .systemGreen
        completeButton.setTitleColor(.white, for: .normal)
        completeButton.layer.cornerRadius = 12
        completeButton.translatesAutoresizingMaskIntoConstraints = false
        completeButton.addTarget(self, action: #selector(completeSetupTapped), for: .touchUpInside)
        
        // Add all views to content view
        [titleLabel, eventNameLabel, progressView, stepLabel, formatContainer, wifiContainer, printingContainer, completeButton].forEach {
            contentView.addSubview($0)
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
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Event name
            eventNameLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            eventNameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Progress view
            progressView.topAnchor.constraint(equalTo: eventNameLabel.bottomAnchor, constant: 20),
            progressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            
            // Step label
            stepLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 8),
            stepLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Format container
            formatContainer.topAnchor.constraint(equalTo: stepLabel.bottomAnchor, constant: 30),
            formatContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            formatContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            formatContainer.heightAnchor.constraint(equalToConstant: 120),
            
            // WiFi container
            wifiContainer.topAnchor.constraint(equalTo: formatContainer.bottomAnchor, constant: 20),
            wifiContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            wifiContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            wifiContainer.heightAnchor.constraint(equalToConstant: 120),
            
            // Printing container
            printingContainer.topAnchor.constraint(equalTo: wifiContainer.bottomAnchor, constant: 20),
            printingContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            printingContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            printingContainer.heightAnchor.constraint(equalToConstant: 120),
            
            // Complete button
            completeButton.topAnchor.constraint(equalTo: printingContainer.bottomAnchor, constant: 40),
            completeButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            completeButton.widthAnchor.constraint(equalToConstant: 250),
            completeButton.heightAnchor.constraint(equalToConstant: 50),
            completeButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    private func setupStepContainers() {
        setupFormatContainer()
        setupWiFiContainer()
        setupPrintingContainer()
    }
    
    private func setupFormatContainer() {
        let titleLabel = UILabel()
        titleLabel.text = "1. Select Photo Format"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let statusLabel = UILabel()
        statusLabel.text = event.format.title
        statusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        statusLabel.textColor = .secondaryLabel
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let button = UIButton(type: .system)
        button.setTitle("Select Format", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(selectFormatTapped), for: .touchUpInside)
        
        [titleLabel, statusLabel, button].forEach {
            formatContainer.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: formatContainer.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: formatContainer.leadingAnchor, constant: 20),
            
            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: formatContainer.leadingAnchor, constant: 20),
            
            button.centerYAnchor.constraint(equalTo: formatContainer.centerYAnchor),
            button.trailingAnchor.constraint(equalTo: formatContainer.trailingAnchor, constant: -20),
            button.widthAnchor.constraint(equalToConstant: 120),
            button.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupWiFiContainer() {
        let titleLabel = UILabel()
        titleLabel.text = "2. Configure WiFi"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let statusLabel = UILabel()
        statusLabel.text = event.isWiFiConfigured ? "✓ Configured" : "Not configured"
        statusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        statusLabel.textColor = event.isWiFiConfigured ? .systemGreen : .secondaryLabel
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let button = UIButton(type: .system)
        button.setTitle("Setup WiFi", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(setupWiFiTapped), for: .touchUpInside)
        
        [titleLabel, statusLabel, button].forEach {
            wifiContainer.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: wifiContainer.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: wifiContainer.leadingAnchor, constant: 20),
            
            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: wifiContainer.leadingAnchor, constant: 20),
            
            button.centerYAnchor.constraint(equalTo: wifiContainer.centerYAnchor),
            button.trailingAnchor.constraint(equalTo: wifiContainer.trailingAnchor, constant: -20),
            button.widthAnchor.constraint(equalToConstant: 120),
            button.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupPrintingContainer() {
        let titleLabel = UILabel()
        titleLabel.text = "3. Printing Options"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let statusLabel = UILabel()
        statusLabel.text = event.printing.title
        statusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        statusLabel.textColor = .secondaryLabel
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let button = UIButton(type: .system)
        button.setTitle("Configure", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(configurePrintingTapped), for: .touchUpInside)
        
        [titleLabel, statusLabel, button].forEach {
            printingContainer.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: printingContainer.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: printingContainer.leadingAnchor, constant: 20),
            
            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: printingContainer.leadingAnchor, constant: 20),
            
            button.centerYAnchor.constraint(equalTo: printingContainer.centerYAnchor),
            button.trailingAnchor.constraint(equalTo: printingContainer.trailingAnchor, constant: -20),
            button.widthAnchor.constraint(equalToConstant: 120),
            button.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func updateProgress() {
        var completedSteps = 1 // Format is always set to default
        
        if event.isWiFiConfigured {
            completedSteps += 1
        }
        
        // Printing options always count as completed since default is set
        completedSteps += 1
        
        let progress = Float(completedSteps) / Float(totalSteps)
        progressView.setProgress(progress, animated: true)
        
        stepLabel.text = "Step \(completedSteps) of \(totalSteps) complete"
        
        // Update complete button
        let isComplete = eventService.isEventConfigurationComplete(event)
        completeButton.alpha = isComplete ? 1.0 : 0.5
        completeButton.isEnabled = isComplete
    }
    
    // MARK: - Actions
    
    @objc private func selectFormatTapped() {
        let formatVC = FormatSelectionViewController(event: event)
        let navController = UINavigationController(rootViewController: formatVC)
        present(navController, animated: true)
    }
    
    @objc private func setupWiFiTapped() {
        let wifiVC = WiFiSetupViewController(event: event)
        let navController = UINavigationController(rootViewController: wifiVC)
        present(navController, animated: true)
    }
    
    @objc private func configurePrintingTapped() {
        let printingVC = PrintingSetupViewController(event: event)
        let navController = UINavigationController(rootViewController: printingVC)
        present(navController, animated: true)
    }
    
    @objc private func completeSetupTapped() {
        guard eventService.isEventConfigurationComplete(event) else {
            showAlert(title: "Setup Incomplete", message: "Please complete WiFi configuration before proceeding.")
            return
        }
        
        let alert = UIAlertController(title: "Setup Complete", message: "Event setup is complete. Ready to start the photo booth!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Start Photo Booth", style: .default) { [weak self] _ in
            let photoBoothVC = PhotoBoothViewController()
            self?.navigationController?.pushViewController(photoBoothVC, animated: true)
        })
        present(alert, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Placeholder View Controllers

class FormatSelectionViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Format options
    private var formatContainers: [UIView] = []
    private var selectedFormat: PhotoFormat
    
    // MARK: - Properties
    
    private let event: Event
    private let eventService = EventService.shared
    
    // MARK: - Initializer
    
    init(event: Event) {
        self.event = event
        self.selectedFormat = event.format
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        updateSelection()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Photo Format"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
        
        // Configure scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Configure title
        titleLabel.text = "Select Photo Format"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure subtitle
        subtitleLabel.text = "Choose how photos will be arranged and displayed"
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Create format options
        createFormatOptions()
        
        // Add all views to content view
        [titleLabel, subtitleLabel].forEach {
            contentView.addSubview($0)
        }
        formatContainers.forEach {
            contentView.addSubview($0)
        }
    }
    
    private func createFormatOptions() {
        formatContainers = []
        
        for format in PhotoFormat.allCases {
            let container = createFormatContainer(for: format)
            formatContainers.append(container)
        }
    }
    
    private func createFormatContainer(for format: PhotoFormat) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 16
        container.layer.borderWidth = 2
        container.layer.borderColor = UIColor.clear.cgColor
        
        // Preview image
        let previewImage = PhotoLayoutRenderer.shared.generatePreview(
            format: format,
            eventName: event.name,
            eventDate: event.formattedDate
        )
        
        let imageView = UIImageView(image: previewImage)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        
        // Title label
        let titleLabel = UILabel()
        titleLabel.text = format.title
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Description label
        let descLabel = UILabel()
        descLabel.text = format.description
        descLabel.font = .systemFont(ofSize: 14, weight: .medium)
        descLabel.textAlignment = .center
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 0
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Photo count label
        let countLabel = UILabel()
        countLabel.text = "\(format.photoCount) photo\(format.photoCount > 1 ? "s" : "")"
        countLabel.font = .systemFont(ofSize: 12, weight: .medium)
        countLabel.textAlignment = .center
        countLabel.textColor = .systemBlue
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Selection indicator
        let selectionIndicator = UIView()
        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        selectionIndicator.backgroundColor = .systemBlue
        selectionIndicator.layer.cornerRadius = 12
        selectionIndicator.isHidden = true
        
        let checkmarkLabel = UILabel()
        checkmarkLabel.text = "✓"
        checkmarkLabel.font = .systemFont(ofSize: 16, weight: .bold)
        checkmarkLabel.textColor = .white
        checkmarkLabel.textAlignment = .center
        checkmarkLabel.translatesAutoresizingMaskIntoConstraints = false
        selectionIndicator.addSubview(checkmarkLabel)
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(formatTapped(_:)))
        container.addGestureRecognizer(tapGesture)
        container.tag = format.rawValue
        
        // Add subviews
        [imageView, titleLabel, descLabel, countLabel, selectionIndicator].forEach {
            container.addSubview($0)
        }
        
        // Setup constraints
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 200),
            
            imageView.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 100),
            
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: selectionIndicator.leadingAnchor, constant: -16),
            
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 16),
            descLabel.trailingAnchor.constraint(equalTo: selectionIndicator.leadingAnchor, constant: -16),
            
            countLabel.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 8),
            countLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 16),
            countLabel.trailingAnchor.constraint(equalTo: selectionIndicator.leadingAnchor, constant: -16),
            
            selectionIndicator.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            selectionIndicator.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            selectionIndicator.widthAnchor.constraint(equalToConstant: 24),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 24),
            
            checkmarkLabel.centerXAnchor.constraint(equalTo: selectionIndicator.centerXAnchor),
            checkmarkLabel.centerYAnchor.constraint(equalTo: selectionIndicator.centerYAnchor)
        ])
        
        return container
    }
    
    private func setupConstraints() {
        var constraints: [NSLayoutConstraint] = [
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
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ]
        
        // Format containers
        var previousContainer: UIView = subtitleLabel
        for container in formatContainers {
            constraints.append(contentsOf: [
                container.topAnchor.constraint(equalTo: previousContainer.bottomAnchor, constant: 20),
                container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
            ])
            previousContainer = container
        }
        
        // Bottom constraint
        if let lastContainer = formatContainers.last {
            constraints.append(lastContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30))
        }
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func updateSelection() {
        for (index, container) in formatContainers.enumerated() {
            let format = PhotoFormat.allCases[index]
            let isSelected = format == selectedFormat
            
            container.layer.borderColor = isSelected ? UIColor.systemBlue.cgColor : UIColor.clear.cgColor
            container.backgroundColor = isSelected ? UIColor.systemBlue.withAlphaComponent(0.1) : .secondarySystemBackground
            
            // Update selection indicator
            if let selectionIndicator = container.subviews.last {
                selectionIndicator.isHidden = !isSelected
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func formatTapped(_ gesture: UITapGestureRecognizer) {
        guard let container = gesture.view,
              let format = PhotoFormat(rawValue: container.tag) else { return }
        
        selectedFormat = format
        updateSelection()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        eventService.setPhotoFormat(for: event, format: selectedFormat)
        dismiss(animated: true)
    }
}

class WiFiSetupViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let statusLabel = UILabel()
    
    // Scan section
    private let scanButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    // Networks table
    private let networksTableView = UITableView()
    private let noNetworksLabel = UILabel()
    
    // Password input (hidden initially)
    private let passwordContainer = UIView()
    private let selectedNetworkLabel = UILabel()
    private let passwordField = UITextField()
    private let connectButton = UIButton(type: .system)
    
    // MARK: - Properties
    
    private let event: Event
    private let eventService = EventService.shared
    private let wifiService = WiFiRelayService()
    private let adminService = AdminService.shared
    
    private var networks: [WiFiRelayNetwork] = []
    private var selectedNetwork: WiFiRelayNetwork?
    private var isScanning = false
    
    // MARK: - Initializer
    
    init(event: Event) {
        self.event = event
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupTableView()
        setupKeyboardHandling()
        checkCurrentStatus()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        authenticateAndScan()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "WiFi Setup"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        // Configure scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delaysContentTouches = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Configure title
        titleLabel.text = "Configure WiFi Network"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure status
        statusLabel.text = "Scan for available networks"
        statusLabel.font = .systemFont(ofSize: 16, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.textColor = .secondaryLabel
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure scan button
        scanButton.setTitle("Scan Networks", for: .normal)
        scanButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        scanButton.backgroundColor = .systemBlue
        scanButton.setTitleColor(.white, for: .normal)
        scanButton.layer.cornerRadius = 12
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        scanButton.addTarget(self, action: #selector(scanNetworksTapped), for: .touchUpInside)
        
        // Configure activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        
        // Configure table view
        networksTableView.translatesAutoresizingMaskIntoConstraints = false
        networksTableView.backgroundColor = .secondarySystemBackground
        networksTableView.layer.cornerRadius = 12
        networksTableView.isHidden = true
        
        // Configure no networks label
        noNetworksLabel.text = "No networks found. Try scanning again."
        noNetworksLabel.font = .systemFont(ofSize: 16, weight: .medium)
        noNetworksLabel.textAlignment = .center
        noNetworksLabel.textColor = .secondaryLabel
        noNetworksLabel.translatesAutoresizingMaskIntoConstraints = false
        noNetworksLabel.isHidden = true
        
        // Configure password container
        passwordContainer.translatesAutoresizingMaskIntoConstraints = false
        passwordContainer.backgroundColor = .secondarySystemBackground
        passwordContainer.layer.cornerRadius = 16
        passwordContainer.isHidden = true
        
        selectedNetworkLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        selectedNetworkLabel.textAlignment = .center
        selectedNetworkLabel.translatesAutoresizingMaskIntoConstraints = false
        
        passwordField.borderStyle = .roundedRect
        passwordField.font = .systemFont(ofSize: 16)
        passwordField.placeholder = "Enter WiFi password"
        passwordField.isSecureTextEntry = true
        passwordField.returnKeyType = .done
        passwordField.delegate = self
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        
        connectButton.setTitle("Connect", for: .normal)
        connectButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        connectButton.backgroundColor = .systemGreen
        connectButton.setTitleColor(.white, for: .normal)
        connectButton.layer.cornerRadius = 8
        connectButton.translatesAutoresizingMaskIntoConstraints = false
        connectButton.addTarget(self, action: #selector(connectTapped), for: .touchUpInside)
        
        [selectedNetworkLabel, passwordField, connectButton].forEach {
            passwordContainer.addSubview($0)
        }
        
        // Add all views to content view
        [titleLabel, statusLabel, scanButton, activityIndicator, networksTableView, noNetworksLabel, passwordContainer].forEach {
            contentView.addSubview($0)
        }
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
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
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Status
            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            statusLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Scan button
            scanButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 30),
            scanButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            scanButton.widthAnchor.constraint(equalToConstant: 200),
            scanButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: scanButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: scanButton.centerYAnchor),
            
            // Networks table view
            networksTableView.topAnchor.constraint(equalTo: scanButton.bottomAnchor, constant: 30),
            networksTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            networksTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            networksTableView.heightAnchor.constraint(equalToConstant: 300),
            
            // No networks label
            noNetworksLabel.centerXAnchor.constraint(equalTo: networksTableView.centerXAnchor),
            noNetworksLabel.centerYAnchor.constraint(equalTo: networksTableView.centerYAnchor),
            
            // Password container
            passwordContainer.topAnchor.constraint(equalTo: networksTableView.bottomAnchor, constant: 20),
            passwordContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            passwordContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            passwordContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),
            
            // Password container contents
            selectedNetworkLabel.topAnchor.constraint(equalTo: passwordContainer.topAnchor, constant: 20),
            selectedNetworkLabel.centerXAnchor.constraint(equalTo: passwordContainer.centerXAnchor),
            
            passwordField.topAnchor.constraint(equalTo: selectedNetworkLabel.bottomAnchor, constant: 20),
            passwordField.leadingAnchor.constraint(equalTo: passwordContainer.leadingAnchor, constant: 20),
            passwordField.trailingAnchor.constraint(equalTo: passwordContainer.trailingAnchor, constant: -20),
            passwordField.heightAnchor.constraint(equalToConstant: 44),
            
            connectButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 20),
            connectButton.centerXAnchor.constraint(equalTo: passwordContainer.centerXAnchor),
            connectButton.widthAnchor.constraint(equalToConstant: 120),
            connectButton.heightAnchor.constraint(equalToConstant: 44),
            connectButton.bottomAnchor.constraint(equalTo: passwordContainer.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupTableView() {
        networksTableView.delegate = self
        networksTableView.dataSource = self
        networksTableView.register(WiFiNetworkCell.self, forCellReuseIdentifier: "NetworkCell")
        networksTableView.separatorStyle = .none
        networksTableView.isUserInteractionEnabled = true
        networksTableView.allowsSelection = true
        networksTableView.delaysContentTouches = false
        
        // Fix gesture recognizer conflicts with parent scroll view
        scrollView.panGestureRecognizer.require(toFail: networksTableView.panGestureRecognizer)
        
        // Add backup tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tableViewTapped(_:)))
        tapGesture.cancelsTouchesInView = false
        networksTableView.addGestureRecognizer(tapGesture)
        
        print("Table view setup complete - interaction enabled: \(networksTableView.isUserInteractionEnabled)")
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
    
    private func checkCurrentStatus() {
        if event.isWiFiConfigured {
            statusLabel.text = "Current: \(event.wifiSSID ?? "Unknown Network")"
            statusLabel.textColor = .systemGreen
        }
    }
    
    private func authenticateAndScan() {
        guard let wifiPassword = adminService.getWiFiAdminPassword() else {
            let hasAdminPwd = adminService.hasAdminPassword
            let hasWiFiPwd = adminService.hasWiFiAdminPassword
            let setupComplete = adminService.isInitialSetupComplete
            
            let debugMessage = "Admin Setup Status:\n- Admin Password: \(hasAdminPwd ? "✓" : "✗")\n- WiFi Admin Password: \(hasWiFiPwd ? "✓" : "✗")\n- Setup Complete: \(setupComplete ? "✓" : "✗")\n\nPlease complete the WiFi admin password setup in the admin configuration."
            
            showAlert(title: "WiFi Admin Password Required", message: debugMessage)
            return
        }
        
        Task {
            do {
                print("Attempting WiFi service login with password: [REDACTED]")
                try await wifiService.login(password: wifiPassword)
                print("WiFi service login successful")
                await scanNetworks()
            } catch {
                print("WiFi service login failed: \(error)")
                await MainActor.run {
                    self.showAlert(title: "Authentication Failed", message: "Login failed: \(error.localizedDescription)\n\nPlease check that the WiFi admin password is correct and the relay device is accessible.")
                }
            }
        }
    }
    
    private func scanNetworks() async {
        await MainActor.run {
            isScanning = true
            updateScanButton()
            statusLabel.text = "Scanning for networks..."
            statusLabel.textColor = .secondaryLabel
        }
        
        do {
            try await wifiService.scanNetworks()
            await MainActor.run {
                self.networks = self.wifiService.availableNetworks
                self.updateNetworksDisplay()
                self.autoSelectPreviousNetwork()
            }
        } catch {
            await MainActor.run {
                self.showAlert(title: "Scan Failed", message: error.localizedDescription)
            }
        }
        
        await MainActor.run {
            isScanning = false
            updateScanButton()
        }
    }
    
    private func updateScanButton() {
        if isScanning {
            scanButton.setTitle("", for: .normal)
            scanButton.isEnabled = false
            activityIndicator.startAnimating()
        } else {
            scanButton.setTitle("Scan Networks", for: .normal)
            scanButton.isEnabled = true
            activityIndicator.stopAnimating()
        }
    }
    
    private func updateNetworksDisplay() {
        if networks.isEmpty {
            networksTableView.isHidden = true
            noNetworksLabel.isHidden = false
            statusLabel.text = "No networks found"
        } else {
            networksTableView.isHidden = false
            noNetworksLabel.isHidden = true
            networksTableView.reloadData()
            statusLabel.text = "Found \(networks.count) network\(networks.count > 1 ? "s" : "")"
        }
    }
    
    private func autoSelectPreviousNetwork() {
        guard let currentSSID = event.wifiSSID,
              let network = networks.first(where: { $0.ssid == currentSSID }) else { return }
        
        selectNetwork(network)
    }
    
    private func selectNetwork(_ network: WiFiRelayNetwork) {
        selectedNetwork = network
        selectedNetworkLabel.text = "Connect to: \(network.displayName)"
        
        if network.securityMode.lowercased() == "open" {
            passwordField.isHidden = true
            passwordField.text = ""
        } else {
            passwordField.isHidden = false
            passwordField.text = event.wifiSSID == network.ssid ? event.wifiPassword : ""
        }
        
        passwordContainer.isHidden = false
        
        // Scroll to show password container
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.scrollView.scrollRectToVisible(self.passwordContainer.frame, animated: true)
        }
    }
    
    // MARK: - Actions
    
    @objc private func tableViewTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: networksTableView)
        if let indexPath = networksTableView.indexPathForRow(at: location) {
            print("Backup tap gesture detected at index: \(indexPath.row)")
            tableView(networksTableView, didSelectRowAt: indexPath)
        }
    }
    
    @objc private func scanNetworksTapped() {
        Task {
            await scanNetworks()
        }
    }
    
    @objc private func connectTapped() {
        guard let network = selectedNetwork else { return }
        
        let password = passwordField.text ?? ""
        
        Task {
            do {
                try await wifiService.selectNetwork(
                    ssid: network.ssid,
                    password: password,
                    mac: network.mac,
                    is5GHz: network.is5GHz
                )
                
                await MainActor.run {
                    // Save to event
                    self.eventService.configureWiFi(
                        for: self.event,
                        ssid: network.ssid,
                        password: password,
                        macAddress: network.mac,
                        is5GHz: network.is5GHz
                    )
                    
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    self.statusLabel.text = "✓ Connected to \(network.ssid)"
                    self.statusLabel.textColor = .systemGreen
                    
                    // Show success feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
            } catch {
                await MainActor.run {
                    self.showAlert(title: "Connection Failed", message: error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
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

// MARK: - UITableViewDataSource & UITableViewDelegate

extension WiFiSetupViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return networks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NetworkCell", for: indexPath) as! WiFiNetworkCell
        cell.configure(with: networks[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Network cell tapped at index: \(indexPath.row)")
        tableView.deselectRow(at: indexPath, animated: true)
        let network = networks[indexPath.row]
        print("Selected network: \(network.ssid)")
        selectNetwork(network)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - UITextFieldDelegate

extension WiFiSetupViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == passwordField {
            connectTapped()
        }
        return true
    }
}

// MARK: - WiFi Network Cell

class WiFiNetworkCell: UITableViewCell {
    private let nameLabel = UILabel()
    private let frequencyLabel = UILabel()
    private let securityLabel = UILabel()
    private let signalImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .default
        isUserInteractionEnabled = true
        
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.isUserInteractionEnabled = false
        
        frequencyLabel.font = .systemFont(ofSize: 12, weight: .medium)
        frequencyLabel.textColor = .systemBlue
        frequencyLabel.translatesAutoresizingMaskIntoConstraints = false
        frequencyLabel.isUserInteractionEnabled = false
        
        securityLabel.font = .systemFont(ofSize: 12, weight: .medium)
        securityLabel.textColor = .secondaryLabel
        securityLabel.translatesAutoresizingMaskIntoConstraints = false
        securityLabel.isUserInteractionEnabled = false
        
        signalImageView.translatesAutoresizingMaskIntoConstraints = false
        signalImageView.contentMode = .scaleAspectFit
        signalImageView.isUserInteractionEnabled = false
        
        [nameLabel, frequencyLabel, securityLabel, signalImageView].forEach {
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: signalImageView.leadingAnchor, constant: -8),
            
            frequencyLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            frequencyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            securityLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            securityLabel.leadingAnchor.constraint(equalTo: frequencyLabel.trailingAnchor, constant: 12),
            securityLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            signalImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            signalImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            signalImageView.widthAnchor.constraint(equalToConstant: 24),
            signalImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    func configure(with network: WiFiRelayNetwork) {
        nameLabel.text = network.ssid
        frequencyLabel.text = network.frequencyDescription
        securityLabel.text = network.securityMode
        
        // Signal strength indicator
        let signalBars = max(1, min(4, (network.signalStrength + 100) / 25))
        signalImageView.image = UIImage(systemName: "wifi", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20))
        signalImageView.tintColor = signalBars > 2 ? .systemGreen : signalBars > 1 ? .systemYellow : .systemRed
    }
}

class PrintingSetupViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Printing options
    private var optionContainers: [UIView] = []
    private var selectedOption: PrintingOption
    
    // Printer discovery section
    private let printerSection = UIView()
    private let printerTitleLabel = UILabel()
    private let discoverButton = UIButton(type: .system)
    private let printersTableView = UITableView()
    private let noPrintersLabel = UILabel()
    
    // MARK: - Properties
    
    private let event: Event
    private let eventService = EventService.shared
    private var availablePrinters: [Printer] = []
    private var selectedPrinter: Printer?
    
    // MARK: - Initializer
    
    init(event: Event) {
        self.event = event
        self.selectedOption = event.printing
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupTableView()
        updatePrinterSectionVisibility()
        discoverPrinters()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Printing Setup"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
        
        // Configure scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Configure title
        titleLabel.text = "Printing Options"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure subtitle
        subtitleLabel.text = "Choose how photos will be printed"
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Create printing options
        createPrintingOptions()
        
        // Setup printer section
        setupPrinterSection()
        
        // Add all views to content view
        [titleLabel, subtitleLabel].forEach {
            contentView.addSubview($0)
        }
        optionContainers.forEach {
            contentView.addSubview($0)
        }
        contentView.addSubview(printerSection)
    }
    
    private func createPrintingOptions() {
        optionContainers = []
        
        for option in PrintingOption.allCases {
            let container = createOptionContainer(for: option)
            optionContainers.append(container)
        }
    }
    
    private func createOptionContainer(for option: PrintingOption) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 16
        container.layer.borderWidth = 2
        container.layer.borderColor = UIColor.clear.cgColor
        
        // Icon
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .systemBlue
        
        let iconName: String
        switch option {
        case .autoPrint:
            iconName = "printer.fill"
        case .userOption:
            iconName = "person.crop.circle.fill.badge.questionmark"
        case .noPrinting:
            iconName = "printer.slash"
        }
        iconView.image = UIImage(systemName: iconName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 30))
        
        // Title label
        let titleLabel = UILabel()
        titleLabel.text = option.title
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Description label
        let descLabel = UILabel()
        descLabel.text = option.description
        descLabel.font = .systemFont(ofSize: 14, weight: .medium)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 0
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Selection indicator
        let selectionIndicator = UIView()
        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        selectionIndicator.backgroundColor = .systemBlue
        selectionIndicator.layer.cornerRadius = 12
        selectionIndicator.isHidden = true
        
        let checkmarkLabel = UILabel()
        checkmarkLabel.text = "✓"
        checkmarkLabel.font = .systemFont(ofSize: 16, weight: .bold)
        checkmarkLabel.textColor = .white
        checkmarkLabel.textAlignment = .center
        checkmarkLabel.translatesAutoresizingMaskIntoConstraints = false
        selectionIndicator.addSubview(checkmarkLabel)
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(optionTapped(_:)))
        container.addGestureRecognizer(tapGesture)
        container.tag = option.rawValue
        
        // Add subviews
        [iconView, titleLabel, descLabel, selectionIndicator].forEach {
            container.addSubview($0)
        }
        
        // Setup constraints
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 100),
            
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: selectionIndicator.leadingAnchor, constant: -16),
            
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 16),
            descLabel.trailingAnchor.constraint(equalTo: selectionIndicator.leadingAnchor, constant: -16),
            descLabel.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -20),
            
            selectionIndicator.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            selectionIndicator.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            selectionIndicator.widthAnchor.constraint(equalToConstant: 24),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 24),
            
            checkmarkLabel.centerXAnchor.constraint(equalTo: selectionIndicator.centerXAnchor),
            checkmarkLabel.centerYAnchor.constraint(equalTo: selectionIndicator.centerYAnchor)
        ])
        
        return container
    }
    
    private func setupPrinterSection() {
        printerSection.translatesAutoresizingMaskIntoConstraints = false
        printerSection.backgroundColor = .secondarySystemBackground
        printerSection.layer.cornerRadius = 16
        
        printerTitleLabel.text = "Available Printers"
        printerTitleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        printerTitleLabel.textAlignment = .center
        printerTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        discoverButton.setTitle("Discover Printers", for: .normal)
        discoverButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        discoverButton.backgroundColor = .systemBlue
        discoverButton.setTitleColor(.white, for: .normal)
        discoverButton.layer.cornerRadius = 8
        discoverButton.translatesAutoresizingMaskIntoConstraints = false
        discoverButton.addTarget(self, action: #selector(discoverPrintersTapped), for: .touchUpInside)
        
        printersTableView.translatesAutoresizingMaskIntoConstraints = false
        printersTableView.backgroundColor = .clear
        printersTableView.layer.cornerRadius = 8
        printersTableView.isScrollEnabled = false
        
        noPrintersLabel.text = "No AirPrint printers found"
        noPrintersLabel.font = .systemFont(ofSize: 16, weight: .medium)
        noPrintersLabel.textAlignment = .center
        noPrintersLabel.textColor = .secondaryLabel
        noPrintersLabel.translatesAutoresizingMaskIntoConstraints = false
        noPrintersLabel.isHidden = true
        
        [printerTitleLabel, discoverButton, printersTableView, noPrintersLabel].forEach {
            printerSection.addSubview($0)
        }
    }
    
    private func setupConstraints() {
        var constraints: [NSLayoutConstraint] = [
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
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ]
        
        // Option containers
        var previousView: UIView = subtitleLabel
        for container in optionContainers {
            constraints.append(contentsOf: [
                container.topAnchor.constraint(equalTo: previousView.bottomAnchor, constant: 20),
                container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
            ])
            previousView = container
        }
        
        // Printer section
        if let lastContainer = optionContainers.last {
            constraints.append(contentsOf: [
                printerSection.topAnchor.constraint(equalTo: lastContainer.bottomAnchor, constant: 30),
                printerSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                printerSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
                printerSection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),
                
                // Printer section contents
                printerTitleLabel.topAnchor.constraint(equalTo: printerSection.topAnchor, constant: 20),
                printerTitleLabel.centerXAnchor.constraint(equalTo: printerSection.centerXAnchor),
                
                discoverButton.topAnchor.constraint(equalTo: printerTitleLabel.bottomAnchor, constant: 16),
                discoverButton.centerXAnchor.constraint(equalTo: printerSection.centerXAnchor),
                discoverButton.widthAnchor.constraint(equalToConstant: 150),
                discoverButton.heightAnchor.constraint(equalToConstant: 36),
                
                printersTableView.topAnchor.constraint(equalTo: discoverButton.bottomAnchor, constant: 16),
                printersTableView.leadingAnchor.constraint(equalTo: printerSection.leadingAnchor, constant: 16),
                printersTableView.trailingAnchor.constraint(equalTo: printerSection.trailingAnchor, constant: -16),
                printersTableView.heightAnchor.constraint(equalToConstant: 150),
                printersTableView.bottomAnchor.constraint(equalTo: printerSection.bottomAnchor, constant: -20),
                
                noPrintersLabel.centerXAnchor.constraint(equalTo: printersTableView.centerXAnchor),
                noPrintersLabel.centerYAnchor.constraint(equalTo: printersTableView.centerYAnchor)
            ])
        }
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupTableView() {
        printersTableView.delegate = self
        printersTableView.dataSource = self
        printersTableView.register(PrinterCell.self, forCellReuseIdentifier: "PrinterCell")
        printersTableView.separatorStyle = .none
    }
    
    private func updateSelection() {
        for (index, container) in optionContainers.enumerated() {
            let option = PrintingOption.allCases[index]
            let isSelected = option == selectedOption
            
            container.layer.borderColor = isSelected ? UIColor.systemBlue.cgColor : UIColor.clear.cgColor
            container.backgroundColor = isSelected ? UIColor.systemBlue.withAlphaComponent(0.1) : .secondarySystemBackground
            
            // Update selection indicator
            if let selectionIndicator = container.subviews.last {
                selectionIndicator.isHidden = !isSelected
            }
        }
        
        updatePrinterSectionVisibility()
    }
    
    private func updatePrinterSectionVisibility() {
        let shouldShow = selectedOption != .noPrinting
        printerSection.isHidden = !shouldShow
    }
    
    private func discoverPrinters() {
        // Mock printer discovery for demonstration
        availablePrinters = [
            Printer(name: "Canon PIXMA", model: "PIXMA TS8320", isConnected: true),
            Printer(name: "HP LaserJet", model: "LaserJet Pro M404", isConnected: false),
            Printer(name: "Epson EcoTank", model: "EcoTank ET-2720", isConnected: true)
        ]
        updatePrintersDisplay()
    }
    
    private func updatePrintersDisplay() {
        if availablePrinters.isEmpty {
            noPrintersLabel.isHidden = false
            printersTableView.isHidden = true
        } else {
            noPrintersLabel.isHidden = true
            printersTableView.isHidden = false
            printersTableView.reloadData()
        }
    }
    
    // MARK: - Actions
    
    @objc private func optionTapped(_ gesture: UITapGestureRecognizer) {
        guard let container = gesture.view,
              let option = PrintingOption(rawValue: container.tag) else { return }
        
        selectedOption = option
        updateSelection()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    @objc private func discoverPrintersTapped() {
        discoverPrinters()
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        eventService.setPrintingOption(for: event, option: selectedOption)
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension PrintingSetupViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availablePrinters.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PrinterCell", for: indexPath) as! PrinterCell
        cell.configure(with: availablePrinters[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedPrinter = availablePrinters[indexPath.row]
        
        // Update selection in table
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}

// MARK: - Supporting Models and Classes

struct Printer {
    let name: String
    let model: String
    let isConnected: Bool
}

class PrinterCell: UITableViewCell {
    private let nameLabel = UILabel()
    private let modelLabel = UILabel()
    private let statusIndicator = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        modelLabel.font = .systemFont(ofSize: 14, weight: .medium)
        modelLabel.textColor = .secondaryLabel
        modelLabel.translatesAutoresizingMaskIntoConstraints = false
        
        statusIndicator.translatesAutoresizingMaskIntoConstraints = false
        statusIndicator.layer.cornerRadius = 6
        
        [nameLabel, modelLabel, statusIndicator].forEach {
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusIndicator.leadingAnchor, constant: -8),
            
            modelLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            modelLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            modelLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            statusIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statusIndicator.widthAnchor.constraint(equalToConstant: 12),
            statusIndicator.heightAnchor.constraint(equalToConstant: 12)
        ])
    }
    
    func configure(with printer: Printer) {
        nameLabel.text = printer.name
        modelLabel.text = printer.model
        statusIndicator.backgroundColor = printer.isConnected ? .systemGreen : .systemGray
    }
}

class PhotoBoothViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "Photo Booth Mode\n(Phase 3 - Coming Soon)"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}