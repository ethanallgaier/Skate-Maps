//
//  AuthService.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/4/26.
//
import Foundation
import FirebaseAuth


//I need to understand this code i dont knwo whats goin on here
@Observable
class AuthService {
    var currentUser: FirebaseAuth.User? = nil
    private var listener: AuthStateDidChangeListenerHandle?

    init() {
        listener = Auth.auth().addStateDidChangeListener { _, user in
            self.currentUser = user
        }
    }

    deinit {
        if let listener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    var isLoggedIn: Bool { currentUser != nil }
   
    
    func login(email: String, password: String) async {
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            print("Login error: \(error.localizedDescription)")
        }
    }

    func signUp(email: String, password: String, username: String) async {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            print("✅ Sign up success: \(result.user.uid)")
        } catch {
            print("❌ Sign up error: \(error.localizedDescription)")
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Logout error: \(error.localizedDescription)")
        }
    }
}
