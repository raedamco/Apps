//
//  Services.swift
//  Raedam
//
//  Created by Omar Waked on 5/15/21.
//  
//

import Foundation
import CoreLocation
import SwiftData

// MARK: - Authentication Service

/// Service for handling user authentication operations.
/// 
/// This service provides methods for user sign-in, sign-up, sign-out,
/// and authentication status checking. Currently uses mock authentication
/// but is designed to be easily replaced with real authentication providers.
final class AuthService {
    
    // MARK: - Private Properties
    
    /// UserDefaults key for storing authentication status
    private let isAuthenticatedKey = "isAuthenticated"
    
    /// UserDefaults key for storing user email
    private let userEmailKey = "userEmail"
    
    /// UserDefaults key for storing user ID
    private let userIdKey = "userId"
    
    /// UserDefaults key for storing user first name
    private let userFirstNameKey = "userFirstName"
    
    /// UserDefaults key for storing user last name
    private let userLastNameKey = "userLastName"
    
    // MARK: - Public Methods
    
    /// Signs in a user with email and password.
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: Authenticated user object
    /// - Throws: AuthError if authentication fails
    func signIn(email: String, password: String) async throws -> User {
        // Simulate network delay for realistic UX
        try await Task.sleep(for: .seconds(1))
        
        // Validate input parameters
        guard !email.isEmpty && !password.isEmpty else {
            throw AuthError.invalidCredentials
        }
        
        // Validate email format
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }
        
        // Mock authentication - in real app, this would call Firebase Auth
        // For demo purposes, we'll use a mock user with a realistic name
        let user = User(
            id: UUID().uuidString,
            email: email,
            firstName: "Omar",
            lastName: "Waked"
        )
        
        // Store authentication state
        await storeAuthenticationState(user: user)
        
        return user
    }
    
    /// Signs up a new user with the provided information.
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    ///   - firstName: User's first name
    ///   - lastName: User's last name
    /// - Returns: Newly created user object
    /// - Throws: AuthError if sign-up fails
    func signUp(email: String, password: String, firstName: String, lastName: String) async throws -> User {
        try await Task.sleep(for: .seconds(1))
        
        // Validate input parameters
        guard !email.isEmpty && !password.isEmpty && !firstName.isEmpty && !lastName.isEmpty else {
            throw AuthError.invalidCredentials
        }
        
        // Validate email format
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }
        
        // Validate password strength
        guard isValidPassword(password) else {
            throw AuthError.weakPassword
        }
        
        // Create new user
        let user = User(
            id: UUID().uuidString,
            email: email,
            firstName: firstName,
            lastName: lastName
        )
        
        // Store authentication state
        await storeAuthenticationState(user: user)
        
        return user
    }
    
    /// Signs out the current user.
    func signOut() async {
        await clearAuthenticationState()
    }
    
    /// Gets the currently authenticated user.
    /// - Returns: Current user object if authenticated, nil otherwise
    func getCurrentUser() async -> User? {
        guard await isUserAuthenticated(),
              let email = UserDefaults.standard.string(forKey: userEmailKey),
              let userId = UserDefaults.standard.string(forKey: userIdKey) else {
            return nil
        }
        
        let firstName = UserDefaults.standard.string(forKey: userFirstNameKey) ?? "User"
        let lastName = UserDefaults.standard.string(forKey: userLastNameKey) ?? "User"
        
        return User(
            id: userId,
            email: email,
            firstName: firstName,
            lastName: lastName
        )
    }
    
    // MARK: - Private Methods
    
    /// Stores authentication state in UserDefaults.
    /// - Parameter user: User to store authentication state for
    @MainActor
    private func storeAuthenticationState(user: User) {
        UserDefaults.standard.set(user.email, forKey: userEmailKey)
        UserDefaults.standard.set(user.id, forKey: userIdKey)
        UserDefaults.standard.set(user.firstName, forKey: userFirstNameKey)
        UserDefaults.standard.set(user.lastName, forKey: userLastNameKey)
        UserDefaults.standard.set(true, forKey: isAuthenticatedKey)
    }
    
    /// Clears authentication state from UserDefaults.
    @MainActor
    private func clearAuthenticationState() {
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: userFirstNameKey)
        UserDefaults.standard.removeObject(forKey: userLastNameKey)
        UserDefaults.standard.set(false, forKey: isAuthenticatedKey)
    }
    
    /// Checks if a user is currently authenticated.
    /// - Returns: Whether the user is authenticated
    private func isUserAuthenticated() async -> Bool {
        UserDefaults.standard.bool(forKey: isAuthenticatedKey)
    }
    
    /// Validates email format using regex.
    /// - Parameter email: Email to validate
    /// - Returns: Whether the email format is valid
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Validates password strength.
    /// - Parameter password: Password to validate
    /// - Returns: Whether the password meets strength requirements
    private func isValidPassword(_ password: String) -> Bool {
        // Minimum 8 characters, at least one letter and one number
        let passwordRegex = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{8,}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return passwordPredicate.evaluate(with: password)
    }
}

// MARK: - Parking Service

