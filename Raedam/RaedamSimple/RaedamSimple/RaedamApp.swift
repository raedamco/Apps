import SwiftUI
import SwiftData

@main
struct RaedamApp: App {
    
    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            ParkingSession.self,
            PaymentMethod.self,
            LocationData.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }()
    
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
        .modelContainer(sharedModelContainer)
    }
}
