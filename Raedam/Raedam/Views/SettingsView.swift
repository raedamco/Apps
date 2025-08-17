//
//  SettingsView.swift
//  Raedam
//
//  Created by Omar Waked on 5/15/21.
//  
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var userPreferences: UserPreferences
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingLanguagePicker = false
    @State private var showingCurrencyPicker = false
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section("Profile") {
                    profileSection
                }
                
                // Preferences Section
                Section("Preferences") {
                    preferencesSection
                }
                
                // Notifications Section
                Section("Notifications") {
                    notificationsSection
                }
                
                // Privacy & Security Section
                Section("Privacy & Security") {
                    privacySecuritySection
                }
                
                // Support Section
                Section("Support") {
                    supportSection
                }
                
                // Account Section
                Section("Account") {
                    accountSection
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    // Delete account action
                }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
        }
    }
    
    private var profileSection: some View {
        Group {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(authViewModel.currentUser?.fullName ?? "User Name")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(authViewModel.currentUser?.email ?? "user@example.com")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Edit") {
                    // Edit profile action
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            .padding(.vertical, 8)
            
            NavigationLink(destination: ProfileEditView()) {
                SettingsRow(
                    icon: "person.fill",
                    iconColor: .blue,
                    title: "Edit Profile",
                    subtitle: "Update your personal information"
                )
            }
            
            NavigationLink(destination: Text("Change Password View")) {
                SettingsRow(
                    icon: "lock.fill",
                    iconColor: .green,
                    title: "Change Password",
                    subtitle: "Update your password"
                )
            }
        }
    }
    
    private var preferencesSection: some View {
        Group {
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text("Language")
                Spacer()
                Text(userPreferences.selectedLanguage)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showingLanguagePicker = true
            }
            
            HStack {
                Image(systemName: "dollarsign.circle")
                    .foregroundColor(.green)
                    .frame(width: 24)
                
                Text("Currency")
                Spacer()
                Text(userPreferences.selectedCurrency)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showingCurrencyPicker = true
            }
            
            HStack {
                Image(systemName: "moon.fill")
                    .foregroundColor(.purple)
                    .frame(width: 24)
                
                Text("Dark Mode")
                Spacer()
                Toggle("", isOn: $userPreferences.isDarkModeEnabled)
            }
        }
        .sheet(isPresented: $showingLanguagePicker) {
            LanguagePickerView(selectedLanguage: $userPreferences.selectedLanguage)
        }
        .sheet(isPresented: $showingCurrencyPicker) {
            CurrencyPickerView(selectedCurrency: $userPreferences.selectedCurrency)
        }
    }
    
    private var notificationsSection: some View {
        Group {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.orange)
                    .frame(width: 24)
                
                Text("Push Notifications")
                Spacer()
                Toggle("", isOn: $userPreferences.areNotificationsEnabled)
            }
            
            if userPreferences.areNotificationsEnabled {
                NavigationLink(destination: NotificationSettingsView()) {
                    SettingsRow(
                        icon: "gear",
                        iconColor: .gray,
                        title: "Notification Settings",
                        subtitle: "Customize notification preferences"
                    )
                }
            }
        }
    }
    
    private var privacySecuritySection: some View {
        Group {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.red)
                    .frame(width: 24)
                
                Text("Location Services")
                Spacer()
                Toggle("", isOn: $userPreferences.areLocationServicesEnabled)
            }
            
            NavigationLink(destination: PrivacyPolicyView()) {
                SettingsRow(
                    icon: "hand.raised.fill",
                    iconColor: .blue,
                    title: "Privacy Policy",
                    subtitle: "Read our privacy policy"
                )
            }
            
            NavigationLink(destination: TermsOfServiceView()) {
                SettingsRow(
                    icon: "doc.text.fill",
                    iconColor: .gray,
                    title: "Terms of Service",
                    subtitle: "Read our terms of service"
                )
            }
            
            NavigationLink(destination: DataUsageView()) {
                SettingsRow(
                    icon: "chart.bar.fill",
                    iconColor: .green,
                    title: "Data Usage",
                    subtitle: "Manage your data usage"
                )
            }
        }
    }
    
    private var supportSection: some View {
        Group {
            NavigationLink(destination: HelpCenterView()) {
                SettingsRow(
                    icon: "questionmark.circle.fill",
                    iconColor: .blue,
                    title: "Help Center",
                    subtitle: "Get help and support"
                )
            }
            
            NavigationLink(destination: ContactSupportView()) {
                SettingsRow(
                    icon: "message.fill",
                    iconColor: .green,
                    title: "Contact Support",
                    subtitle: "Get in touch with our team"
                )
            }
            
            NavigationLink(destination: FeedbackView()) {
                SettingsRow(
                    icon: "star.fill",
                    iconColor: .yellow,
                    title: "Send Feedback",
                    subtitle: "Help us improve the app"
                )
            }
            
            NavigationLink(destination: AboutView()) {
                SettingsRow(
                    icon: "info.circle.fill",
                    iconColor: .gray,
                    title: "About",
                    subtitle: "App version and information"
                )
            }
            
            Button(action: {
                userPreferences.resetToDefaults()
            }) {
                SettingsRow(
                    icon: "arrow.clockwise",
                    iconColor: .orange,
                    title: "Reset Preferences",
                    subtitle: "Reset all settings to defaults"
                )
            }
            .foregroundColor(.primary)
        }
    }
    
    private var accountSection: some View {
        Group {
            Button(action: {
                showingSignOutAlert = true
            }) {
                SettingsRow(
                    icon: "rectangle.portrait.and.arrow.right",
                    iconColor: .orange,
                    title: "Sign Out",
                    subtitle: "Sign out of your account"
                )
            }
            .foregroundColor(.primary)
            
            Button(action: {
                showingDeleteAccountAlert = true
            }) {
                SettingsRow(
                    icon: "trash.fill",
                    iconColor: .red,
                    title: "Delete Account",
                    subtitle: "Permanently delete your account"
                )
            }
            .foregroundColor(.red)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Placeholder Views
struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phoneNumber = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Personal Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") { dismiss() }
            )
        }
    }
}

