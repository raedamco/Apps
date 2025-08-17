//
//  PaymentView.swift
//  Raedam
//
//  Created by Omar Waked on 5/15/21.
//  
//

import SwiftUI

struct PaymentView: View {
    @EnvironmentObject var paymentViewModel: PaymentViewModel
    @State private var showingAddPayment = false
    @State private var selectedPaymentMethod: PaymentMethod?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Payment Methods
                    paymentMethodsSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Recent Transactions
                    recentTransactionsSection
                }
                .padding()
            }
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await paymentViewModel.loadPaymentMethods()
            }
        }
        .onAppear {
            Task {
                await paymentViewModel.loadPaymentMethods()
            }
        }
        .sheet(isPresented: $showingAddPayment) {
            AddPaymentMethodSheet()
        }
        .sheet(item: $selectedPaymentMethod) { paymentMethod in
            PaymentMethodDetailSheet(paymentMethod: paymentMethod)
        }
    }
    
    private var paymentMethodsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Payment Methods")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button("Add New") {
                    showingAddPayment = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if paymentViewModel.paymentMethods.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "creditcard")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text("No Payment Methods")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Add a payment method to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Add Payment Method") {
                        showingAddPayment = true
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(15)
            } else {
                ForEach(paymentViewModel.paymentMethods, id: \.id) { paymentMethod in
                    PaymentMethodCard(paymentMethod: paymentMethod) {
                        selectedPaymentMethod = paymentMethod
                    }
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
                    title: "Add Card",
                    icon: "plus.circle.fill",
                    color: .green
                ) {
                    showingAddPayment = true
                }
                
                QuickActionButton(
                    title: "Set Default",
                    icon: "star.fill",
                    color: .yellow
                ) {
                    if let defaultMethod = paymentViewModel.defaultPaymentMethod {
                        selectedPaymentMethod = defaultMethod
                    }
                }
                
                QuickActionButton(
                    title: "Payment History",
                    icon: "clock.fill",
                    color: .blue
                ) {
                    // Navigate to payment history
                }
                
                QuickActionButton(
                    title: "Settings",
                    icon: "gearshape.fill",
                    color: .gray
                ) {
                    // Navigate to payment settings
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button("See All") {
                    // Navigate to full transaction history
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // Mock transaction data - in real app, this would come from a service
            VStack(spacing: 8) {
                TransactionRow(
                    title: "Parking Session - Downtown",
                    amount: 5.50,
                    date: Date().addingTimeInterval(-3600),
                    status: .completed
                )
                
                TransactionRow(
                    title: "Parking Session - Airport",
                    amount: 12.00,
                    date: Date().addingTimeInterval(-86400),
                    status: .completed
                )
                
                TransactionRow(
                    title: "Parking Session - Mall",
                    amount: 3.25,
                    date: Date().addingTimeInterval(-172800),
                    status: .completed
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
}

struct PaymentMethodCard: View {
    let paymentMethod: PaymentMethod
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: paymentMethod.type.iconName)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("•••• \(paymentMethod.lastFourDigits)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if paymentMethod.isDefault {
                            Text("Default")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(paymentMethod.cardholderName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Expires \(paymentMethod.expiryMonth)/\(paymentMethod.expiryYear)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
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
}

struct TransactionRow: View {
    let title: String
    let amount: Double
    let date: Date
    let status: TransactionStatus
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(String(format: "%.2f", amount))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(status.displayName)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(status.color.opacity(0.2))
                    .foregroundColor(status.color)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
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

struct AddPaymentMethodSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var paymentViewModel: PaymentViewModel
    @State private var cardNumber = ""
    @State private var expiryMonth = ""
    @State private var expiryYear = ""
    @State private var cvv = ""
    @State private var cardholderName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Card Information")) {
                    TextField("Card Number", text: $cardNumber)
                        .keyboardType(.numberPad)
                    
                    HStack {
                        TextField("MM", text: $expiryMonth)
                            .keyboardType(.numberPad)
                            .frame(maxWidth: .infinity)
                        
                        TextField("YYYY", text: $expiryYear)
                            .keyboardType(.numberPad)
                            .frame(maxWidth: .infinity)
                    }
                    
                    TextField("CVV", text: $cvv)
                        .keyboardType(.numberPad)
                        .frame(maxWidth: .infinity)
                }
                
                Section(header: Text("Cardholder Information")) {
                    TextField("Cardholder Name", text: $cardholderName)
                        .textInputAutocapitalization(.words)
                }
            }
            .navigationTitle("Add Payment Method")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Add") {
                    Task {
                        if let month = Int(expiryMonth),
                           let year = Int(expiryYear) {
                            await paymentViewModel.addPaymentMethod(
                                cardNumber: cardNumber,
                                expiryMonth: month,
                                expiryYear: year,
                                cvv: cvv,
                                cardholderName: cardholderName
                            )
                        }
                        dismiss()
                    }
                }
                .disabled(cardNumber.isEmpty || expiryMonth.isEmpty || expiryYear.isEmpty || cvv.isEmpty || cardholderName.isEmpty)
            )
        }
    }
}

struct PaymentMethodDetailSheet: View {
    let paymentMethod: PaymentMethod
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var paymentViewModel: PaymentViewModel
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Payment Method Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Payment Method Details")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        InfoRow(title: "Card Type", value: paymentMethod.type.displayName)
                        InfoRow(title: "Last Four Digits", value: "•••• \(paymentMethod.lastFourDigits)")
                        InfoRow(title: "Expiry Date", value: paymentMethod.formattedExpiry)
                        InfoRow(title: "Cardholder", value: paymentMethod.cardholderName)
                        InfoRow(title: "Default", value: paymentMethod.isDefault ? "Yes" : "No")
                        InfoRow(title: "Added", value: paymentMethod.createdAt, style: .medium)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    
                    // Actions
                    VStack(spacing: 12) {
                        if !paymentMethod.isDefault {
                            Button("Set as Default") {
                                Task {
                                    await paymentViewModel.setDefaultPaymentMethod(paymentMethod)
                                    dismiss()
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        
                        Button("Remove Payment Method") {
                            showingDeleteConfirmation = true
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
            .navigationTitle("Payment Method")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .alert("Remove Payment Method", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) {
                    Task {
                        await paymentViewModel.removePaymentMethod(paymentMethod)
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to remove this payment method? This action cannot be undone.")
            }
        }
    }
}



enum TransactionStatus: String, CaseIterable {
    case completed = "completed"
    case pending = "pending"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .completed: return "Completed"
        case .pending: return "Pending"
        case .failed: return "Failed"
        }
    }
    
    var color: Color {
        switch self {
        case .completed: return .green
        case .pending: return .orange
        case .failed: return .red
        }
    }
}

#Preview {
    PaymentView()
        .environmentObject(PaymentViewModel())
}
