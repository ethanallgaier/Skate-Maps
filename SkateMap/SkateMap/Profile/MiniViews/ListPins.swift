//
//  ListPins.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/20/26.
//

import SwiftUI

struct PinListRow: View {
    let pin: PinInfo

    var body: some View {
        HStack(spacing: 14) {
            // Spot image — fixed size, always fills
            Group {
                if let firstURL = pin.imageURls.first, let url = URL(string: firstURL) {
                    CachedAsyncImage(url: url) {
                        Color.secondary.opacity(0.15)
                            .overlay(ProgressView().controlSize(.small))
                    }
                } else {
                    Color.secondary.opacity(0.1)
                        .overlay(
                            Image(systemName: "figure.skateboarding")
                                .font(.system(size: 22))
                                .foregroundStyle(.secondary.opacity(0.4))
                        )
                }
            }
            .frame(width: 80, height: 80)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(pin.pinName)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .lineLimit(1)

                // Spot types as plain text
                Text(pin.spotTypes.map(\.rawValue).joined(separator: ", "))
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                // Badges
                HStack(spacing: 6) {
                    Text(pin.difficultyLevel.label)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(pin.difficultyLevel.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(pin.difficultyLevel.color.opacity(0.15), in: Capsule())

                    if pin.averageRating > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.yellow)
                            Text(String(format: "%.1f", pin.averageRating))
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                    }
                }

                // Date
                Text(pin.time.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .glassEffect(in: .rect(cornerRadius: 16))
    }
}
