//
//  Models.swift
//  Raedam
//
//  Created by Omar Waked on 5/15/21.
//  
//

import Foundation
import SwiftData
import CoreLocation

// MARK: - User Model

/// Represents a user account in the parking application.
/// 
/// This model stores user information including personal details,
/// authentication status, and relationships to parking sessions and payment methods.
@Model
final class User {
    
    // MARK: - Properties
    
    /// Unique identifier for the user
    @Attribute(.unique) var id: String
    
    /// User's email address (used for authentication)
    var email: String
    
    /// User's first name
    var firstName: String
    
    /// User's last name
    var lastName: String
    
    /// User's phone number (optional)
    var phoneNumber: String?
    
    /// URL to user's profile image (optional)
    var profileImageURL: String?
    
    /// Date when the user account was created
    var createdAt: Date
    
    /// Date when the user account was last updated
    var updatedAt: Date
    
    /// Whether the user's email has been verified
    var isVerified: Bool
    
    /// Collection of user's parking sessions
    @Relationship(deleteRule: .cascade, inverse: \ParkingSession.user)
    var parkingSessions: [ParkingSession]?
    
    /// Collection of user's payment methods
    @Relationship(deleteRule: .cascade, inverse: \PaymentMethod.user)
    var paymentMethods: [PaymentMethod]?
    
    // MARK: - Initialization
    
    /// Creates a new user with the specified information.
    /// - Parameters:
    ///   - id: Unique identifier for the user
    ///   - email: User's email address
    ///   - firstName: User's first name
    ///   - lastName: User's last name
    init(id: String, email: String, firstName: String, lastName: String) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isVerified = false
        self.parkingSessions = []
        self.paymentMethods = []
    }
    
    // MARK: - Computed Properties
    
    /// User's full name (first name + last name)
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    /// User's initials for avatar display
    var initials: String {
        let firstInitial = firstName.first?.uppercased() ?? ""
        let lastInitial = lastName.first?.uppercased() ?? ""
        return "\(firstInitial)\(lastInitial)"
    }
    
    /// Whether the user has any active parking sessions
    var hasActiveParking: Bool {
        parkingSessions?.contains { $0.status == .active } ?? false
    }
    
    /// Total number of completed parking sessions
    var totalParkingSessions: Int {
        parkingSessions?.count ?? 0
    }
}

// MARK: - Parking Session Model

/// Represents a parking session for a user.
/// 
/// This model tracks the complete lifecycle of a parking session including
/// location, timing, cost, and payment information.
@Model
final class ParkingSession {
    
    // MARK: - Properties
    
    /// Unique identifier for the parking session
    @Attribute(.unique) var id: String
    
    /// Reference to the user who owns this session
    @Relationship var user: User?
    
    /// User ID for the session owner
    var userId: String
    
    /// Location data for the parking session
    @Relationship var location: LocationData?
    
    /// When the parking session started
    var startTime: Date
    
    /// When the parking session ended (nil if still active)
    var endTime: Date?
    
    /// Duration of the parking session in seconds
    var duration: TimeInterval
    
    /// Cost of the parking session
    var cost: Double
    
    /// Current status of the parking session
    var status: ParkingStatus
    
    /// Reference to the payment method used for this session
    @Relationship var paymentMethod: PaymentMethod?
    
    /// Payment method ID for the session
    var paymentMethodId: String?
    
    /// Additional notes about the parking session
    var notes: String?
    
    /// Date when the session was created
    var createdAt: Date
    
    /// Date when the session was last updated
    var updatedAt: Date
    
    // MARK: - Initialization
    
    /// Creates a new parking session.
    /// - Parameters:
    ///   - id: Unique identifier for the session
    ///   - userId: ID of the user who owns the session
    ///   - location: Location data for the parking spot
    ///   - startTime: When the session started (defaults to current time)
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
    
    // MARK: - Computed Properties
    
    /// Whether the parking session is currently active
    var isActive: Bool {
        status == .active
    }
    
    /// Formatted duration string (e.g., "2h 30m")
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Formatted cost string (e.g., "$5.50")
    var formattedCost: String {
        String(format: "$%.2f", cost)
    }
    
    /// Elapsed time since the session started
    var elapsedTime: TimeInterval {
        endTime?.timeIntervalSince(startTime) ?? Date().timeIntervalSince(startTime)
    }
}

// MARK: - Payment Method Model

/// Represents a payment method for a user.
/// 
/// This model stores credit card information and payment preferences
/// for processing parking payments.
@Model
final class PaymentMethod {
    
    // MARK: - Properties
    
    /// Unique identifier for the payment method
    @Attribute(.unique) var id: String
    
    /// Reference to the user who owns this payment method
    @Relationship var user: User?
    
