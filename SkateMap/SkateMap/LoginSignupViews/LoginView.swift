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

    // Animation states
    @State private var boardOffset: CGFloat = -200
    @State private var boardRotation: Double = -30
    @State private var titleOpacity: Double = 0
    @State private var fieldsOpacity: Double = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    // MARK: - Animated Header
                    VStack(spacing: 8) {
                        Image(systemName: "skateboard.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.darkblue)
                            .rotationEffect(.degrees(boardRotation))
                            .offset(x: boardOffset)

                        Text("Skate Maps")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("Find. Ride. Share.")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .opacity(titleOpacity)
                    .padding(.top, 60)
                    .padding(.bottom, 40)

                    // MARK: - Fields
                    VStack(spacing: 14) {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(.secondary)
                                .frame(width: 20)
                            TextField("Email address", text: $viewModel.email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        .authField()

                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.secondary)
                                .frame(width: 20)
                            SecureField("Password", text: $viewModel.password)
                        }
                        .authField()
                    }
                    .padding(.horizontal, 24)
                    .opacity(fieldsOpacity)

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
                            .foregroundStyle(.darkblue)
                    }
                    .padding(.top, 14)

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
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    viewModel.isLoginValid
                                        ? AnyShapeStyle(LinearGradient(colors: [.darkblue, .blue], startPoint: .leading, endPoint: .trailing))
                                        : AnyShapeStyle(Color.gray.opacity(0.35))
                                )
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .opacity(isLoading ? 0 : 1)
                            if isLoading {
                                ProgressView().tint(.white)
                            }
                        }
                    }
                    .disabled(!viewModel.isLoginValid || isLoading)
                    .padding(.horizontal, 24)
                    .padding(.top, 28)

                    // MARK: - Browse as Guest
                    Button {
                        authService.enterGuestMode()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "eye.fill")
                                .font(.caption)
                            Text("Browse as Guest")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.darkblue)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color(.secondarySystemFill))
                        .clipShape(Capsule())
                    }
                    .padding(.top, 20)
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
                    .foregroundStyle(.darkblue)
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
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.1)) {
                    boardOffset = 0
                    boardRotation = 0
                }
                withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                    titleOpacity = 1
                }
                withAnimation(.easeOut(duration: 0.5).delay(0.55)) {
                    fieldsOpacity = 1
                }
            }
        }
    }
}

// MARK: - Shared Auth Field Modifier
extension View {
    func authField() -> some View {
        self
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    LoginView()
        .environment(AuthService())
}
