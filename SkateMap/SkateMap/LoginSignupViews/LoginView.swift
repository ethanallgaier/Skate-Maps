//
//  LoginView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/2/26.
//

import SwiftUI

struct LoginView: View {

    @State var viewModel = LoginViewModel()
    @Environment(AuthService.self) var authService

    @State private var isLoading = false
    @State private var showForgotPassword = false
    @State private var resetEmail = ""
    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    Text("Skate Maps")
                        .font(.system(size: 40, design: .serif))
                        .bold()
                        .padding(.top, 80)
                        .padding(.bottom, 48)

                    // MARK: - Fields
                    VStack(spacing: 14) {
                        TextField("Email address", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .styledLoginField()

                        SecureField("Password", text: $viewModel.password)
                            .styledLoginField()
                    }
                    .padding(.horizontal, 24)

                    // MARK: - Error Message
                    if !authService.errorMessage.isEmpty {
                        Text(authService.errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                            .padding(.top, 8)
                            .padding(.horizontal, 24)
                    }

                    // MARK: - Forgot Password
                    Button {
                        resetEmail = viewModel.email
                        showForgotPassword = true
                    } label: {
                        Text("Forgot password?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 16)

                    // MARK: - Login Button
                    Button {
                        isLoading = true
                        Task {
                            await authService.login(email: viewModel.email, password: viewModel.password)
                            isLoading = false
                        }
                    } label: {
                        ZStack {
                            Text("Log In")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(viewModel.isLoginValid ? Color.blue : Color.gray.opacity(0.4))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .opacity(isLoading ? 0 : 1)
                            if isLoading {
                                ProgressView().tint(.blue)
                            }
                        }
                    }
                    .disabled(!viewModel.isLoginValid || isLoading)
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .safeAreaInset(edge: .bottom) {
                // MARK: - Sign Up Link
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .foregroundStyle(.secondary)
                    NavigationLink("Sign Up") {
                        SignUpView()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
                }
                .font(.subheadline)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
            }
            .alert("Reset Password", isPresented: $showForgotPassword) {
                TextField("Email address", text: $resetEmail)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Send Link") {
                    Task {
                        await authService.sendPasswordReset(email: resetEmail)
                        if authService.errorMessage.isEmpty {
                            showResetConfirmation = true
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter your email and we'll send you a link to reset your password.")
            }
            .alert("Check Your Email", isPresented: $showResetConfirmation) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("If an account exists for that email, a password reset link has been sent.")
            }
        }
    }
}

// MARK: - TextField Modifier
private extension View {
    func styledLoginField() -> some View {
        self
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    LoginView()
        .environment(AuthService())
}
