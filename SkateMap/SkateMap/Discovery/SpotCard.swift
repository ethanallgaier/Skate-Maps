//
//  SpotCard.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/31/26.
//

import SwiftUI

struct SpotCard: View {
    let pin: PinInfo
    @ObservedObject var viewModel: MapViewModel
    var distance: Double? // meters
    var showDate: Bool = false
    var showRating: Bool = true
    let onTap: () -> Void

    private var formattedDistance: String? {
        guard let distance else { return nil }
        let miles = distance / 1609.34
        if miles < 0.1 {
            return String(format: "%.0f ft", distance * 3.28084)
        } else if miles < 10 {
            return String(format: "%.1f mi", miles)
        } else {
            return String(format: "%.0f mi", miles)
        }
    }

    private var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: pin.time, relativeTo: Date())
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Photo — fixed size, always fills
                ZStack(alignment: .topTrailing) {
                    Group {
                        if let firstURL = pin.imageURls.first, let url = URL(string: firstURL) {
                            CachedAsyncImage(url: url) {
                                Color(.systemGray5)
                                    .overlay(ProgressView())
                            }
                        } else {
                            LinearGradient(
                                colors: [Color(.systemGray5), Color(.systemGray4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .overlay(
                                Image(systemName: "figure.skateboarding")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.secondary.opacity(0.5))
                            )
                        }
                    }
                    .frame(width: 159, height: 120)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    // Distance badge overlay
                    if let dist = formattedDistance {
                        Text(dist)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(.black.opacity(0.55), in: Capsule())
                            .padding(6)
                    }
                }

                // Info — fixed height so all cards match
                VStack(alignment: .leading, spacing: 3) {
                    Text(pin.pinName)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .foregroundStyle(.primary)

                    // Location
                    if let location = viewModel.locationName(for: pin) {
                        HStack(spacing: 3) {
                            Image(systemName: "mappin")
                                .font(.system(size: 9))
                            Text(location)
                                .lineLimit(1)
                        }
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                    }

                    // Badges — difficulty + spot type
                    HStack(spacing: 4) {
                        Text(pin.difficultyLevel.label)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(pin.difficultyLevel.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(pin.difficultyLevel.color.opacity(0.12), in: Capsule())

                        if let firstType = pin.spotTypes.first, firstType != .other {
                            Text(firstType.rawValue)
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray5), in: Capsule())
                        }
                    }

                    // Creator + rating/date row
                    HStack(spacing: 4) {
                        // Profile picture
                        if let picURL = viewModel.profilePicture(for: pin.createdByUID),
                           let url = URL(string: picURL) {
                            CachedAsyncImage(url: url) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.tertiary)
                            }
                            .frame(width: 14, height: 14)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.tertiary)
                        }

                        Text(viewModel.username(for: pin.createdByUID))
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        if showRating, pin.averageRating > 0 {
                            Text("·")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                            Image(systemName: "star.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.yellow)
                            Text(String(format: "%.1f", pin.averageRating))
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                        }

                        if showDate {
                            Text("·")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                            Text(relativeDate)
                                .font(.system(size: 11, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(height: 82, alignment: .topLeading)
                .padding(.horizontal, 4)
                .padding(.top, 8)
            }
            .padding(8)
            .frame(width: 175, height: 230)
            .glassEffect(in: .rect(cornerRadius: 16))
        }
        .buttonStyle(CardPressStyle())
    }
}
