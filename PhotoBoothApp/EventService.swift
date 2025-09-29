import Foundation
import CoreData
import Combine

class EventService: ObservableObject {
    static let shared = EventService()
    
    private let coreDataStack = CoreDataStack.shared
    @Published var events: [Event] = []
    @Published var currentEvent: Event?
    
    private init() {
        fetchEvents()
    }
    
    // MARK: - CRUD Operations
    
    func createEvent(name: String, date: Date) -> Event {
        let context = coreDataStack.context
        let event = Event(context: context)
        event.name = name
        event.date = date
        
        saveContext()
        fetchEvents()
        
        return event
    }
    
    func updateEvent(_ event: Event) {
        event.updateTimestamp()
        saveContext()
        fetchEvents()
    }
    
    func deleteEvent(_ event: Event) {
        let context = coreDataStack.context
        context.delete(event)
        
        if currentEvent == event {
            currentEvent = nil
        }
        
        saveContext()
        fetchEvents()
    }
    
    func setCurrentEvent(_ event: Event) {
        currentEvent = event
    }
    
    // MARK: - Fetch Operations
    
    func fetchEvents() {
        let context = coreDataStack.context
        let request: NSFetchRequest<Event> = Event.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Event.updatedAt, ascending: false)]
        
        do {
            events = try context.fetch(request)
        } catch {
            print("Failed to fetch events: \(error)")
            events = []
        }
    }
    
    func getRecentEvents(limit: Int = 10) -> [Event] {
        return Array(events.prefix(limit))
    }
    
    func searchEvents(query: String) -> [Event] {
        return events.filter { event in
            event.name.localizedCaseInsensitiveContains(query) ||
            event.formattedDate.contains(query)
        }
    }
    
    // MARK: - WiFi Configuration
    
    func configureWiFi(for event: Event, ssid: String, password: String, macAddress: String, is5GHz: Bool) {
        event.wifiSSID = ssid
        event.wifiPassword = password
        event.wifiMACAddress = macAddress
        event.is5GHz = is5GHz
        updateEvent(event)
    }
    
    func clearWiFiConfiguration(for event: Event) {
        event.wifiSSID = nil
        event.wifiPassword = nil
        event.wifiMACAddress = nil
        event.is5GHz = false
        updateEvent(event)
    }
    
    // MARK: - Format and Printing Configuration
    
    func setPhotoFormat(for event: Event, format: PhotoFormat) {
        event.format = format
        updateEvent(event)
    }
    
    func setPrintingOption(for event: Event, option: PrintingOption) {
        event.printing = option
        updateEvent(event)
    }
    
    // MARK: - Helper Methods
    
    private func saveContext() {
        coreDataStack.saveContext()
    }
    
    func isEventConfigurationComplete(_ event: Event) -> Bool {
        return !event.name.isEmpty &&
               event.isWiFiConfigured
    }
    
    // MARK: - Background Operations
    
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        coreDataStack.performBackgroundTask(block)
    }
}