import Foundation
import SwiftUI
import SwiftData
import CoreLocation

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authService = AuthService()
    
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
    
    func signOut() {
        Task {
            await authService.signOut()
            currentUser = nil
            isAuthenticated = false
        }
    }
    
    func checkAuthenticationStatus() {
        Task {
            if let user = await authService.getCurrentUser() {
                currentUser = user
                isAuthenticated = true
            }
        }
    }
}

@MainActor
class ParkingViewModel: ObservableObject {
    @Published var activeSessions: [ParkingSession] = []
    @Published var parkingHistory: [ParkingSession] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentLocation: CLLocation?
    
    private let parkingService = ParkingService()
    private let locationService = LocationService()
    
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
    
    func endParkingSession(_ session: ParkingSession) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedSession = try await parkingService.endSession(session)
            if let index = activeSessions.firstIndex(where: { $0.id == session.id }) {
                activeSessions.remove(at: index)
            }
            parkingHistory.append(updatedSession)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadParkingHistory() async {
        isLoading = true
        
        do {
            parkingHistory = try await parkingService.getParkingHistory()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func requestLocationPermission() async {
        await locationService.requestPermission()
    }
    
    func getCurrentLocation() async {
        currentLocation = await locationService.getCurrentLocation()
    }
}

@MainActor
class PaymentViewModel: ObservableObject {
    @Published var paymentMethods: [PaymentMethod] = []
    @Published var selectedPaymentMethod: PaymentMethod?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let paymentService = PaymentService()
    
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
            if paymentMethods.count == 1 {
                selectedPaymentMethod = paymentMethod
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func removePaymentMethod(_ paymentMethod: PaymentMethod) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await paymentService.removePaymentMethod(paymentMethod)
            if let index = paymentMethods.firstIndex(where: { $0.id == paymentMethod.id }) {
                paymentMethods.remove(at: index)
            }
            if selectedPaymentMethod?.id == paymentMethod.id {
                selectedPaymentMethod = paymentMethods.first
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func setDefaultPaymentMethod(_ paymentMethod: PaymentMethod) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await paymentService.setDefaultPaymentMethod(paymentMethod)
            for var method in paymentMethods {
                method.isDefault = (method.id == paymentMethod.id)
            }
            selectedPaymentMethod = paymentMethod
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
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
            return success
        } catch {
            errorMessage = error.localizedDescription
            return false
        } finally {
            isLoading = false
        }
    }
}
