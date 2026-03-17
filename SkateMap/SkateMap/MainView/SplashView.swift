//
//  SplashView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/14/26.
//

import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                // Logo

                // App name
                Image(systemName: "figure.skateboarding.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)
                    .scaleEffect(isAnimating ? 1.5 : 0.9)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                Text("TESTING")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    SplashView()
}