struct NotificationSettingsView: View {
    @State private var parkingReminders = true
    @State private var paymentReminders = true
    @State private var promotionalNotifications = false
    
    var body: some View {
        Form {
            Section("Parking") {
                Toggle("Parking Reminders", isOn: $parkingReminders)
                Toggle("Session Expiry Alerts", isOn: $parkingReminders)
            }
            
            Section("Payments") {
                Toggle("Payment Due Reminders", isOn: $paymentReminders)
                Toggle("Transaction Confirmations", isOn: $paymentReminders)
            }
            
            Section("General") {
                Toggle("Promotional Notifications", isOn: $promotionalNotifications)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Last updated: January 2024")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Your privacy is important to us. This privacy policy explains how we collect, use, and protect your personal information.")
                    .font(.body)
                
                Text("Information We Collect")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("We collect information you provide directly to us, such as when you create an account, use our services, or contact us for support.")
                    .font(.body)
                
                Text("How We Use Your Information")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("We use the information we collect to provide, maintain, and improve our services, process transactions, and communicate with you.")
                    .font(.body)
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Last updated: January 2024")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("By using our parking app, you agree to these terms of service.")
                    .font(.body)
                
                Text("Acceptance of Terms")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("By accessing or using our services, you agree to be bound by these terms and all applicable laws and regulations.")
                    .font(.body)
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataUsageView: View {
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Data Usage")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Manage how your data is used")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 16) {
                DataUsageCard(
                    title: "Location Data",
                    description: "Used for parking location and navigation",
                    isEnabled: true
                )
                
                DataUsageCard(
                    title: "Analytics",
                    description: "Help us improve the app",
                    isEnabled: true
                )
                
                DataUsageCard(
                    title: "Crash Reports",
                    description: "Help fix app issues",
                    isEnabled: false
                )
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Data Usage")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataUsageCard: View {
    let title: String
    let description: String
    @State var isEnabled: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct HelpCenterView: View {
    var body: some View {
        List {
            Section("Getting Started") {
                NavigationLink("How to Start Parking") {
                    Text("Help content for starting parking")
                }
                NavigationLink("Adding Payment Methods") {
                    Text("Help content for payment methods")
                }
            }
            
            Section("Troubleshooting") {
                NavigationLink("Common Issues") {
                    Text("Common issues and solutions")
                }
                NavigationLink("App Not Working") {
                    Text("Troubleshooting guide")
                }
            }
        }
        .navigationTitle("Help Center")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ContactSupportView: View {
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Contact Support")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("We're here to help")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 16) {
                ContactOptionCard(
                    icon: "message.fill",
                    title: "Live Chat",
                    description: "Chat with our support team",
                    action: { }
                )
                
                ContactOptionCard(
                    icon: "envelope.fill",
                    title: "Email Support",
                    description: "Send us an email",
                    action: { }
                )
                
                ContactOptionCard(
                    icon: "phone.fill",
                    title: "Phone Support",
                    description: "Call us directly",
                    action: { }
                )
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ContactOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var feedbackText = ""
    @State private var rating = 5
    @State private var category = "General"
    
    private let categories = ["General", "Bug Report", "Feature Request", "Performance", "UI/UX"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Rating") {
                    HStack {
                        Text("Rate your experience")
                        Spacer()
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .onTapGesture {
                                    rating = star
                                }
                        }
                    }
                }
                
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Feedback") {
                    TextField("Tell us what you think...", text: $feedbackText, axis: .vertical)
                        .lineLimit(5...10)
                }
            }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Send") { dismiss() }
                    .disabled(feedbackText.isEmpty)
            )
        }
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "car.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("Parking App")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 16) {
                AboutRow(title: "Developer", value: "Your Company")
                AboutRow(title: "Copyright", value: "© 2024 Your Company")
                AboutRow(title: "Build", value: "1.0.0 (1)")
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutRow: View {
    let title: String
    let value: String
    
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
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}
