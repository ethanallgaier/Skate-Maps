//
//  SplashView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/14/26.
//

import SwiftUI

struct SplashView: View {

    @State private var goText = ""
    @State private var skateText = ""
    @State private var showCursor = true

    private let goTarget = "GO"
    private let skateTarget = "SKATE"

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: -15) {
                // GO
                HStack(spacing: 0) {
                    Text(goText)
                        .font(.system(size: 105, weight: .black, design: .rounded))
                        .foregroundStyle(.darkblue)
                        .lineLimit(1)

                    if goText.count < goTarget.count {
                        cursor
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)

                // SKATE
                HStack(spacing: 0) {
                    Text(skateText)
                        .font(.system(size: 105, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.darkblue, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineLimit(1)

                    if goText.count >= goTarget.count && skateText.count < skateTarget.count {
                        cursor
                    }

                    if skateText.count >= skateTarget.count {
                        cursor
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
            }
        }
        .task {
            for char in goTarget {
                try? await Task.sleep(for: .seconds(0.25))
                goText.append(char)
            }

            try? await Task.sleep(for: .seconds(0.2))

            for char in skateTarget {
                try? await Task.sleep(for: .seconds(0.2))
                skateText.append(char)
            }
        }
    }

    private var cursor: some View {
        Rectangle()
            .fill(Color.darkblue)
            .frame(width: 6, height: 120)
            .opacity(showCursor ? 1 : 0)
            .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: showCursor)
            .onAppear { showCursor = false }
            .padding(.leading, 4)
    }
}

#Preview {
    SplashView()
}
