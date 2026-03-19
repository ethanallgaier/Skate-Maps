//
//  AuthService.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/4/26.
//
import FirebaseAuth
import FirebaseFirestore
import UIKit

@Observable
class AuthService {
    var isLoggedIn: Bool = false
    var errorMessage: String = ""
    var currentUser: UserInfo?
 
    

    private let db = Firestore.firestore()
    private var authHandle: AuthStateDidChangeListenerHandle?

    init() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isLoggedIn = user != nil
                if let user {
                    Task { await self?.fetchUser(uid: user.uid) }
                } else {
                    self?.currentUser = nil
                }
            }
        }
    }

    deinit {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Login
    func login(email: String, password: String) async {
        errorMessage = ""
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Sign Up
    func signUp(email: String, password: String, username: String, profileImage: UIImage? = nil) async {
        errorMessage = ""
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let uid = result.user.uid

            var profilePicURL = ""
            if let image = profileImage {
                profilePicURL = (try? await ImageUploader.upload(image: image, path: "profile_images/\(uid)")) ?? ""
            }

            let user = UserInfo(id: uid, username: username, bio: "", profilePicture: profilePicURL)
            try db.collection("users").document(uid).setData(from: user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Logout
    func logout() {
        try? Auth.auth().signOut()
        currentUser = nil
    }

    // MARK: - Fetch User
    @MainActor
    func fetchUser(uid: String) async {
        guard let snapshot = try? await db.collection("users").document(uid).getDocument(source: .server) else { return }
        currentUser = try? snapshot.data(as: UserInfo.self)
    }

    // MARK: - Update Username
    func updateUsername(_ username: String) async throws {
        guard let uid = currentUser?.id else { return }
        try await db.collection("users").document(uid).updateData(["username": username])
        await MainActor.run {
            guard let existing = currentUser else { return }
            currentUser = UserInfo(id: existing.id, username: username, bio: existing.bio, profilePicture: existing.profilePicture)
        }
    }

    // MARK: - Update Bio
    func updateBio(_ bio: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try await db.collection("users").document(uid).updateData(["bio": bio])
        await MainActor.run {
            guard let existing = currentUser else { return }
            currentUser = UserInfo(
                id: existing.id,
                username: existing.username,
                bio: bio,
                profilePicture: existing.profilePicture
            )
        }
    }

    // MARK: - Update Profile Picture
    func updateProfilePicture(_ image: UIImage) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let path = "profile_images/\(uid)_\(Date().timeIntervalSince1970)"
        let url = try await ImageUploader.upload(image: image, path: path)
        try await db.collection("users").document(uid).updateData(["profilePicture": url])
        await MainActor.run {
            guard let existing = currentUser else { return }
            currentUser = UserInfo(id: existing.id, username: existing.username, bio: existing.bio, profilePicture: url)
        }
    }

    // MARK: - Update Email
    func updateEmail(newEmail: String, currentPassword: String) async throws {
        guard let user = Auth.auth().currentUser,
              let email = user.email else { return }
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        try await user.reauthenticate(with: credential)
        try await user.sendEmailVerification(beforeUpdatingEmail: newEmail)
    }

    // MARK: - Update Password
    func updatePassword(currentPassword: String, newPassword: String) async throws {
        guard let user = Auth.auth().currentUser,
              let email = user.email else { return }
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        try await user.reauthenticate(with: credential)
        try await user.updatePassword(to: newPassword)
    }

    // MARK: - Delete Account
    func deleteAccount(password: String) async throws {
        guard let user = Auth.auth().currentUser,
              let email = user.email else { return }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await user.reauthenticate(with: credential)
        try await db.collection("users").document(user.uid).delete()
        try await user.delete()
    }
}
