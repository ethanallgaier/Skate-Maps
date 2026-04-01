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
            // Spot image
            Group {
                if let firstURL = pin.imageURls.first, let url = URL(string: firstURL) {
                    CachedAsyncImage(url: url) {
                        Color.secondary.opacity(0.15)
                            .overlay(ProgressView().controlSize(.small))
                    }
                } else {
                    Color.secondary.opacity(0.1)
                        .overlay(
                            Image(systemName: pin.spotTypes.first?.icon ?? "mappin")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        )
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(pin.pinName)
                    .font(.headline)
                    .lineLimit(1)

                // Spot types
                Text(pin.spotTypes.map(\.rawValue).joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                // Badges
                HStack(spacing: 8) {
                    // Risk badge
                    

                    // Difficulty badge
                    HStack(spacing: 3) {
                        Image(systemName: pin.difficultyLevel.icon)
                        Text(pin.difficultyLevel.label)
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(pin.difficultyLevel.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(pin.difficultyLevel.color.opacity(0.15), in: Capsule())
                }

                // Date
                Text(pin.time.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .glassEffect(in: .rect(cornerRadius: 16))
    }
}