    /// User ID for the payment method owner
    var userId: String
    
    /// Type of payment card
    var type: PaymentType
    
    /// Last four digits of the card number
    var lastFourDigits: String
    
    /// Expiry month (1-12)
    var expiryMonth: Int
    
    /// Expiry year (4-digit format)
    var expiryYear: Int
    
    /// Name of the cardholder
    var cardholderName: String
    
    /// Whether this is the default payment method
    var isDefault: Bool
    
    /// Date when the payment method was added
    var createdAt: Date
    
    /// Date when the payment method was last updated
    var updatedAt: Date
    
    // MARK: - Initialization
    
    /// Creates a new payment method.
    /// - Parameters:
    ///   - id: Unique identifier for the payment method
    ///   - userId: ID of the user who owns the payment method
    ///   - type: Type of payment card
    ///   - lastFourDigits: Last four digits of the card number
    ///   - expiryMonth: Expiry month (1-12)
    ///   - expiryYear: Expiry year (4-digit format)
    ///   - cardholderName: Name of the cardholder
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
    
    // MARK: - Computed Properties
    
    /// Formatted expiry date string (e.g., "12/25")
    var formattedExpiry: String {
        String(format: "%02d/%d", expiryMonth, expiryYear)
    }
    
    /// Whether the card has expired
    var isExpired: Bool {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)
        
        if currentYear > expiryYear {
            return true
        } else if currentYear == expiryYear && currentMonth > expiryMonth {
            return true
        }
        return false
    }
    
    /// Masked card number for display (e.g., "•••• •••• •••• 1234")
    var maskedCardNumber: String {
        "•••• •••• •••• \(lastFourDigits)"
    }
}

// MARK: - Location Data Model

/// Represents location information for parking spots.
/// 
/// This model stores both coordinate and address information
/// for precise location tracking and display.
@Model
final class LocationData {
    
    // MARK: - Properties
    
    /// Unique identifier for the location
    @Attribute(.unique) var id: String
    
    /// Latitude coordinate
    var latitude: Double
    
    /// Longitude coordinate
    var longitude: Double
    
    /// Street address
    var address: String
    
    /// City name
    var city: String
    
    /// State or province
    var state: String
    
    /// ZIP or postal code
    var zipCode: String
    
    /// Country name
    var country: String
    
    // MARK: - Initialization
    
    /// Creates a new location data object.
    /// - Parameters:
    ///   - latitude: Latitude coordinate
    ///   - longitude: Longitude coordinate
    ///   - address: Street address
    ///   - city: City name
    ///   - state: State or province
    ///   - zipCode: ZIP or postal code
    ///   - country: Country name
    init(latitude: Double, longitude: Double, address: String, city: String, state: String, zipCode: String, country: String) {
        self.id = UUID().uuidString
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.country = country
    }
    
    // MARK: - Computed Properties
    
    /// CoreLocation coordinate for mapping and location services
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// Full address string for display
    var fullAddress: String {
        "\(address), \(city), \(state) \(zipCode), \(country)"
    }
    
    /// Short address string (city, state)
    var shortAddress: String {
        "\(city), \(state)"
    }
    
    /// CLLocation object for distance calculations
    var clLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Enums

/// Represents the status of a parking session.
enum ParkingStatus: String, CaseIterable, Codable {
    case active = "active"
    case completed = "completed"
    case cancelled = "cancelled"
    case expired = "expired"
    
    /// Human-readable display name for the status
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .expired: return "Expired"
        }
    }
    
    /// Color identifier for UI display
    var color: String {
        switch self {
        case .active: return "green"
        case .completed: return "blue"
        case .cancelled: return "red"
        case .expired: return "orange"
        }
    }
    
    /// SF Symbol name for the status
    var iconName: String {
        switch self {
        case .active: return "car.fill"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .expired: return "clock.fill"
        }
    }
}

/// Represents the type of payment card.
enum PaymentType: String, CaseIterable, Codable {
    case visa = "visa"
    case mastercard = "mastercard"
    case amex = "amex"
    case discover = "discover"
    
    /// Human-readable display name for the card type
    var displayName: String {
        switch self {
        case .visa: return "Visa"
        case .mastercard: return "Mastercard"
        case .amex: return "American Express"
        case .discover: return "Discover"
        }
    }
    
    /// SF Symbol name for the card type
    var iconName: String {
        switch self {
        case .visa: return "creditcard.fill"
        case .mastercard: return "creditcard.fill"
        case .amex: return "creditcard.fill"
        case .discover: return "creditcard.fill"
        }
    }
    
    /// Color for the card type in UI
    var color: String {
        switch self {
        case .visa: return "blue"
        case .mastercard: return "red"
        case .amex: return "green"
        case .discover: return "orange"
        }
    }
}
