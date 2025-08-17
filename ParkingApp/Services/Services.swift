import Foundation
import CoreLocation
import SwiftData

// MARK: - Auth Service
class AuthService {
    func signIn(email: String, password: String) async throws -> User {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Mock authentication - in real app, this would call Firebase Auth
        guard !email.isEmpty && !password.isEmpty else {
            throw AuthError.invalidCredentials
        }
        
        let user = User(
            id: UUID().uuidString,
            email: email,
            firstName: "John",
            lastName: "Doe"
        )
        
        // Store user in UserDefaults for demo
        UserDefaults.standard.set(email, forKey: "userEmail")
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        
        return user
    }
    
    func signUp(email: String, password: String, firstName: String, lastName: String) async throws -> User {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        guard !email.isEmpty && !password.isEmpty && !firstName.isEmpty && !lastName.isEmpty else {
            throw AuthError.invalidCredentials
        }
        
        let user = User(
            id: UUID().uuidString,
            email: email,
            firstName: firstName,
            lastName: lastName
        )
        
        UserDefaults.standard.set(email, forKey: "userEmail")
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        
        return user
    }
    
    func signOut() async {
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.set(false, forKey: "isAuthenticated")
    }
    
    func getCurrentUser() async -> User? {
        guard UserDefaults.standard.bool(forKey: "isAuthenticated"),
              let email = UserDefaults.standard.string(forKey: "userEmail") else {
            return nil
        }
        
        return User(
            id: UUID().uuidString,
            email: email,
            firstName: "John",
            lastName: "Doe"
        )
    }
}

// MARK: - Parking Service
class ParkingService {
    func startSession(at location: CLLocation, address: String) async throws -> ParkingSession {
        try await Task.sleep(nanoseconds: 500_000_000)
        
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
    
    func endSession(_ session: ParkingSession) async throws -> ParkingSession {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        var updatedSession = session
        updatedSession.endTime = Date()
        updatedSession.duration = updatedSession.endTime!.timeIntervalSince(session.startTime)
        updatedSession.cost = calculateCost(duration: updatedSession.duration)
        updatedSession.status = .completed
        updatedSession.updatedAt = Date()
        
        return updatedSession
    }
    
    func getParkingHistory() async throws -> [ParkingSession] {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Return mock data
        return []
    }
    
    private func calculateCost(duration: TimeInterval) -> Double {
        let hours = duration / 3600
        let baseRate = 2.50 // $2.50 per hour
        return max(baseRate, hours * baseRate)
    }
}

// MARK: - Location Service
class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestPermission() async {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func getCurrentLocation() async -> CLLocation? {
        return await withCheckedContinuation { continuation in
            locationManager.requestLocation()
            
            // For demo purposes, return a mock location
            let mockLocation = CLLocation(
                latitude: 37.7749,
                longitude: -122.4194
            )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                continuation.resume(returning: mockLocation)
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Handle location updates
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
    }
}

// MARK: - Payment Service
class PaymentService {
    func addPaymentMethod(cardNumber: String, expiryMonth: Int, expiryYear: Int, cvv: String, cardholderName: String) async throws -> PaymentMethod {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        guard cardNumber.count >= 13 && cardNumber.count <= 19,
              expiryMonth >= 1 && expiryMonth <= 12,
              expiryYear >= 2024,
              cvv.count >= 3 && cvv.count <= 4,
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
    
    func removePaymentMethod(_ paymentMethod: PaymentMethod) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        // In real app, this would call Stripe API
    }
    
    func setDefaultPaymentMethod(_ paymentMethod: PaymentMethod) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        // In real app, this would call Stripe API
    }
    
    func getPaymentMethods() async throws -> [PaymentMethod] {
        try await Task.sleep(nanoseconds: 500_000_000)
        // Return mock data
        return []
    }
    
    func processPayment(amount: Double, description: String, paymentMethod: PaymentMethod) async throws -> Bool {
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Simulate payment processing
        let random = Int.random(in: 1...10)
        if random == 1 {
            throw PaymentError.paymentFailed
        }
        
        return true
    }
    
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

// MARK: - Errors
enum AuthError: LocalizedError {
    case invalidCredentials
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network error. Please try again."
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

enum PaymentError: LocalizedError {
    case invalidCardDetails
    case paymentFailed
    case insufficientFunds
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidCardDetails:
            return "Invalid card details"
        case .paymentFailed:
            return "Payment failed. Please try again."
        case .insufficientFunds:
            return "Insufficient funds"
        case .networkError:
            return "Network error. Please try again."
        }
    }
}
