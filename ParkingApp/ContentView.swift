import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                TabView(selection: $selectedTab) {
                    HomeView()
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Home")
                        }
                        .tag(0)
                    
                    ParkingView()
                        .tabItem {
                            Image(systemName: "car.fill")
                            Text("Parking")
                        }
                        .tag(1)
                    
                    PaymentView()
                        .tabItem {
                            Image(systemName: "creditcard.fill")
                            Text("Payment")
                        }
                        .tag(2)
                    
                    SettingsView()
                        .tabItem {
                            Image(systemName: "gearshape.fill")
                            Text("Settings")
                        }
                        .tag(3)
                }
                .accentColor(.blue)
            } else {
                AuthView()
            }
        }
        .onAppear {
            authViewModel.checkAuthenticationStatus()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(ParkingViewModel())
        .environmentObject(PaymentViewModel())
}
