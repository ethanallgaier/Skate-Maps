//
//  ContentView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/3/26.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(AuthService.self) var authService// see if user has logged in

    var body: some View {
//        if authService.isLoggedIn {
            TabView {
                Tab("Map", systemImage: "map.circle") {
                    MapView()
                }
                Tab("Profile", systemImage: "person") {
                    ProfileView()
                }
            }
//        } else {
//            LoginView()
//        }
    }
}
#Preview {
    ContentView()
        .environment(AuthService())  
}
