import Foundation
import SwiftData
import CoreLocation

@Model
final class User {
    var id: String
    var email: String
    var firstName: String
    var lastName: String
    var phoneNumber: String?
    var profileImageURL: String?
    var createdAt: Date
    var updatedAt: Date
    var isVerified: Bool
    var parkingSessions: [ParkingSession]?
    var paymentMethods: [PaymentMethod]?
    
    init(id: String, email: String, firstName: String, lastName: String) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isVerified = false
    }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

@Model
final class ParkingSession {
    var id: String
    var userId: String
    var location: LocationData
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    var cost: Double
    var status: ParkingStatus
    var paymentMethodId: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String, userId: String, location: LocationData, startTime: Date = Date()) {
        self.id = id
        self.userId = userId
        self.location = location
        self.startTime = startTime
        self.duration = 0
        self.cost = 0.0
        self.status = .active
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
final class PaymentMethod {
    var id: String
    var userId: String
    var type: PaymentType
    var lastFourDigits: String
    var expiryMonth: Int
    var expiryYear: Int
    var cardholderName: String
    var isDefault: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String, userId: String, type: PaymentType, lastFourDigits: String, expiryMonth: Int, expiryYear: Int, cardholderName: String) {
        self.id = id
        self.userId = userId
        self.type = type
        self.lastFourDigits = lastFourDigits
        self.expiryMonth = expiryMonth
        self.expiryYear = expiryYear
        self.cardholderName = cardholderName
        self.isDefault = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
final class LocationData {
    var latitude: Double
    var longitude: Double
    var address: String
    var city: String
    var state: String
    var zipCode: String
    var country: String
    
    init(latitude: Double, longitude: Double, address: String, city: String, state: String, zipCode: String, country: String) {
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.country = country
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum ParkingStatus: String, CaseIterable, Codable {
    case active = "active"
    case completed = "completed"
    case cancelled = "cancelled"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .expired: return "Expired"
        }
    }
    
    var color: String {
        switch self {
        case .active: return "green"
        case .completed: return "blue"
        case .cancelled: return "red"
        case .expired: return "orange"
        }
    }
}

enum PaymentType: String, CaseIterable, Codable {
    case visa = "visa"
    case mastercard = "mastercard"
    case amex = "amex"
    case discover = "discover"
    
    var displayName: String {
        switch self {
        case .visa: return "Visa"
        case .mastercard: return "Mastercard"
        case .amex: return "American Express"
        case .discover: return "Discover"
        }
    }
    
    var icon: String {
        switch self {
        case .visa: return "creditcard.fill"
        case .mastercard: return "creditcard.fill"
        case .amex: return "creditcard.fill"
        case .discover: return "creditcard.fill"
        }
    }
}
