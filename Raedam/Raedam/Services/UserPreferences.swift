//
//  UserPreferences.swift
//  Raedam
//
//  Created by Omar Waked on 5/15/21.
//  
//

import Foundation
import SwiftUI

/// Manages user preferences and settings with persistent storage
@MainActor
final class UserPreferences: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether dark mode is enabled
    @Published var isDarkModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isDarkModeEnabled, forKey: "isDarkModeEnabled")
            updateAppearance()
        }
    }
    
    /// Whether notifications are enabled
    @Published var areNotificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(areNotificationsEnabled, forKey: "areNotificationsEnabled")
        }
    }
    
    /// Whether location services are enabled
    @Published var areLocationServicesEnabled: Bool {
        didSet {
            UserDefaults.standard.set(areLocationServicesEnabled, forKey: "areLocationServicesEnabled")
        }
    }
    
    /// Selected language
    @Published var selectedLanguage: String {
        didSet {
            UserDefaults.standard.set(selectedLanguage, forKey: "selectedLanguage")
        }
    }
    
    /// Selected currency
    @Published var selectedCurrency: String {
        didSet {
            UserDefaults.standard.set(selectedCurrency, forKey: "selectedCurrency")
        }
    }
    
    /// Whether parking reminders are enabled
    @Published var areParkingRemindersEnabled: Bool {
        didSet {
            UserDefaults.standard.set(areParkingRemindersEnabled, forKey: "areParkingRemindersEnabled")
        }
    }
    
    /// Whether payment reminders are enabled
    @Published var arePaymentRemindersEnabled: Bool {
        didSet {
            UserDefaults.standard.set(arePaymentRemindersEnabled, forKey: "arePaymentRemindersEnabled")
        }
    }
    
    /// Whether promotional notifications are enabled
    @Published var arePromotionalNotificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(arePromotionalNotificationsEnabled, forKey: "arePromotionalNotificationsEnabled")
        }
    }
    
    // MARK: - Constants
    
    private let availableLanguages = ["English", "Spanish", "French", "German", "Chinese"]
    private let availableCurrencies = ["USD", "EUR", "GBP", "CAD", "AUD"]
    
    // MARK: - Initialization
    
    init() {
        // Load saved preferences or use defaults
        self.isDarkModeEnabled = UserDefaults.standard.bool(forKey: "isDarkModeEnabled")
        self.areNotificationsEnabled = UserDefaults.standard.bool(forKey: "areNotificationsEnabled")
        self.areLocationServicesEnabled = UserDefaults.standard.bool(forKey: "areLocationServicesEnabled")
        self.selectedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "English"
        self.selectedCurrency = UserDefaults.standard.string(forKey: "selectedCurrency") ?? "USD"
        self.areParkingRemindersEnabled = UserDefaults.standard.bool(forKey: "areParkingRemindersEnabled")
        self.arePaymentRemindersEnabled = UserDefaults.standard.bool(forKey: "arePaymentRemindersEnabled")
        self.arePromotionalNotificationsEnabled = UserDefaults.standard.bool(forKey: "arePromotionalNotificationsEnabled")
        
        // Set default values for new installations
        if !UserDefaults.standard.bool(forKey: "hasSetDefaults") {
            setDefaultPreferences()
        }
        
        // Apply initial appearance
        updateAppearance()
    }
    
    // MARK: - Public Methods
    
    /// Sets default preferences for new installations
    private func setDefaultPreferences() {
        areNotificationsEnabled = true
        areLocationServicesEnabled = true
        areParkingRemindersEnabled = true
        arePaymentRemindersEnabled = true
        arePromotionalNotificationsEnabled = false
        
        UserDefaults.standard.set(true, forKey: "hasSetDefaults")
    }
    
    /// Updates the app's appearance based on dark mode setting
    private func updateAppearance() {
        // This would typically be handled by the main app
        // For now, we'll just store the preference
    }
    
    /// Gets available languages
    var languages: [String] {
        return availableLanguages
    }
    
    /// Gets available currencies
    var currencies: [String] {
        return availableCurrencies
    }
    
    /// Resets all preferences to defaults
    func resetToDefaults() {
        isDarkModeEnabled = false
        areNotificationsEnabled = true
        areLocationServicesEnabled = true
        selectedLanguage = "English"
        selectedCurrency = "USD"
        areParkingRemindersEnabled = true
        arePaymentRemindersEnabled = true
        arePromotionalNotificationsEnabled = false
    }
}
