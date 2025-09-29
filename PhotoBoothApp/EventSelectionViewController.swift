import UIKit
import Combine

class EventSelectionViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Recent Events Section
    private let recentEventsLabel = UILabel()
    private let recentEventsTableView = UITableView()
    
    // Action Buttons
    private let createNewEventButton = UIButton(type: .system)
    private let adminSettingsButton = UIButton(type: .system)
    
    // MARK: - Properties
    
    private let eventService = EventService.shared
    private let adminService = AdminService.shared
    private var cancellables = Set<AnyCancellable>()
    private var recentEvents: [Event] = []
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupObservers()
        setupTableView()
        refreshData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshData()
        checkAdminSetupStatus()
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
        titleLabel.text = "Event Selection"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure subtitle
        subtitleLabel.text = "Select an existing event or create a new one"
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure recent events label
        recentEventsLabel.text = "Recent Events"
        recentEventsLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        recentEventsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure table view
        recentEventsTableView.translatesAutoresizingMaskIntoConstraints = false
        recentEventsTableView.backgroundColor = .secondarySystemBackground
        recentEventsTableView.layer.cornerRadius = 12
        recentEventsTableView.separatorStyle = .none
        recentEventsTableView.isScrollEnabled = false
        
        // Configure create new event button
        createNewEventButton.setTitle("Create New Event", for: .normal)
        createNewEventButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        createNewEventButton.backgroundColor = .systemBlue
        createNewEventButton.setTitleColor(.white, for: .normal)
        createNewEventButton.layer.cornerRadius = 12
        createNewEventButton.translatesAutoresizingMaskIntoConstraints = false
        createNewEventButton.addTarget(self, action: #selector(createNewEventTapped), for: .touchUpInside)
        
        // Configure admin settings button
        adminSettingsButton.setTitle("Admin Settings", for: .normal)
        adminSettingsButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        adminSettingsButton.setTitleColor(.systemOrange, for: .normal)
        adminSettingsButton.translatesAutoresizingMaskIntoConstraints = false
        adminSettingsButton.addTarget(self, action: #selector(adminSettingsTapped), for: .touchUpInside)
        
        // Add all views to content view
        [titleLabel, subtitleLabel, recentEventsLabel, recentEventsTableView, createNewEventButton, adminSettingsButton].forEach {
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
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Recent events label
            recentEventsLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            recentEventsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            // Recent events table view
            recentEventsTableView.topAnchor.constraint(equalTo: recentEventsLabel.bottomAnchor, constant: 12),
            recentEventsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            recentEventsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            recentEventsTableView.heightAnchor.constraint(equalToConstant: 300),
            
            // Create new event button
            createNewEventButton.topAnchor.constraint(equalTo: recentEventsTableView.bottomAnchor, constant: 30),
            createNewEventButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            createNewEventButton.widthAnchor.constraint(equalToConstant: 250),
            createNewEventButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Admin settings button
            adminSettingsButton.topAnchor.constraint(equalTo: createNewEventButton.bottomAnchor, constant: 20),
            adminSettingsButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            adminSettingsButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }
    
    private func setupObservers() {
        eventService.$events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] events in
                self?.recentEvents = Array(events.prefix(5))
                self?.updateTableViewHeight()
                self?.recentEventsTableView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    private func setupTableView() {
        recentEventsTableView.delegate = self
        recentEventsTableView.dataSource = self
        recentEventsTableView.register(EventTableViewCell.self, forCellReuseIdentifier: "EventCell")
    }
    
    private func updateTableViewHeight() {
        let rowHeight: CGFloat = 70
        let maxHeight: CGFloat = 300
        let calculatedHeight = CGFloat(recentEvents.count) * rowHeight
        
        recentEventsTableView.constraints.forEach { constraint in
            if constraint.firstAttribute == .height {
                constraint.constant = min(calculatedHeight, maxHeight)
            }
        }
        
        recentEventsTableView.isScrollEnabled = calculatedHeight > maxHeight
    }
    
    private func refreshData() {
        eventService.fetchEvents()
    }
    
    private func checkAdminSetupStatus() {
        if !adminService.isInitialSetupComplete {
            let hasAdminPwd = adminService.hasAdminPassword
            let hasWiFiPwd = adminService.hasWiFiAdminPassword
            
            if hasAdminPwd && !hasWiFiPwd {
                // Admin password is set but WiFi admin password is missing
                let alert = UIAlertController(
                    title: "Setup Incomplete", 
                    message: "WiFi admin password is required to configure network settings. Would you like to complete the admin setup now?", 
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Complete Setup", style: .default) { [weak self] _ in
                    self?.goToAdminSetup()
                })
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                present(alert, animated: true)
            }
        }
    }
    
    private func goToAdminSetup() {
        let adminSetupVC = AdminSetupViewController()
        let navController = UINavigationController(rootViewController: adminSetupVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    // MARK: - Actions
    
    @objc private func createNewEventTapped() {
        let createEventVC = CreateEventViewController()
        let navController = UINavigationController(rootViewController: createEventVC)
        present(navController, animated: true)
    }
    
    @objc private func adminSettingsTapped() {
        let coordinator = MainCoordinator(window: view.window)
        coordinator.showAdminLogin { [weak self] success in
            if success {
                self?.showAdminMenu()
            }
        }
    }
    
    private func showAdminMenu() {
        let alert = UIAlertController(title: "Admin Settings", message: "Select an option", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Reset Admin Settings", style: .destructive) { [weak self] _ in
            self?.resetAdminSettings()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = adminSettingsButton
            popover.sourceRect = adminSettingsButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func resetAdminSettings() {
        let alert = UIAlertController(title: "Reset Admin Settings", message: "This will clear all admin passwords and require setup again. Continue?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
            if self?.adminService.resetAdminSettings() == true {
                let coordinator = MainCoordinator(window: self?.view.window)
                coordinator.start()
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func selectEvent(_ event: Event) {
        eventService.setCurrentEvent(event)
        
        if eventService.isEventConfigurationComplete(event) {
            // Navigate to Photo Booth mode
            let photoBoothVC = PhotoBoothViewController()
            navigationController?.pushViewController(photoBoothVC, animated: true)
        } else {
            // Navigate to event setup
            let setupVC = EventSetupViewController(event: event)
            navigationController?.pushViewController(setupVC, animated: true)
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension EventSelectionViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recentEvents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath) as! EventTableViewCell
        cell.configure(with: recentEvents[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectEvent(recentEvents[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}

// MARK: - Event Table View Cell

class EventTableViewCell: UITableViewCell {
    private let nameLabel = UILabel()
    private let dateLabel = UILabel()
    private let formatLabel = UILabel()
    private let statusLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        dateLabel.font = .systemFont(ofSize: 14, weight: .medium)
        dateLabel.textColor = .secondaryLabel
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        formatLabel.font = .systemFont(ofSize: 12, weight: .regular)
        formatLabel.textColor = .tertiaryLabel
        formatLabel.translatesAutoresizingMaskIntoConstraints = false
        
        statusLabel.font = .systemFont(ofSize: 12, weight: .medium)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        [nameLabel, dateLabel, formatLabel, statusLabel].forEach {
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -8),
            
            dateLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            formatLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            formatLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            formatLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            statusLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    func configure(with event: Event) {
        nameLabel.text = event.name
        dateLabel.text = event.formattedDate
        formatLabel.text = event.format.title
        
        if EventService.shared.isEventConfigurationComplete(event) {
            statusLabel.text = "✓ Ready"
            statusLabel.textColor = .systemGreen
        } else {
            statusLabel.text = "Setup Required"
            statusLabel.textColor = .systemOrange
        }
    }
}