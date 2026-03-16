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
                Tab("Explore", systemImage: "globe") {
                    MapView()
                }
                Tab("Profile", systemImage: "figure.stand") {
                    ProfileView()
                }
                Tab("Favorites", systemImage: "staroflife.fill") {
                    
                }
            }
            .tint(.black)
        
//            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
//        } else {
//            LoginView()
//        }
    }
}
#Preview {
    ContentView()
        .environment(AuthService())  
}
