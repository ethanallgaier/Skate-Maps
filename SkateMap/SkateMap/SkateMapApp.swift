//
//  SkateMapApp.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/2/26.
//

import SwiftUI
import FirebaseCore

//AppDelegate is an older iOS pattern that lets you run code at specific moments in your app's life. The didFinishLaunchingWithOptions function runs the moment your app opens — before any screen appears — which is exactly when Firebase needs to be configured.
//FirebaseApp.configure() is the one line that wakes Firebase up and reads your GoogleService-Info.plist to connect to your project.
//@UIApplicationDelegateAdaptor is the bridge between the old AppDelegate pattern and SwiftUI. Since SwiftUI apps don't use AppDelegate by default, this line plugs it back in so it still runs.
//

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return true
    }
}

//idk what is goin on here exept the animation

import SwiftUI
import FirebaseCore

@main
struct SkateMapApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @State private var authService: AuthService
    @State private var showSplash = true

    init() {
        FirebaseApp.configure()
        _authService = State(initialValue: AuthService())
    }

    var body: some Scene {
        WindowGroup {

            Group {
                if showSplash {
                    SplashView()
                } else {
                    ContentView()
                        .environment(authService)
                }
            }
            .task {
                try? await Task.sleep(for: .seconds(2))

                withAnimation(.easeOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }
}
