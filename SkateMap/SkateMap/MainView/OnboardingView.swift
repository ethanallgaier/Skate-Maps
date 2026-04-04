//
//  OnboardingView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 4/3/26.
//

import SwiftUI

struct OnboardingView: View {

    var onFinished: () -> Void

    @State private var currentPage = 0
    @State private var appeared = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "map.fill",
            color: .blue,
            title: "Find skate spots",
            subtitle: "Explore a map loaded with street spots, parks, and hidden gems near you."
        ),
        OnboardingPage(
            icon: "mappin.and.ellipse",
            color: .darkblue,
            title: "Post your own",
            subtitle: "Drop a pin, add photos, and share your favorite spots with the community."
        ),
        OnboardingPage(
            icon: "star.fill",
            color: .orange,
            title: "See what others ride",
            subtitle: "Rate spots, save your favorites, and discover what skaters are hitting."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Page Content
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: 20) {
                        Spacer()

                        // Icon circle
                        ZStack {
                            Circle()
                                .fill(page.color.opacity(0.12))
                                .frame(width: 130, height: 130)
                            Image(systemName: page.icon)
                                .font(.system(size: 52))
                                .foregroundStyle(page.color)
                        }
                        .scaleEffect(appeared ? 1 : 0.7)
                        .opacity(appeared ? 1 : 0)

                        Text(page.title)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .multilineTextAlignment(.center)

                        Text(page.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 48)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)

            // MARK: - Bottom Controls
            VStack(spacing: 20) {

                // Custom page dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.darkblue : Color.secondary.opacity(0.3))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.35), value: currentPage)
                    }
                }

                // Button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        onFinished()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [.darkblue, .blue], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .contentTransition(.interpolate)
                }
                .padding(.horizontal, 24)

                // Skip (hidden on last page)
                if currentPage < pages.count - 1 {
                    Button {
                        onFinished()
                    } label: {
                        Text("Skip")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
    }
}

// MARK: - Page Model
private struct OnboardingPage {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
}

#Preview {
    OnboardingView { }
}
