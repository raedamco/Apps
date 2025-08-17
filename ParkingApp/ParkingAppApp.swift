import SwiftUI
import SwiftData

@main
struct ParkingAppApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var parkingViewModel = ParkingViewModel()
    @StateObject private var paymentViewModel = PaymentViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(parkingViewModel)
                .environmentObject(paymentViewModel)
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [User.self, ParkingSession.self, PaymentMethod.self])
    }
}