/// Service for handling parking session operations.
/// 
/// This service manages the lifecycle of parking sessions including
/// starting, ending, and retrieving parking history.
final class ParkingService {
    
    // MARK: - Private Properties
    
    /// Base hourly rate for parking
    private let baseHourlyRate: Double = 2.50
    
    
    /// Minimum parking cost
    private let minimumCost: Double = 2.50
    
    // MARK: - Public Methods
    
    /// Starts a new parking session at the specified location.
    /// - Parameters:
    ///   - location: Location where parking is starting
    ///   - address: Human-readable address for the location
    /// - Returns: New parking session
    /// - Throws: ParkingError if session creation fails
    func startSession(at location: CLLocation, address: String) async throws -> ParkingSession {
        try await Task.sleep(for: .milliseconds(500))
        
        let locationData = LocationData(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            address: address,
            city: "San Francisco",
            state: "CA",
            zipCode: "94102",
            country: "USA"
        )
        
        let session = ParkingSession(
            id: UUID().uuidString,
            userId: "currentUser",
            location: locationData
        )
        
        return session
    }
    
    /// Ends an active parking session.
    /// - Parameter session: The parking session to end
    /// - Returns: Updated parking session with end time and cost
    /// - Throws: ParkingError if session ending fails
    func endSession(_ session: ParkingSession) async throws -> ParkingSession {
        try await Task.sleep(for: .milliseconds(500))
        
        var updatedSession = session
        updatedSession.endTime = Date()
        updatedSession.duration = updatedSession.endTime!.timeIntervalSince(session.startTime)
        updatedSession.cost = calculateCost(duration: updatedSession.duration)
        updatedSession.status = .completed
        updatedSession.updatedAt = Date()
        
        return updatedSession
    }
    
    /// Retrieves the user's parking history.
    /// - Returns: Array of parking sessions
    /// - Throws: ParkingError if retrieval fails
    func getParkingHistory() async throws -> [ParkingSession] {
        try await Task.sleep(for: .milliseconds(500))
        
        // Return mock data for now
        return []
    }
    
    // MARK: - Private Methods
    
    /// Calculates the cost for a parking session.
    /// - Parameter duration: Duration in seconds
    /// - Returns: Calculated cost
    private func calculateCost(duration: TimeInterval) -> Double {
        let hours = duration / 3600
        let calculatedCost = max(baseHourlyRate, hours * baseHourlyRate)
        return max(minimumCost, calculatedCost)
    }
}

// MARK: - Location Service

