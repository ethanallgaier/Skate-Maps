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
                    colors: [.clear, .clear, .black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Content overlay
                VStack(alignment: .leading, spacing: 8) {
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
                            .foregroundStyle(.white.opacity(0.8))

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
        }
        .buttonStyle(.plain)
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
