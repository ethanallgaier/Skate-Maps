//
//  SignUpView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/4/26.
//

import SwiftUI
import PhotosUI

struct SignUpView: View {
    @State var viewModel = SignUpViewModel()
    @Environment(AuthService.self) var authService

    @State private var selectedItem: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("Welcome to\nSkateMap")
                    .font(.system(size: 36, design: .serif))
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)
                    .padding(.bottom, 28)

                // MARK: - Profile Picture
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    ZStack(alignment: .bottomTrailing) {
                        Group {
                            if let image = profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.background, lineWidth: 3))

                        Circle()
                            .fill(.blue)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                            )
                    }
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            profileImage = image
                        }
                    }
                }
                .padding(.bottom, 8)

                Text("Add a profile photo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 32)

                // MARK: - Fields
                VStack(spacing: 14) {
                    TextField("Username", text: $viewModel.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .styledField()

                    TextField("Email address", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .styledField()

                    SecureField("Password (6+ characters)", text: $viewModel.password)
                        .styledField()
                }
                .padding(.horizontal, 24)

                if !authService.errorMessage.isEmpty {
                    Text(authService.errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding(.top, 8)
                        .padding(.horizontal, 24)
                }

                Spacer().frame(height: 40)

                // MARK: - Sign Up Button
                Button {
                    viewModel.isValid = true
                    guard viewModel.isSignUpValid else { return }
                    isLoading = true
                    Task {
                        await authService.signUp(
                            email: viewModel.email,
                            password: viewModel.password,
                            username: viewModel.username,
                            profileImage: profileImage
                        )
                        isLoading = false
                    }
                } label: {
                    ZStack {
                        Text("Create Account")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.isSignUpValid ? Color.blue : Color.gray.opacity(0.4))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .opacity(isLoading ? 0 : 1)
                        if isLoading {
                            ProgressView().tint(.blue)
                        }
                    }
                }
                .disabled(!viewModel.isSignUpValid || isLoading)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

// MARK: - TextField Modifier
private extension View {
    func styledField() -> some View {
        self
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack { SignUpView() }
        .environment(AuthService())
}

#Preview {
    NavigationStack {
        SignUpView()
    }
    .environment(AuthService())
}
