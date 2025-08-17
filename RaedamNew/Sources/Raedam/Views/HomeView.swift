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
            
            if parkingViewModel.currentLocation != nil {
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
                ActiveParkingCard(session: session) {
                    // Handle tap action
                }
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
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                QuickActionButton(
                    title: "Start Parking",
                    icon: "car.fill",
                    color: .green
                ) {
                    // Start parking action
                }
                
                QuickActionButton(
                    title: "Find Spot",
                    icon: "location.fill",
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
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            if parkingViewModel.parkingHistory.isEmpty {
                Text("No recent parking activity")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
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
            Text("Map Preview")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let firstSession = parkingViewModel.activeSessions.first,
               let location = firstSession.location {
                Map(coordinateRegion: $region, annotationItems: [firstSession]) { session in
                    MapMarker(coordinate: location.coordinate, tint: .green)
                }
                .frame(height: 200)
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            } else {
                Map(coordinateRegion: $region)
                    .frame(height: 200)
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            }
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

struct RecentActivityRow: View {
    let session: ParkingSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let location = session.location {
                    Text(location.address)
                        .font(.subheadline)
                        .lineLimit(1)
                } else {
                    Text("Unknown Location")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text("\(session.startTime, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(session.formattedCost)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(session.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
    }
}

#Preview {
    HomeView()
        .environmentObject(ParkingViewModel())
        .environmentObject(AuthViewModel())
}
