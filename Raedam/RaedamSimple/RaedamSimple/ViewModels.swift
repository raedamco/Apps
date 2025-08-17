//
//  ViewModels.swift
//  Raedam
//
//  Created by Omar Waked on 8/16/25.
//  Updated and refactored for modern Swift and iOS development practices.
//

import Foundation
import SwiftUI
import SwiftData
import CoreLocation

// MARK: - Authentication View Model

/// Manages user authentication state and operations.
/// 
/// This view model handles user sign-in, sign-up, sign-out, and authentication
/// status checking. It maintains the current user state and provides
/// authentication-related functionality to the UI.
@MainActor
final class AuthViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether the user is currently authenticated
    @Published var isAuthenticated = false
    
    /// Currently authenticated user (nil if not authenticated)
    @Published var currentUser: User?
    
    /// Whether an authentication operation is in progress
    @Published var isLoading = false
    
    /// Error message from the last authentication operation
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    /// Service for handling authentication operations
    private let authService = AuthService()
    
    // MARK: - Public Methods
    
    /// Signs in a user with email and password.
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.signIn(email: email, password: password)
            currentUser = user
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Signs up a new user with the provided information.
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    ///   - firstName: User's first name
    ///   - lastName: User's last name
    func signUp(email: String, password: String, firstName: String, lastName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.signUp(email: email, password: password, firstName: firstName, lastName: lastName)
            currentUser = user
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Signs out the current user.
    func signOut() {
        Task {
            await authService.signOut()
            currentUser = nil
            isAuthenticated = false
        }
    }
    
    /// Checks the current authentication status and updates the view model.
    func checkAuthenticationStatus() async {
        if let user = await authService.getCurrentUser() {
            currentUser = user
            isAuthenticated = true
        } else {
            currentUser = nil
            isAuthenticated = false
        }
    }
    
    /// Clears any error messages.
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Parking View Model

/// Manages parking sessions and location services.
/// 
/// This view model handles parking session lifecycle, location permissions,
/// and provides parking-related functionality to the UI.
@MainActor
final class ParkingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Currently active parking sessions
    @Published var activeSessions: [ParkingSession] = []
    
    /// Historical parking sessions
    @Published var parkingHistory: [ParkingSession] = []
    
    /// Whether a parking operation is in progress
    @Published var isLoading = false
    
    /// Error message from the last parking operation
    @Published var errorMessage: String?
    
    /// Current user location
    @Published var currentLocation: CLLocation?
    
    /// Whether location services are authorized
    @Published var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    
    // MARK: - Private Properties
    
    /// Service for handling parking operations
    private let parkingService = ParkingService()
    
    /// Service for handling location operations
    private let locationService = LocationService()
    
    // MARK: - Public Methods
    
    /// Starts a new parking session at the specified location.
    /// - Parameters:
    ///   - location: Location where parking is starting
    ///   - address: Human-readable address for the location
    func startParkingSession(at location: CLLocation, address: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await parkingService.startSession(at: location, address: address)
            activeSessions.append(session)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Ends an active parking session.
    /// - Parameter session: The parking session to end
    func endParkingSession(_ session: ParkingSession) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedSession = try await parkingService.endSession(session)
            
            // Remove from active sessions
            if let index = activeSessions.firstIndex(where: { $0.id == session.id }) {
                activeSessions.remove(at: index)
            }
            
            // Add to history
            parkingHistory.append(updatedSession)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Loads the user's parking history.
    func loadParkingHistory() async {
        isLoading = true
        
        do {
            parkingHistory = try await parkingService.getParkingHistory()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Requests permission to use location services.
    func requestLocationPermission() async {
        await locationService.requestPermission()
        locationAuthorizationStatus = locationService.authorizationStatus
    }
    
    /// Gets the current user location.
    func getCurrentLocation() async {
        currentLocation = await locationService.getCurrentLocation()
    }
    
    /// Refreshes all parking data.
    func refreshData() async {
        await loadParkingHistory()
        await getCurrentLocation()
    }
    
    /// Clears any error messages.
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Computed Properties
    
    /// Total cost of all active parking sessions
    var totalActiveCost: Double {
        activeSessions.reduce(0) { $0 + $1.cost }
    }
    
    /// Number of active parking sessions
    var activeSessionCount: Int {
        activeSessions.count
    }
    
    /// Whether the user has any active parking sessions
    var hasActiveSessions: Bool {
        !activeSessions.isEmpty
    }
}

// MARK: - Payment View Model

/// Manages payment methods and payment processing.
/// 
/// This view model handles adding/removing payment methods, setting defaults,
/// and processing payments for parking sessions.
@MainActor
final class PaymentViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// User's payment methods
    @Published var paymentMethods: [PaymentMethod] = []
    
    /// Currently selected payment method
    @Published var selectedPaymentMethod: PaymentMethod?
    
    /// Whether a payment operation is in progress
    @Published var isLoading = false
    
    /// Error message from the last payment operation
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    /// Service for handling payment operations
    private let paymentService = PaymentService()
    
    // MARK: - Public Methods
    
    /// Adds a new payment method.
    /// - Parameters:
    ///   - cardNumber: Credit card number
    ///   - expiryMonth: Expiry month (1-12)
    ///   - expiryYear: Expiry year (4-digit format)
    ///   - cvv: Card verification value
    ///   - cardholderName: Name on the card
    func addPaymentMethod(cardNumber: String, expiryMonth: Int, expiryYear: Int, cvv: String, cardholderName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let paymentMethod = try await paymentService.addPaymentMethod(
                cardNumber: cardNumber,
                expiryMonth: expiryMonth,
                expiryYear: expiryYear,
                cvv: cvv,
                cardholderName: cardholderName
            )
            
            paymentMethods.append(paymentMethod)
            
            // Set as default if it's the first payment method
            if paymentMethods.count == 1 {
                selectedPaymentMethod = paymentMethod
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Removes a payment method.
    /// - Parameter paymentMethod: The payment method to remove
    func removePaymentMethod(_ paymentMethod: PaymentMethod) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await paymentService.removePaymentMethod(paymentMethod)
            
            // Remove from local array
            if let index = paymentMethods.firstIndex(where: { $0.id == paymentMethod.id }) {
                paymentMethods.remove(at: index)
            }
            
            // Update selection if necessary
            if selectedPaymentMethod?.id == paymentMethod.id {
                selectedPaymentMethod = paymentMethods.first
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Sets a payment method as the default.
    /// - Parameter paymentMethod: The payment method to set as default
    func setDefaultPaymentMethod(_ paymentMethod: PaymentMethod) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await paymentService.setDefaultPaymentMethod(paymentMethod)
            
            // Update local state
            for var method in paymentMethods {
                method.isDefault = (method.id == paymentMethod.id)
            }
            
            selectedPaymentMethod = paymentMethod
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Loads the user's payment methods.
    func loadPaymentMethods() async {
        isLoading = true
        
        do {
            paymentMethods = try await paymentService.getPaymentMethods()
            selectedPaymentMethod = paymentMethods.first(where: { $0.isDefault }) ?? paymentMethods.first
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Processes a payment for a parking session.
    /// - Parameters:
    ///   - amount: Payment amount
    ///   - description: Description of the payment
    /// - Returns: Whether the payment was successful
    func processPayment(amount: Double, description: String) async -> Bool {
        guard let paymentMethod = selectedPaymentMethod else {
            errorMessage = "No payment method selected"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let success = try await paymentService.processPayment(
                amount: amount,
                description: description,
                paymentMethod: paymentMethod
            )
            isLoading = false
            return success
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    /// Clears any error messages.
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Computed Properties
    
    /// Number of payment methods
    var paymentMethodCount: Int {
        paymentMethods.count
    }
    
    /// Whether the user has any payment methods
    var hasPaymentMethods: Bool {
        !paymentMethods.isEmpty
    }
    
    /// Default payment method
    var defaultPaymentMethod: PaymentMethod? {
        paymentMethods.first(where: { $0.isDefault })
    }
}