/// Service for handling location-related operations.
/// 
/// This service manages location permissions, provides current location,
/// and handles location updates.
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    // MARK: - Published Properties
    
    /// Current authorization status for location services
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    // MARK: - Private Properties
    
    /// Core Location manager for location services
    private let locationManager = CLLocationManager()
    
    /// Continuation for async location requests
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Public Methods
    
    /// Requests permission to use location services.
    func requestPermission() async {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Gets the current user location.
    /// - Returns: Current location or nil if unavailable
    func getCurrentLocation() async -> CLLocation? {
        return await withCheckedContinuation { continuation in
            locationContinuation = continuation
            
            // Check if we already have authorization
            switch authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                locationManager.requestLocation()
            case .denied, .restricted:
                continuation.resume(returning: nil)
            case .notDetermined:
                // Wait for authorization
                continuation.resume(returning: nil)
            @unknown default:
                continuation.resume(returning: nil)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Sets up the location manager with appropriate configuration.
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Resume continuation if waiting for location
        locationContinuation?.resume(returning: location)
        locationContinuation = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        
        // Resume continuation with nil on error
        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
    }
}

// MARK: - Payment Service

/// Service for handling payment operations.
/// 
/// This service manages payment methods, processes payments,
/// and handles payment-related errors.
final class PaymentService {
    
    // MARK: - Public Methods
    
    /// Adds a new payment method.
    /// - Parameters:
    ///   - cardNumber: Credit card number
    ///   - expiryMonth: Expiry month (1-12)
    ///   - expiryYear: Expiry year (4-digit format)
    ///   - cvv: Card verification value
    ///   - cardholderName: Name on the card
    /// - Returns: New payment method object
    /// - Throws: PaymentError if validation fails
    func addPaymentMethod(cardNumber: String, expiryMonth: Int, expiryYear: Int, cvv: String, cardholderName: String) async throws -> PaymentMethod {
        try await Task.sleep(for: .seconds(1))
        
        // Validate card details
        guard isValidCardNumber(cardNumber),
              isValidExpiryDate(month: expiryMonth, year: expiryYear),
              isValidCVV(cvv),
              !cardholderName.isEmpty else {
            throw PaymentError.invalidCardDetails
        }
        
        let lastFourDigits = String(cardNumber.suffix(4))
        let paymentType = determineCardType(from: cardNumber)
        
        let paymentMethod = PaymentMethod(
            id: UUID().uuidString,
            userId: "currentUser",
            type: paymentType,
            lastFourDigits: lastFourDigits,
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            cardholderName: cardholderName
        )
        
        return paymentMethod
    }
    
    /// Removes a payment method.
    /// - Parameter paymentMethod: The payment method to remove
    /// - Throws: PaymentError if removal fails
    func removePaymentMethod(_ paymentMethod: PaymentMethod) async throws {
        try await Task.sleep(for: .milliseconds(500))
        // In real app, this would call Stripe API
    }
    
    /// Sets a payment method as the default.
    /// - Parameter paymentMethod: The payment method to set as default
    /// - Throws: PaymentError if setting default fails
    func setDefaultPaymentMethod(_ paymentMethod: PaymentMethod) async throws {
        try await Task.sleep(for: .milliseconds(500))
        // In real app, this would call Stripe API
    }
    
    /// Retrieves the user's payment methods.
    /// - Returns: Array of payment methods
    /// - Throws: PaymentError if retrieval fails
    func getPaymentMethods() async throws -> [PaymentMethod] {
        try await Task.sleep(for: .milliseconds(500))
        // Return mock data for now
        return []
    }
    
    /// Processes a payment for a parking session.
    /// - Parameters:
    ///   - amount: Payment amount
    ///   - description: Description of the payment
    ///   - paymentMethod: Payment method to use
    /// - Returns: Whether the payment was successful
    /// - Throws: PaymentError if payment fails
    func processPayment(amount: Double, description: String, paymentMethod: PaymentMethod) async throws -> Bool {
        try await Task.sleep(for: .seconds(1.5))
        
        // Validate amount
        guard amount > 0 else {
            throw PaymentError.invalidAmount
        }
        
        // Simulate payment processing with occasional failure
        let random = Int.random(in: 1...10)
        if random == 1 {
            throw PaymentError.paymentFailed
        }
        
        return true
    }
    
    // MARK: - Private Methods
    
    /// Validates credit card number using Luhn algorithm.
    /// - Parameter cardNumber: Card number to validate
    /// - Returns: Whether the card number is valid
    private func isValidCardNumber(_ cardNumber: String) -> Bool {
        let digits = cardNumber.compactMap { $0.wholeNumberValue }
        guard digits.count >= 13 && digits.count <= 19 else { return false }
        
        // Luhn algorithm validation
        var sum = 0
        var isEven = false
        
        for digit in digits.reversed() {
            if isEven {
                let doubled = digit * 2
                sum += doubled > 9 ? doubled - 9 : doubled
            } else {
                sum += digit
            }
            isEven.toggle()
        }
        
        return sum % 10 == 0
    }
    
    /// Validates expiry date.
    /// - Parameters:
    ///   - month: Expiry month (1-12)
    ///   - year: Expiry year (4-digit format)
    /// - Returns: Whether the expiry date is valid
    private func isValidExpiryDate(month: Int, year: Int) -> Bool {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)
        
        guard month >= 1 && month <= 12 else { return false }
        guard year >= currentYear else { return false }
        
        if year == currentYear && month < currentMonth {
            return false
        }
        
        return true
    }
    
    /// Validates CVV code.
    /// - Parameter cvv: CVV to validate
    /// - Returns: Whether the CVV is valid
    private func isValidCVV(_ cvv: String) -> Bool {
        let cvvDigits = cvv.compactMap { $0.wholeNumberValue }
        return cvvDigits.count >= 3 && cvvDigits.count <= 4
    }
    
    /// Determines the card type from the card number.
    /// - Parameter cardNumber: Card number to analyze
    /// - Returns: Determined card type
    private func determineCardType(from cardNumber: String) -> PaymentType {
        let firstDigit = cardNumber.first?.wholeNumberValue ?? 0
        let firstTwoDigits = Int(cardNumber.prefix(2)) ?? 0
        
        switch firstDigit {
        case 4:
            return .visa
        case 5:
            return .mastercard
        case 3:
            if firstTwoDigits == 34 || firstTwoDigits == 37 {
                return .amex
            }
            return .discover
        case 6:
            return .discover
        default:
            return .visa
        }
    }
}

// MARK: - Error Types

/// Authentication-related errors.
enum AuthError: LocalizedError {
    case invalidCredentials
    case invalidEmail
    case weakPassword
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password must be at least 8 characters with letters and numbers"
        case .networkError:
            return "Network error. Please try again."
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

/// Payment-related errors.
enum PaymentError: LocalizedError {
    case invalidCardDetails
    case invalidAmount
    case paymentFailed
    case insufficientFunds
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidCardDetails:
            return "Invalid card details. Please check and try again."
        case .invalidAmount:
            return "Invalid payment amount"
        case .paymentFailed:
            return "Payment failed. Please try again."
        case .insufficientFunds:
            return "Insufficient funds"
        case .networkError:
            return "Network error. Please try again."
        }
    }
}

/// Parking-related errors.
enum ParkingError: LocalizedError {
    case sessionCreationFailed
    case sessionEndFailed
    case locationUnavailable
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .sessionCreationFailed:
            return "Failed to create parking session"
        case .sessionEndFailed:
            return "Failed to end parking session"
        case .locationUnavailable:
            return "Location services unavailable"
        case .networkError:
            return "Network error. Please try again."
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
