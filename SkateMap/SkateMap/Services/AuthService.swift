//
//  AuthService.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/4/26.
//
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit

@Observable
class AuthService {
    var isLoggedIn: Bool = false
    var isGuest: Bool = false
    var errorMessage: String = ""
    var currentUser: UserInfo?


    var profileRefreshID: UUID = UUID()
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

    // MARK: - Forgot Password
    func sendPasswordReset(email: String) async {
        errorMessage = ""
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
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
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument(source: .server)
            currentUser = try snapshot.data(as: UserInfo.self)
        } catch {
            // Silently fail — user data may not exist yet
        }
    }

    // MARK: - Update Username
    func updateUsername(_ username: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try await db.collection("users").document(uid).updateData(["username": username])
        await fetchUser(uid: uid)
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

        // Clear the old image from cache before uploading the new one
        if let oldURL = currentUser?.profilePicture, !oldURL.isEmpty {
            ImageCache.shared.remove(for: oldURL)
        }

        let path = "profile_images/\(uid)_\(Date().timeIntervalSince1970)"
        let url = try await ImageUploader.upload(image: image, path: path)
        try await db.collection("users").document(uid).updateData(["profilePicture": url])
        URLCache.shared.removeAllCachedResponses()
        await fetchUser(uid: uid)
        await MainActor.run { profileRefreshID = UUID() }
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

        let uid = user.uid

        // Delete all pins created by this user
        let pinsSnapshot = try await db.collection("pins")
            .whereField("createdByUID", isEqualTo: uid)
            .getDocuments()

        for doc in pinsSnapshot.documents {
            // Delete pin images from Storage
            if let imageURLs = doc.data()["imageURls"] as? [String] {
                for urlString in imageURLs {
                    if let url = URL(string: urlString),
                       let path = extractStoragePath(from: url) {
                        try? await Storage.storage().reference(withPath: path).delete()
                    }
                }
            }
            // Delete comments subcollection
            let comments = try await doc.reference.collection("comments").getDocuments()
            for comment in comments.documents {
                try await comment.reference.delete()
            }
            // Delete the pin document
            try await doc.reference.delete()
        }

        // Delete profile image from Storage
        if let profilePic = currentUser?.profilePicture, !profilePic.isEmpty,
           let url = URL(string: profilePic),
           let path = extractStoragePath(from: url) {
            try? await Storage.storage().reference(withPath: path).delete()
        }

        // Delete user document from Firestore
        try await db.collection("users").document(uid).delete()

        // Delete Firebase Auth account
        try await user.delete()
    }

    /// Extracts the Firebase Storage path from a download URL
    private func extractStoragePath(from url: URL) -> String? {
        // Firebase Storage download URLs contain the path after /o/ and before ?
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let path = components.path.split(separator: "/o/").last else { return nil }
        return String(path).removingPercentEncoding
    }

    // MARK: - Guest Mode
    func enterGuestMode() {
        isGuest = true
    }

    func exitGuestMode() {
        isGuest = false
    }
}
