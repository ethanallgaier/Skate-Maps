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

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // Background image or placeholder
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

                    // Spot type badges
                    HStack(spacing: 6) {
                        ForEach(pin.spotTypes, id: \.self) { type in
                            Text(type.rawValue)
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                    }

                    Text(pin.pinName)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 10) {
                        Label(viewModel.username(for: pin.createdByUID), systemImage: "person.circle")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))

                        if pin.averageRating > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill")
                                Text(String(format: "%.1f", pin.averageRating))
                            }
                            .font(.caption.bold())
                            .foregroundStyle(.yellow)
                        }

                        HStack(spacing: 3) {
                            Image(systemName: pin.riskLevel.icon)
                            Text(pin.riskLevel.label)
                        }
                        .font(.caption2.bold())
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
