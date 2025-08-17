//
//  ContentView.swift
//  Raedam
//
//  Created by Omar Waked on 8/16/25.
//  Updated and refactored for modern Swift and iOS development practices.
//

import SwiftUI

/// Main content view that manages the app's navigation and authentication flow.
/// 
/// This view serves as the root view of the application and handles:
/// - Authentication state management
/// - Tab-based navigation for authenticated users
/// - Authentication view for unauthenticated users
/// - Environment object injection for view models
struct ContentView: View {
    
    // MARK: - Environment Objects
    
    /// Authentication view model for managing user authentication state
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // MARK: - State Properties
    
    /// Currently selected tab index
    @State private var selectedTab = 0
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                authenticatedView
            } else {
                authenticationView
            }
        }
        .onAppear {
            checkAuthenticationStatus()
        }
    }
    
    // MARK: - View Components
    
    /// View displayed when user is authenticated
    private var authenticatedView: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            ParkingView()
                .tabItem {
                    Label("Parking", systemImage: "car.fill")
                }
                .tag(1)
            
            PaymentView()
                .tabItem {
                    Label("Payment", systemImage: "creditcard.fill")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .accentColor(.blue)
        .onAppear {
            loadInitialData()
        }
    }
    
    /// View displayed when user is not authenticated
    private var authenticationView: some View {
        AuthView()
    }
    
    // MARK: - Private Methods
    
    /// Checks the current authentication status
    private func checkAuthenticationStatus() {
        Task {
            await authViewModel.checkAuthenticationStatus()
        }
    }
    
    /// Loads initial data for authenticated users
    private func loadInitialData() {
        // This will be handled by the individual view models
        // when they receive the environment objects
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(ParkingViewModel())
        .environmentObject(PaymentViewModel())
}
