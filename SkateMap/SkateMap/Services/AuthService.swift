//
//  AuthService.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/4/26.
//
import Foundation
import FirebaseAuth


@Observable
class AuthService {
    var currentUser: FirebaseAuth.User? = nil       //Stores current logged in user
    var errorMessage: String = ""
    private var listener: AuthStateDidChangeListenerHandle?     //watches login state changes

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

    var isLoggedIn: Bool { currentUser != nil }//checks if user is logged in
   
//login
    func login(email: String, password: String) async {
        errorMessage = ""
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)//asks firebase to login
        } catch {
            print("Login error: \(error.localizedDescription)")//if failed
           errorMessage = error.localizedDescription
        }
    }
    
//signup
    func signUp(email: String, password: String, username: String) async {
        do {
            errorMessage = ""
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            print("✅ Sign up success: \(result.user.uid)")
        } catch {
            print("SignUp error: \(error.localizedDescription)")
           errorMessage = error.localizedDescription
        }
    }
    
//logout
    func logout() {
        errorMessage = ""
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
