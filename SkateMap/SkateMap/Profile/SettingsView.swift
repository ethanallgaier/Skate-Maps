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
    @State private var showLogout = false
    
    var body: some View {
        List {
            
            // MARK: - PROFILE PIC
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        ZStack(alignment: .bottomTrailing) {
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                profileAvatar
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.blue, .purple, .pink],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 3
                                            )
                                    )
                                    .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                            }
                            .id(authService.profileRefreshID)
                            .onChange(of: selectedItem) { _, newItem in
                                guard let newItem else { return }
                                Task {
                                    guard let data = try? await newItem.loadTransferable(type: Data.self),
                                          let image = UIImage(data: data) else { return }
                                    localProfileImage = image
                                    isUploadingPhoto = true
                                    do {
                                        try await authService.updateProfilePicture(image)
                                    } catch {
                                        // Upload failed
                                    }
                                    isUploadingPhoto = false
                                    selectedItem = nil
                                }
                            }
                            if isUploadingPhoto {
                                Circle()
                                    .fill(.black.opacity(0.4))
                                    .frame(width: 100, height: 100)
                                    .overlay(ProgressView().tint(.white))
                            } else {
                                Circle()
                                    .fill(.blue.gradient)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(.white)
                                    )
                                    .shadow(color: .blue.opacity(0.3), radius: 4, y: 2)
                                    .offset(x: 2, y: 2)
                            }
                        }
                        
                        Text(authService.currentUser?.username ?? "Skater")
                            .font(.title3.bold())
                        
                        if let email = Auth.auth().currentUser?.email {
                            Text(email)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 12)
                .listRowBackground(Color.clear)
            }
            
            // MARK: - PROFILE
            Section {
                SettingsRow(icon: "person.fill", label: "Username", value: authService.currentUser?.username, iconColor: .blue) {
                    showEditUsername = true
                }
                SettingsRow(icon: "text.quote", label: "Bio", value: authService.currentUser?.bio.isEmpty == false ? authService.currentUser?.bio : "Add a bio", iconColor: .purple) {
                    showEditBio = true
                }
            } header: {
                Text("Profile")
            }
            
            // MARK: - ACCOUNT
            Section {
                SettingsRow(icon: "envelope.fill", label: "Email", value: Auth.auth().currentUser?.email, iconColor: .teal) {
                    showEditEmail = true
                }
                SettingsRow(icon: "lock.fill", label: "Change Password", iconColor: .orange) {
                    showEditPassword = true
                }
            } header: {
                Text("Account")
            }
            
            // MARK: - ACTIONS
            Section {
                Button {
                    showLogout = true
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(Color.red.gradient, in: RoundedRectangle(cornerRadius: 7))
                        Text("Log Out")
                            .foregroundStyle(.red)
                    }
                }
                .confirmationDialog("Are you sure you want to log out?", isPresented: $showLogout, titleVisibility: .visible) {
                    Button("Log Out", role: .destructive) {
                        authService.logout()
                    }
                    Button("Cancel", role: .cancel) { }
                }
                
                Button {
                    showDeleteAccount = true
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(Color.red.gradient, in: RoundedRectangle(cornerRadius: 7))
                        Text("Delete Account")
                            .foregroundStyle(.red)
                    }
                }
            }
            
            // MARK: - LEGAL
            Section {
                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(Color.blue.gradient, in: RoundedRectangle(cornerRadius: 7))
                        Text("Privacy Policy")
                            .foregroundStyle(.primary)
                    }
                }
                NavigationLink {
                    TermsOfServiceView()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(Color.gray.gradient, in: RoundedRectangle(cornerRadius: 7))
                        Text("Terms of Service")
                            .foregroundStyle(.primary)
                    }
                }
            } header: {
                Text("Legal")
            }

            Section {
                HStack {
                    Spacer()
                    Text("SkateMap v1.1")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        
        // MARK: - SHEETS
        .sheet(isPresented: $showEditUsername) {
            EditFieldSheet(title: "Username", placeholder: "New username", current: authService.currentUser?.username ?? "") { newValue in
                try await authService.updateUsername(newValue)
            }
        }
        //BIO
        .sheet(isPresented: $showEditBio) {
            EditFieldSheet(title: "Bio", placeholder: "Tell people about yourself", current: authService.currentUser?.bio ?? "", multiline: true) { newValue in
                try await authService.updateBio(newValue)
            }
        }
        //EMAIL
        .sheet(isPresented: $showEditEmail) {
            PasswordConfirmSheet(title: "Change Email", fieldLabel: "New Email", isEmail: true) { newValue, password in
                try await authService.updateEmail(newEmail: newValue, currentPassword: password)
            }
        }
        //PASSWORD
        .sheet(isPresented: $showEditPassword) {
            ChangePasswordSheet { current, new in
                try await authService.updatePassword(currentPassword: current, newPassword: new)
            }
        }
        //DELETE ACCOUNT
        .sheet(isPresented: $showDeleteAccount) {
            DeleteAccountSheet { password in
                try await authService.deleteAccount(password: password)
            }
        }
        //LOGOUT
     
    }
    
    
    
    
  //MARK: - PROFILE PIC
    @ViewBuilder//allows me to use views wtih else statemenst
    var profileAvatar: some View {
        if let local = localProfileImage {
            Image(uiImage: local)
                .resizable()
                .scaledToFill()
        } else if let url = authService.currentUser?.profilePicture, !url.isEmpty {
            CachedAsyncImage(url: URL(string: url)) {
                Color.secondary.opacity(0.2)
            }
            .id(url)
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .foregroundStyle(.secondary)
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


