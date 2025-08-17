//
//  ParkingView.swift
//  Raedam
//
//  Created by Omar Waked on 5/15/21.
//  
//

import SwiftUI
import MapKit
import CoreLocation

struct ParkingView: View {
    @EnvironmentObject var parkingViewModel: ParkingViewModel
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var showingStartParking = false
    @State private var selectedSession: ParkingSession?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Map Section
                    mapSection
                    
                    // Parking Controls
                    parkingControlsSection
                    
                    // Active Sessions
                    if !parkingViewModel.activeSessions.isEmpty {
                        activeSessionsSection
                    }
                    
                    // Parking History
                    parkingHistorySection
                }
                .padding()
            }
            .navigationTitle("Parking")
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
        .sheet(isPresented: $showingStartParking) {
            StartParkingSheet()
        }
        .sheet(item: $selectedSession) { session in
            ParkingSessionDetailSheet(session: session)
        }
    }
    
    private var mapSection: some View {
        Map(coordinateRegion: $region, annotationItems: parkingViewModel.activeSessions.filter { $0.location != nil }) { session in
            MapAnnotation(coordinate: session.location!.coordinate) {
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
                ActiveParkingCard(session: session) {
                    selectedSession = session
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    private var parkingHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Sessions")
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
                ForEach(parkingViewModel.parkingHistory.prefix(5), id: \.id) { session in
                    ParkingHistoryRow(session: session)
                }
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

struct ParkingAnnotationView: View {
    let session: ParkingSession
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "car.fill")
                .font(.title2)
                .foregroundColor(.green)
                .background(
                    Circle()
                        .fill(.white)
                        .frame(width: 40, height: 40)
                )
            
            Text(session.location?.address ?? "Unknown")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 2)
        }
    }
}

struct ActiveParkingCard: View {
    let session: ParkingSession
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let location = session.location {
                        Text(location.address)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    } else {
                        Text("Unknown Location")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Started \(session.startTime, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(session.formattedCost)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    Text(session.formattedDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ParkingHistoryRow: View {
    let session: ParkingSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let location = session.location {
                    Text(location.address)
                        .font(.subheadline)
                        .fontWeight(.medium)
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
                
                HStack(spacing: 4) {
                    Text(session.status.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(session.status.color).opacity(0.2))
                        .foregroundColor(Color(session.status.color))
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
    }
}

struct StartParkingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var parkingViewModel: ParkingViewModel
    @State private var address = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Start Parking Session")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location Address")
                        .font(.headline)
                    
                    TextField("Enter address", text: $address)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                if let location = parkingViewModel.currentLocation {
                    Text("Current coordinates: \(location.coordinate.latitude, specifier: "%.4f"), \(location.coordinate.longitude, specifier: "%.4f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Start Parking") {
                    Task {
                        if let location = parkingViewModel.currentLocation {
                            await parkingViewModel.startParkingSession(at: location, address: address.isEmpty ? "Current Location" : address)
                        }
                        dismiss()
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
                .disabled(parkingViewModel.currentLocation == nil)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
}

struct ParkingSessionDetailSheet: View {
    let session: ParkingSession
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var parkingViewModel: ParkingViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Session Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Session Details")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let location = session.location {
                            InfoRow(title: "Address", value: location.address)
                            InfoRow(title: "City", value: location.city)
                            InfoRow(title: "State", value: location.state)
                        }
                        
                        InfoRow(title: "Start Time", value: session.startTime, style: .medium)
                        InfoRow(title: "Duration", value: session.formattedDuration)
                        InfoRow(title: "Cost", value: session.formattedCost)
                        InfoRow(title: "Status", value: session.status.displayName)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    
                    // Actions
                    if session.isActive {
                        Button("End Session") {
                            Task {
                                await parkingViewModel.endParkingSession(session)
                                dismiss()
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Session Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    init(title: String, value: String) {
        self.title = title
        self.value = value
    }
    
    init(title: String, value: Date, style: DateFormatter.Style) {
        self.title = title
        let formatter = DateFormatter()
        formatter.dateStyle = style
        self.value = formatter.string(from: value)
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    ParkingView()
        .environmentObject(ParkingViewModel())
}
