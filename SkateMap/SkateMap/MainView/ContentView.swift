//
//  ContentView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/3/26.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(AuthService.self) var authService// see if user has logged in
    @StateObject private var viewModel = MapViewModel()
    
    var body: some View {
        if authService.isLoggedIn {
            TabView {
                Tab("Explore", systemImage: "globe") {
                    MapView(viewModel: viewModel)
                }
                Tab("Profile", systemImage: "person.crop.circle") {
                    ProfileView(viewModel: viewModel)
                }
               
            }
            .tint(.red.opacity(0.9))
        
//            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        } else {
            LoginView()
        }
    }
}
#Preview {
    ContentView()
        .environment(AuthService())  
}
