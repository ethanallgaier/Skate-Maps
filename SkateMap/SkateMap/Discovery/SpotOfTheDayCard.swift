//
//  SpotOfTheDayCard.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/31/26.
//

import SwiftUI

struct SpotOfTheDayCard: View {
    let pin: PinInfo
    @ObservedObject var viewModel: MapViewModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // Background image or placeholder — always fills
                Group {
                    if let firstURL = pin.imageURls.first, let url = URL(string: firstURL) {
                        CachedAsyncImage(url: url) {
                            gradientPlaceholder
                        }
                    } else {
                        gradientPlaceholder
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .clipped()

                // Gradient overlay for text readability
                LinearGradient(
                    colors: [.clear, .clear, .black.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Content overlay
                VStack(alignment: .leading, spacing: 8) {
                    Spacer()

                    // Spot type badges (text only, no icons)
                    HStack(spacing: 6) {
                        ForEach(pin.spotTypes, id: \.self) { type in
                            Text(type.rawValue)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                    }

                    Text(pin.pinName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 10) {
                        HStack(spacing: 5) {
                            if let picURL = viewModel.profilePicture(for: pin.createdByUID),
                               let url = URL(string: picURL) {
                                CachedAsyncImage(url: url) {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                                .frame(width: 18, height: 18)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            Text(viewModel.username(for: pin.createdByUID))
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(.white.opacity(0.85))
                        }

                        if pin.averageRating > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill")
                                Text(String(format: "%.1f", pin.averageRating))
                            }
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.yellow)
                        }

                        Text(pin.riskLevel.label)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(pin.riskLevel.color)
                    }
                }
                .padding(20)
            }
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(CardPressStyle())
    }

    private var gradientPlaceholder: some View {
        LinearGradient(
            colors: [Color(red: 0.12, green: 0.12, blue: 0.16), Color(red: 0.22, green: 0.22, blue: 0.28)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Image(systemName: "figure.skateboarding")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.18))
        )
    }
}

// MARK: - Reusable Press Style

struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(duration: 0.25, bounce: 0.3), value: configuration.isPressed)
    }
}
