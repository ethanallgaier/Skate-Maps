//
//  ContentView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/3/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthService.self) var authService// check to see if user has logged in or not
    var body: some View {
        if authService.isLoggedIn {
            Text("Welcome to skate maps")
            Button {
                authService.logout()
            } label: {
                Text("Logout")
            }
        } else {
            LoginView()
        }
    }
}

#Preview {
    ContentView()
}
