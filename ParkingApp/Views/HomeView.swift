import SwiftUI
import MapKit

struct HomeView: View {
    @EnvironmentObject var parkingViewModel: ParkingViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Active Parking Session
                    if !parkingViewModel.activeSessions.isEmpty {
                        activeParkingSection
                    }
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Recent Activity
                    recentActivitySection
                    
                    // Map Preview
                    mapPreviewSection
                }
                .padding()
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await refreshData()
            }
        }
        .onAppear {
            Task {
                await parkingViewModel.requestLocationPermission()
                await parkingViewModel.getCurrentLocation()
                await parkingViewModel.loadParkingHistory()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Welcome back,")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text(authViewModel.currentUser?.firstName ?? "User")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                Button(action: {
                    // Profile action
                }) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                }
            }
            
            if let location = parkingViewModel.currentLocation {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.red)
                    Text("San Francisco, CA")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    private var activeParkingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "car.fill")
                    .foregroundColor(.green)
                Text("Active Parking")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(parkingViewModel.activeSessions.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            
            ForEach(parkingViewModel.activeSessions, id: \.id) { session in
                ActiveParkingCard(session: session)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionButton(
                    title: "Start Parking",
                    icon: "car.fill",
                    color: .green
                ) {
                    // Start parking action
                }
                
                QuickActionButton(
                    title: "Find Spot",
                    icon: "magnifyingglass",
                    color: .blue
                ) {
                    // Find spot action
                }
                
                QuickActionButton(
                    title: "Payment",
                    icon: "creditcard.fill",
                    color: .orange
                ) {
                    // Payment action
                }
                
                QuickActionButton(
                    title: "History",
                    icon: "clock.fill",
                    color: .purple
                ) {
                    // History action
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button("See All") {
                    // Navigate to full history
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if parkingViewModel.parkingHistory.isEmpty {
                Text("No recent parking sessions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(parkingViewModel.parkingHistory.prefix(3), id: \.id) { session in
                    RecentActivityRow(session: session)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    private var mapPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nearby Parking")
                .font(.headline)
                .fontWeight(.semibold)
            
            Map(coordinateRegion: $region, annotationItems: parkingViewModel.activeSessions) { session in
                MapMarker(coordinate: session.location.coordinate, tint: .green)
            }
            .frame(height: 200)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    private func refreshData() async {
        await parkingViewModel.loadParkingHistory()
        await parkingViewModel.getCurrentLocation()
    }
}

struct ActiveParkingCard: View {
    let session: ParkingSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.location.address)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("Started \(session.startTime, style: .relative) ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("End") {
                // End parking action
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.red)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecentActivityRow: View {
    let session: ParkingSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.location.address)
                    .font(.subheadline)
                    .lineLimit(1)
                
                Text("\(session.startTime, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(String(format: "%.2f", session.cost))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(session.status.displayName)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(session.status.color).opacity(0.2))
                    .foregroundColor(Color(session.status.color))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
        .environmentObject(ParkingViewModel())
        .environmentObject(PaymentViewModel())
}
