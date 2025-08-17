//
//  RaedamApp.swift
//  Raedam
//
//  Created by Omar Waked on 8/16/25.
//  Updated and refactored for modern Swift and iOS development practices.
//

import SwiftUI
import SwiftData

/// Main application entry point for the Raedam parking application.
/// 
/// This app provides a comprehensive parking management solution with features including:
/// - User authentication and account management
/// - Parking session tracking and management
/// - Payment processing and method management
/// - Location services and mapping
/// - Real-time parking status updates
@main
struct RaedamApp: App {
    
    // MARK: - Properties
    
    /// Shared model container for SwiftData persistence
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
    
    // MARK: - View Models
    
    /// Authentication view model for managing user authentication state
    @StateObject private var authViewModel = AuthViewModel()
    
    /// Parking view model for managing parking sessions and location
    @StateObject private var parkingViewModel = ParkingViewModel()
    
    /// Payment view model for managing payment methods and transactions
    @StateObject private var paymentViewModel = PaymentViewModel()
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(parkingViewModel)
                .environmentObject(paymentViewModel)
                .preferredColorScheme(.light)
                .onAppear {
                    setupApp()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    // MARK: - Private Methods
    
    /// Performs initial app setup and configuration
    private func setupApp() {
        // Configure app-wide settings
        configureAppearance()
        
        // Initialize services
        Task {
            await initializeServices()
        }
    }
    
    /// Configures the app's visual appearance
    private func configureAppearance() {
        // Set navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // Set tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    /// Initializes app services asynchronously
    @MainActor
    private func initializeServices() async {
        // Check authentication status
        await authViewModel.checkAuthenticationStatus()
        
        // Load user data if authenticated
        if authViewModel.isAuthenticated {
            await parkingViewModel.loadParkingHistory()
            await paymentViewModel.loadPaymentMethods()
        }
    }
}
