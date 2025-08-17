import SwiftUI
import MapKit
import CoreLocation

struct ParkingView: View {
    @EnvironmentObject var parkingViewModel: ParkingViewModel
    @State private var showingStartParking = false
    @State private var selectedSession: ParkingSession?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Map Section
                mapSection
                
                // Parking Controls
                parkingControlsSection
                
                // Active Sessions
                if !parkingViewModel.activeSessions.isEmpty {
                    activeSessionsSection
                }
                
                Spacer()
            }
            .navigationTitle("Parking")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingStartParking) {
                StartParkingSheet()
            }
            .sheet(item: $selectedSession) { session in
                ParkingSessionDetailSheet(session: session)
            }
        }
        .onAppear {
            Task {
                await parkingViewModel.requestLocationPermission()
                await parkingViewModel.getCurrentLocation()
            }
        }
    }
    
    private var mapSection: some View {
        Map(coordinateRegion: $region, annotationItems: parkingViewModel.activeSessions) { session in
            MapAnnotation(coordinate: session.location.coordinate) {
                ParkingAnnotationView(session: session)
            }
        }
        .frame(height: 300)
        .overlay(
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        Task {
                            await parkingViewModel.getCurrentLocation()
                            if let location = parkingViewModel.currentLocation {
                                region.center = location.coordinate
                            }
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
            }
        )
    }
    
    private var parkingControlsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Button(action: {
                    showingStartParking = true
                }) {
                    HStack {
                        Image(systemName: "car.fill")
                        Text("Start Parking")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    // Find nearby parking
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Find Spot")
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            if let location = parkingViewModel.currentLocation {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.red)
                    Text("Current Location: \(location.coordinate.latitude, specifier: "%.4f"), \(location.coordinate.longitude, specifier: "%.4f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private var activeSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Sessions")
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
                ActiveSessionCard(session: session) {
                    selectedSession = session
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

struct ParkingAnnotationView: View {
    let session: ParkingSession
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "car.fill")
                .font(.title2)
                .foregroundColor(.white)
                .padding(8)
                .background(Color.green)
                .clipShape(Circle())
            
            Text("$\(String(format: "%.2f", session.cost))")
                .font(.caption2)
                .fontWeight(.semibold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.white)
                .foregroundColor(.green)
                .clipShape(Capsule())
        }
    }
}

struct ActiveSessionCard: View {
    let session: ParkingSession
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.location.address)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    Text("Started \(session.startTime, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Cost: $\(String(format: "%.2f", session.cost))")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatDuration(session.startTime))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Duration")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDuration(_ startTime: Date) -> String {
        let duration = Date().timeIntervalSince(startTime)
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct StartParkingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var parkingViewModel: ParkingViewModel
    @State private var address = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Start Parking Session")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter the address where you're parking")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Address")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    TextField("Enter parking address", text: $address)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)
                }
                
                if let location = parkingViewModel.currentLocation {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Location")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Text("\(location.coordinate.latitude, specifier: "%.4f"), \(location.coordinate.longitude, specifier: "%.4f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await startParking()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Start Parking")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(address.isEmpty ? Color.gray : Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(address.isEmpty || isLoading)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Start") {
                    Task {
                        await startParking()
                    }
                }
                .disabled(address.isEmpty || isLoading)
            )
        }
    }
    
    private func startParking() async {
        guard let location = parkingViewModel.currentLocation else { return }
        
        isLoading = true
        await parkingViewModel.startParkingSession(at: location, address: address)
        isLoading = false
        
        dismiss()
    }
}

struct ParkingSessionDetailSheet: View {
    let session: ParkingSession
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var parkingViewModel: ParkingViewModel
    @State private var showingEndConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Session Info
                    sessionInfoSection
                    
                    // Location Details
                    locationSection
                    
                    // Cost Breakdown
                    costSection
                    
                    // Actions
                    actionsSection
                }
                .padding()
            }
            .navigationTitle("Parking Session")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .alert("End Parking Session", isPresented: $showingEndConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("End Session", role: .destructive) {
                    Task {
                        await endSession()
                    }
                }
            } message: {
                Text("Are you sure you want to end this parking session? This action cannot be undone.")
            }
        }
    }
    
    private var sessionInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                InfoRow(title: "Status", value: session.status.displayName, color: Color(session.status.color))
                InfoRow(title: "Started", value: session.startTime.formatted(date: .abbreviated, time: .shortened))
                InfoRow(title: "Duration", value: formatDuration(session.startTime))
                if let endTime = session.endTime {
                    InfoRow(title: "Ended", value: endTime.formatted(date: .abbreviated, time: .shortened))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(session.location.address)
                    .font(.subheadline)
                
                Text("\(session.location.city), \(session.location.state) \(session.location.zipCode)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var costSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cost")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Text("Total Cost")
                    .font(.subheadline)
                Spacer()
                Text("$\(String(format: "%.2f", session.cost))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            if session.status == .active {
                Button(action: {
                    showingEndConfirmation = true
                }) {
                    Text("End Parking Session")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            
            Button(action: {
                // Share session details
            }) {
                Text("Share Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
    }
    
    private func formatDuration(_ startTime: Date) -> String {
        let duration = Date().timeIntervalSince(startTime)
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func endSession() async {
        await parkingViewModel.endParkingSession(session)
        dismiss()
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    var color: Color = .primary
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

#Preview {
    ParkingView()
        .environmentObject(ParkingViewModel())
}
