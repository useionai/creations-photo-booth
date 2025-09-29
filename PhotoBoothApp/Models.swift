import Foundation
import CoreData

// MARK: - Photo Format Enum

enum PhotoFormat: Int, CaseIterable {
    case singlePhoto = 0
    case singlePhotoWithDetails = 1
    case largePlusThreeSmall = 2
    
    var title: String {
        switch self {
        case .singlePhoto:
            return "Single Photo"
        case .singlePhotoWithDetails:
            return "Photo with Event Details"
        case .largePlusThreeSmall:
            return "Large + 3 Small Photos"
        }
    }
    
    var description: String {
        switch self {
        case .singlePhoto:
            return "One photo"
        case .singlePhotoWithDetails:
            return "One photo with event name and date in mm.dd.yyyy format"
        case .largePlusThreeSmall:
            return "One large photo on top, with three small photos below. Event name and date displayed beside the large photo"
        }
    }
    
    var photoCount: Int {
        switch self {
        case .singlePhoto, .singlePhotoWithDetails:
            return 1
        case .largePlusThreeSmall:
            return 4
        }
    }
}

// MARK: - Printing Option Enum

enum PrintingOption: Int, CaseIterable {
    case autoPrint = 0
    case userOption = 1
    case noPrinting = 2
    
    var title: String {
        switch self {
        case .autoPrint:
            return "Auto Print"
        case .userOption:
            return "User Option"
        case .noPrinting:
            return "No Printing"
        }
    }
    
    var description: String {
        switch self {
        case .autoPrint:
            return "Automatically print photos after capture"
        case .userOption:
            return "Give users the option to print"
        case .noPrinting:
            return "No printing available"
        }
    }
}

// MARK: - Event Model

@objc(Event)
public class Event: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var date: Date
    @NSManaged public var photoFormat: Int16
    @NSManaged public var printingOption: Int16
    @NSManaged public var wifiSSID: String?
    @NSManaged public var wifiPassword: String?
    @NSManaged public var wifiMACAddress: String?
    @NSManaged public var is5GHz: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    // Computed properties
    var format: PhotoFormat {
        get { PhotoFormat(rawValue: Int(photoFormat)) ?? .singlePhoto }
        set { photoFormat = Int16(newValue.rawValue) }
    }
    
    var printing: PrintingOption {
        get { PrintingOption(rawValue: Int(printingOption)) ?? .noPrinting }
        set { printingOption = Int16(newValue.rawValue) }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yyyy"
        return formatter.string(from: date)
    }
    
    var displayName: String {
        return "\(name) - \(formattedDate)"
    }
    
    var isWiFiConfigured: Bool {
        return wifiSSID != nil && !wifiSSID!.isEmpty
    }
}

// MARK: - Event Extensions

extension Event {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Event> {
        return NSFetchRequest<Event>(entityName: "Event")
    }
    
    convenience init(context: NSManagedObjectContext) {
        guard let entity = NSEntityDescription.entity(forEntityName: "Event", in: context) else {
            fatalError("Failed to find Event entity description")
        }
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.photoFormat = Int16(PhotoFormat.singlePhoto.rawValue)
        self.printingOption = Int16(PrintingOption.noPrinting.rawValue)
        self.is5GHz = false
    }
    
    func updateTimestamp() {
        self.updatedAt = Date()
    }
}

// MARK: - WiFi Network Model

struct WiFiNetwork: Codable, Identifiable, Hashable {
    let id = UUID()
    let ssid: String
    let macAddress: String
    let signalStrength: Int
    let securityType: String
    let is5GHz: Bool
    let channel: Int
    
    var displayName: String {
        return "\(ssid) (\(is5GHz ? "5GHz" : "2.4GHz"))"
    }
    
    var signalBars: Int {
        // Convert signal strength to 0-4 bars
        switch signalStrength {
        case -30...0: return 4
        case -50...(-31): return 3
        case -70...(-51): return 2
        case -90...(-71): return 1
        default: return 0
        }
    }
}