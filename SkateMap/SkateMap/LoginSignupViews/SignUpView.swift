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

    // Animation states
    @State private var headerOpacity: Double = 0
    @State private var photoScale: CGFloat = 0.6
    @State private var fieldsOpacity: Double = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // MARK: - Header
                VStack(spacing: 6) {
                    Text("Join the crew")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Drop pins. Rate spots. Own the map.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .opacity(headerOpacity)
                .padding(.top, 32)
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
                                ZStack {
                                    Circle()
                                        .fill(Color(.tertiarySystemFill))
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 44))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(colors: [.darkblue, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: 3
                                )
                        )

                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.darkblue, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 32, height: 32)
                            Image(systemName: "camera.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(.white)
                        }
                        .offset(x: 2, y: 2)
                    }
                }
                .scaleEffect(photoScale)
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            profileImage = image
                        }
                    }
                }
                .padding(.bottom, 6)

                Text("Add a profile photo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 28)

                // MARK: - Fields
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        Image(systemName: "at")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        TextField("Username", text: $viewModel.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .authField()

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
                        SecureField("Password (6+ characters)", text: $viewModel.password)
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
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                viewModel.isSignUpValid
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
                .disabled(!viewModel.isSignUpValid || isLoading)
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 32)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                headerOpacity = 1
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.25)) {
                photoScale = 1
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                fieldsOpacity = 1
            }
        }
    }
}

#Preview {
    NavigationStack { SignUpView() }
        .environment(AuthService())
}
