import SwiftUI

struct AuthView: View {
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var showingForgotPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        headerSection
                        
                        // Form
                        formSection
                        
                        // Action Buttons
                        actionButtonsSection
                        
                        // Toggle between Sign In and Sign Up
                        toggleSection
                        
                        // Additional Options
                        additionalOptionsSection
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 50)
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordSheet()
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "car.fill")
                .font(.system(size: 80))
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                Text("Parking App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(isSignUp ? "Create your account" : "Welcome back")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }
    
    private var formSection: some View {
        VStack(spacing: 20) {
            if isSignUp {
                // First Name and Last Name
                HStack(spacing: 16) {
                    CustomTextField(
                        text: $firstName,
                        placeholder: "First Name",
                        icon: "person.fill"
                    )
                    
                    CustomTextField(
                        text: $lastName,
                        placeholder: "Last Name",
                        icon: "person.fill"
                    )
                }
            }
            
            // Email
            CustomTextField(
                text: $email,
                placeholder: "Email",
                icon: "envelope.fill",
                keyboardType: .emailAddress
            )
            
            // Password
            CustomSecureField(
                text: $password,
                placeholder: "Password",
                icon: "lock.fill"
            )
            
            // Confirm Password (Sign Up only)
            if isSignUp {
                CustomSecureField(
                    text: $confirmPassword,
                    placeholder: "Confirm Password",
                    icon: "lock.fill"
                )
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Main Action Button
            Button(action: {
                Task {
                    await performAuthentication()
                }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isFormValid ? Color.white : Color.white.opacity(0.3))
                .foregroundColor(isFormValid ? Color.blue : Color.white.opacity(0.7))
                .cornerRadius(25)
            }
            .disabled(!isFormValid || isLoading)
            
            // Forgot Password (Sign In only)
            if !isSignUp {
                Button("Forgot Password?") {
                    showingForgotPassword = true
                }
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            }
        }
    }
    
    private var toggleSection: some View {
        HStack {
            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Button(isSignUp ? "Sign In" : "Sign Up") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isSignUp.toggle()
                    resetForm()
                }
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
        }
    }
    
    private var additionalOptionsSection: some View {
        VStack(spacing: 20) {
            // Divider
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.white.opacity(0.3))
                
                Text("or")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.white.opacity(0.3))
            }
            
            // Social Sign In Options
            VStack(spacing: 12) {
                SocialSignInButton(
                    title: "Continue with Apple",
                    icon: "applelogo",
                    backgroundColor: .black
                ) {
                    // Apple Sign In
                }
                
                SocialSignInButton(
                    title: "Continue with Google",
                    icon: "globe",
                    backgroundColor: .red
                ) {
                    // Google Sign In
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        if isSignUp {
            return !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty &&
                   !firstName.isEmpty && !lastName.isEmpty &&
                   password == confirmPassword && password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    private func performAuthentication() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if isSignUp {
                await authViewModel.signUp(
                    email: email,
                    password: password,
                    firstName: firstName,
                    lastName: lastName
                )
            } else {
                await authViewModel.signIn(
                    email: email,
                    password: password
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func resetForm() {
        email = ""
        password = ""
        confirmPassword = ""
        firstName = ""
        lastName = ""
        errorMessage = nil
    }
}

struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                .foregroundColor(.white)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder)
                        .foregroundColor(.white.opacity(0.6))
                }
        }
        .padding()
        .background(Color.white.opacity(0.2))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

struct CustomSecureField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    @State private var isSecured = true
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 20)
            
            if isSecured {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .foregroundColor(.white.opacity(0.6))
                    }
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .foregroundColor(.white.opacity(0.6))
                    }
            }
            
            Button(action: {
                isSecured.toggle()
            }) {
                Image(systemName: isSecured ? "eye.slash" : "eye")
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .background(Color.white.opacity(0.2))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SocialSignInButton: View {
    let title: String
    let icon: String
    let backgroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundColor)
            .cornerRadius(25)
        }
    }
}

struct ForgotPasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 8) {
                        Text("Forgot Password?")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Enter your email address and we'll send you a link to reset your password.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    Button(action: {
                        Task {
                            await resetPassword()
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Send Reset Link")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(email.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(email.isEmpty || isLoading)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .alert("Success", isPresented: $showingSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("If an account with that email exists, we've sent a password reset link.")
            }
        }
    }
    
    private func resetPassword() async {
        isLoading = true
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        isLoading = false
        showingSuccess = true
    }
}

// MARK: - Extensions
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
}
