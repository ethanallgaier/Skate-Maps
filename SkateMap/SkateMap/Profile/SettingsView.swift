//
//  SettingsView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/11/26.
//

import SwiftUI
import PhotosUI
import FirebaseAuth

struct SettingsView: View {
    @Environment(AuthService.self) var authService
    @Environment(\.dismiss) var dismiss
    
    @State private var localProfileImage: UIImage?
    @State private var showEditUsername = false
    @State private var showEditBio = false
    @State private var showEditEmail = false
    @State private var showEditPassword = false
    @State private var showDeleteAccount = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var isUploadingPhoto = false
    
    var body: some View {
        List {
            
            // MARK: - Avatar
            Section {
                HStack {
                    Spacer()
                    ZStack(alignment: .bottomTrailing) {
                        PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .not(.livePhotos)])) {
                            profileAvatar
                                .frame(width: 90, height: 90)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.background, lineWidth: 3))
                        }
                        .onChange(of: selectedItem) { _, newItem in
                            print("📸 selectedItem changed: \(String(describing: newItem))")
                            guard let newItem else { return }
                            Task {
                                guard let data = try? await newItem.loadTransferable(type: Data.self),
                                      let image = UIImage(data: data) else {
                                    print("❌ Failed to load image data")
                                    return
                                }
                                localProfileImage = image
                                isUploadingPhoto = true
                                do {
                                    
                                    try await authService.updateProfilePicture(image)
                                    URLCache.shared.removeAllCachedResponses()
                                } catch {
                                    print("❌ Upload error: \(error.localizedDescription)") // ← check Xcode console
                                }
                                isUploadingPhoto = false
                                selectedItem = nil
                            }
                        }
                        if isUploadingPhoto {
                            Circle()
                                .fill(.black.opacity(0.4))
                                .frame(width: 90, height: 90)
                                .clipShape(Circle())
                                .overlay(ProgressView().tint(.white))
                        } else {
                            Circle()
                                .fill(.blue)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                )
                                .offset(x: 2, y: 2)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }
            
            // MARK: - Profile
            Section("Profile") {
                SettingsRow(icon: "person", label: "Username", value: authService.currentUser?.username) {
                    showEditUsername = true
                }
                SettingsRow(icon: "text.quote", label: "Bio", value: authService.currentUser?.bio.isEmpty == false ? authService.currentUser?.bio : "Add a bio") {
                    showEditBio = true
                }
            }
            
            // MARK: - Account
            Section("Account") {
                SettingsRow(icon: "envelope", label: "Email", value: Auth.auth().currentUser?.email) {
                    showEditEmail = true
                }
                SettingsRow(icon: "lock", label: "Change Password") {
                    showEditPassword = true
                }
            }
            
            // MARK: - Danger Zone
            Section {
                Button(role: .destructive) {
                    authService.logout()
                } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
                
                Button(role: .destructive) {
                    showDeleteAccount = true
                } label: {
                    Label("Delete Account", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        
        // MARK: - Sheets
        .sheet(isPresented: $showEditUsername) {
            EditFieldSheet(title: "Username", placeholder: "New username", current: authService.currentUser?.username ?? "") { newValue in
                try await authService.updateUsername(newValue)
            }
        }
        .sheet(isPresented: $showEditBio) {
            EditFieldSheet(title: "Bio", placeholder: "Tell people about yourself", current: authService.currentUser?.bio ?? "", multiline: true) { newValue in
                try await authService.updateBio(newValue)
            }
        }
        .sheet(isPresented: $showEditEmail) {
            PasswordConfirmSheet(title: "Change Email", fieldLabel: "New Email", isEmail: true) { newValue, password in
                try await authService.updateEmail(newEmail: newValue, currentPassword: password)
            }
        }
        .sheet(isPresented: $showEditPassword) {
            ChangePasswordSheet { current, new in
                try await authService.updatePassword(currentPassword: current, newPassword: new)
            }
        }
        .sheet(isPresented: $showDeleteAccount) {
            DeleteAccountSheet { password in
                try await authService.deleteAccount(password: password)
            }
        }
    }
    
    @ViewBuilder
    var profileAvatar: some View {
        if let local = localProfileImage {
            Image(uiImage: local)
                .resizable()
                .scaledToFill()
        } else if let url = authService.currentUser?.profilePicture, !url.isEmpty {
            AsyncImage(url: URL(string: url)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.secondary.opacity(0.2)
            }
            .id(url)
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Settings Row
    struct SettingsRow: View {
        let icon: String
        let label: String
        var value: String? = nil
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack {
                    Label(label, systemImage: icon)
                        .foregroundStyle(.primary)
                    Spacer()
                    if let value {
                        Text(value)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .font(.subheadline)
                    }
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                        .font(.caption)
                }
            }
        }
    }
    
    // MARK: - Edit Text Field Sheet
    struct EditFieldSheet: View {
        let title: String
        let placeholder: String
        let current: String
        var multiline: Bool = false
        let onSave: (String) async throws -> Void
        
        @State private var value = ""
        @State private var isLoading = false
        @State private var errorMessage = ""
        @Environment(\.dismiss) var dismiss
        
        var body: some View {
            NavigationStack {
                Form {
                    if multiline {
                        TextField(placeholder, text: $value, axis: .vertical)
                            .lineLimit(3...6)
                    } else {
                        TextField(placeholder, text: $value)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    if !errorMessage.isEmpty {
                        Text(errorMessage).foregroundStyle(.red).font(.caption)
                    }
                }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Button("Save") {
                                isLoading = true
                                Task {
                                    do {
                                        try await onSave(value)
                                        dismiss()
                                    } catch {
                                        errorMessage = error.localizedDescription
                                        isLoading = false
                                    }
                                }
                            }
                            .disabled(value.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
            }
            .onAppear { value = current }
        }
    }
    
    // MARK: - Change Email Sheet (requires current password)
    struct PasswordConfirmSheet: View {
        let title: String
        let fieldLabel: String
        var isEmail: Bool = false
        let onSave: (String, String) async throws -> Void
        
        @State private var newValue = ""
        @State private var password = ""
        @State private var isLoading = false
        @State private var errorMessage = ""
        @Environment(\.dismiss) var dismiss
        
        var body: some View {
            NavigationStack {
                Form {
                    Section(fieldLabel) {
                        TextField(fieldLabel, text: $newValue)
                            .keyboardType(isEmail ? .emailAddress : .default)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    Section("Confirm Identity") {
                        SecureField("Current Password", text: $password)
                    }
                    if !errorMessage.isEmpty {
                        Text(errorMessage).foregroundStyle(.red).font(.caption)
                    }
                }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        if isLoading { ProgressView() }
                        else {
                            Button("Save") {
                                isLoading = true
                                Task {
                                    do {
                                        try await onSave(newValue, password)
                                        dismiss()
                                    } catch {
                                        errorMessage = error.localizedDescription
                                        isLoading = false
                                    }
                                }
                            }
                            .disabled(newValue.isEmpty || password.isEmpty)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Change Password Sheet
    struct ChangePasswordSheet: View {
        let onSave: (String, String) async throws -> Void
        
        @State private var currentPassword = ""
        @State private var newPassword = ""
        @State private var confirmPassword = ""
        @State private var isLoading = false
        @State private var errorMessage = ""
        @Environment(\.dismiss) var dismiss
        
        var body: some View {
            NavigationStack {
                Form {
                    Section("Current Password") {
                        SecureField("Current password", text: $currentPassword)
                    }
                    Section("New Password") {
                        SecureField("New password (6+ characters)", text: $newPassword)
                        SecureField("Confirm new password", text: $confirmPassword)
                    }
                    if !errorMessage.isEmpty {
                        Text(errorMessage).foregroundStyle(.red).font(.caption)
                    }
                }
                .navigationTitle("Change Password")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        if isLoading { ProgressView() }
                        else {
                            Button("Save") {
                                guard newPassword == confirmPassword else {
                                    errorMessage = "Passwords don't match"
                                    return
                                }
                                guard newPassword.count >= 6 else {
                                    errorMessage = "Password must be at least 6 characters"
                                    return
                                }
                                isLoading = true
                                Task {
                                    do {
                                        try await onSave(currentPassword, newPassword)
                                        dismiss()
                                    } catch {
                                        errorMessage = error.localizedDescription
                                        isLoading = false
                                    }
                                }
                            }
                            .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Delete Account Sheet
    struct DeleteAccountSheet: View {
        let onDelete: (String) async throws -> Void
        
        @State private var password = ""
        @State private var isLoading = false
        @State private var errorMessage = ""
        @Environment(\.dismiss) var dismiss
        
        var body: some View {
            NavigationStack {
                Form {
                    Section {
                        Text("This will permanently delete your account and cannot be undone.")
                            .foregroundStyle(.secondary)
                    }
                    Section("Confirm Identity") {
                        SecureField("Enter your password", text: $password)
                    }
                    if !errorMessage.isEmpty {
                        Text(errorMessage).foregroundStyle(.red).font(.caption)
                    }
                }
                .navigationTitle("Delete Account")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        if isLoading { ProgressView() }
                        else {
                            Button("Delete", role: .destructive) {
                                isLoading = true
                                Task {
                                    do {
                                        try await onDelete(password)
                                        dismiss()
                                    } catch {
                                        errorMessage = error.localizedDescription
                                        isLoading = false
                                    }
                                }
                            }
                            .disabled(password.isEmpty)
                        }
                    }
                }
            }
        }
    }
}
#Preview {
    NavigationStack { SettingsView() }
        .environment(AuthService())
}


