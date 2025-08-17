import SwiftUI

struct PaymentView: View {
    @EnvironmentObject var paymentViewModel: PaymentViewModel
    @State private var showingAddCard = false
    @State private var selectedPaymentMethod: PaymentMethod?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Payment Methods
                    paymentMethodsSection
                    
                    // Recent Transactions
                    recentTransactionsSection
                    
                    // Quick Actions
                    quickActionsSection
                }
                .padding()
            }
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await paymentViewModel.loadPaymentMethods()
            }
            .sheet(isPresented: $showingAddCard) {
                AddPaymentMethodSheet()
            }
            .sheet(item: $selectedPaymentMethod) { paymentMethod in
                PaymentMethodDetailSheet(paymentMethod: paymentMethod)
            }
        }
        .onAppear {
            Task {
                await paymentViewModel.loadPaymentMethods()
            }
        }
    }
    
    private var paymentMethodsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Payment Methods")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button("Add") {
                    showingAddCard = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if paymentViewModel.paymentMethods.isEmpty {
                emptyPaymentMethodsView
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
    
    private var emptyPaymentMethodsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No Payment Methods")
                .font(.headline)
                .fontWeight(.medium)
            
            Text("Add a payment method to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Add Payment Method") {
                showingAddCard = true
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }
    
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Transactions")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Mock transaction data
            VStack(spacing: 8) {
                TransactionRow(
                    title: "Parking Session",
                    amount: 5.50,
                    date: Date().addingTimeInterval(-3600),
                    status: .completed
                )
                
                TransactionRow(
                    title: "Monthly Parking Pass",
                    amount: 45.00,
                    date: Date().addingTimeInterval(-86400),
                    status: .completed
                )
                
                TransactionRow(
                    title: "Parking Extension",
                    amount: 2.75,
                    date: Date().addingTimeInterval(-7200),
                    status: .pending
                )
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
                    title: "Add Card",
                    icon: "plus.circle.fill",
                    color: .blue
                ) {
                    showingAddCard = true
                }
                
                QuickActionButton(
                    title: "View History",
                    icon: "clock.fill",
                    color: .green
                ) {
                    // View transaction history
                }
                
                QuickActionButton(
                    title: "Billing",
                    icon: "doc.text.fill",
                    color: .orange
                ) {
                    // View billing information
                }
                
                QuickActionButton(
                    title: "Support",
                    icon: "questionmark.circle.fill",
                    color: .purple
                ) {
                    // Contact support
                }
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
                Image(systemName: paymentMethod.type.icon)
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
    @State private var expiryMonth = 1
    @State private var expiryYear = 2024
    @State private var cvv = ""
    @State private var cardholderName = ""
    @State private var isLoading = false
    
    private let months = Array(1...12)
    private let years = Array(2024...2034)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Payment Method")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Enter your card details securely")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 16) {
                        // Card Number
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Card Number")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            TextField("1234 5678 9012 3456", text: $cardNumber)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                        
                        // Expiry and CVV
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Expiry Month")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                
                                Picker("Month", selection: $expiryMonth) {
                                    ForEach(months, id: \.self) { month in
                                        Text("\(month)").tag(month)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Expiry Year")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                
                                Picker("Year", selection: $expiryYear) {
                                    ForEach(years, id: \.self) { year in
                                        Text("\(year)").tag(year)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        
                        // CVV
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CVV")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            TextField("123", text: $cvv)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .frame(maxWidth: 100)
                        }
                        
                        // Cardholder Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cardholder Name")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            TextField("John Doe", text: $cardholderName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.words)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await addPaymentMethod()
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Add Payment Method")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(!isFormValid || isLoading)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Add") {
                    Task {
                        await addPaymentMethod()
                    }
                }
                .disabled(!isFormValid || isLoading)
            )
        }
    }
    
    private var isFormValid: Bool {
        !cardNumber.isEmpty && !cvv.isEmpty && !cardholderName.isEmpty
    }
    
    private func addPaymentMethod() async {
        isLoading = true
        
        await paymentViewModel.addPaymentMethod(
            cardNumber: cardNumber,
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            cvv: cvv,
            cardholderName: cardholderName
        )
        
        isLoading = false
        dismiss()
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
                    // Card Preview
                    cardPreviewSection
                    
                    // Card Details
                    cardDetailsSection
                    
                    // Actions
                    actionsSection
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
                        await removePaymentMethod()
                    }
                }
            } message: {
                Text("Are you sure you want to remove this payment method? This action cannot be undone.")
            }
        }
    }
    
    private var cardPreviewSection: some View {
        VStack(spacing: 16) {
            Image(systemName: paymentMethod.type.icon)
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("•••• \(paymentMethod.lastFourDigits)")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(paymentMethod.cardholderName)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    private var cardDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Card Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                InfoRow(title: "Card Type", value: paymentMethod.type.displayName)
                InfoRow(title: "Last Four Digits", value: paymentMethod.lastFourDigits)
                InfoRow(title: "Expiry Date", value: "\(paymentMethod.expiryMonth)/\(paymentMethod.expiryYear)")
                InfoRow(title: "Cardholder", value: paymentMethod.cardholderName)
                InfoRow(title: "Default", value: paymentMethod.isDefault ? "Yes" : "No")
                InfoRow(title: "Added", value: paymentMethod.createdAt.formatted(date: .abbreviated, time: .omitted))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            if !paymentMethod.isDefault {
                Button(action: {
                    Task {
                        await setAsDefault()
                    }
                }) {
                    Text("Set as Default")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            
            Button(action: {
                showingDeleteConfirmation = true
            }) {
                Text("Remove Card")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
    }
    
    private func setAsDefault() async {
        await paymentViewModel.setDefaultPaymentMethod(paymentMethod)
    }
    
    private func removePaymentMethod() async {
        await paymentViewModel.removePaymentMethod(paymentMethod)
        dismiss()
    }
}

struct InfoRow: View {
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
