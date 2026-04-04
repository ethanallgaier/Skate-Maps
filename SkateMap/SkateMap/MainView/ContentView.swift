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
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        if authService.isLoggedIn || authService.isGuest {
            TabView {
                Tab("Explore", systemImage: "globe") {
                    MapView(viewModel: viewModel, locationManager: locationManager)
                }
                Tab("Discover", systemImage: "binoculars.fill") {
                    DiscoveryView(viewModel: viewModel, locationManager: locationManager)
                }
                Tab("Profile", systemImage: "person.crop.circle") {
                    if authService.isGuest {
                        GuestProfileView()
                    } else {
                        ProfileView(viewModel: viewModel)
                    }
                }
               
            }
            .tint(.darkblue)
        } else {
            LoginView()
        }
    }
}
// MARK: - Guest Profile View
struct GuestProfileView: View {
    @Environment(AuthService.self) var authService

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)

                Text("Sign in to access your profile")
                    .font(.title3.bold())

                Text("Create an account to drop pins, rate spots, and save your favorites.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Button {
                    authService.exitGuestMode()
                } label: {
                    Text("Sign In or Sign Up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Spacer()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthService())  
}
