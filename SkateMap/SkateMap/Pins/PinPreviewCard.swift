//
//  PinPreviewCard.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/14/26.
//

import SwiftUI

//MARK: - MINI PREVIEW CARD. FIRST TAP ON A PIN
struct PinPreviewCard: View {
    var pin: PinInfo
    @ObservedObject var viewModel: MapViewModel
    var onTap: () -> Void
    var onDismiss: () -> Void

    @State private var showUserProfile = false

    var body: some View {
        HStack(spacing: 16) {

            // Photo or placeholder
            if let firstImage = pin.imageURls.first {
                CachedAsyncImage(url: URL(string: firstImage)) {
                    ProgressView()
                }
                .frame(width: 82, height: 82)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemGray5))
                    .frame(width: 82, height: 82)
                    .overlay(
                        Image(systemName: "figure.skateboarding")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary.opacity(0.5))
                    )
            }

            // Spot info
            VStack(alignment: .leading, spacing: 8) {
                // Name + stars
                HStack(spacing: 8) {
                    Text(pin.pinName)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if pin.averageRating > 0 {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: Double(star) <= pin.averageRating ? "star.fill" : Double(star) - pin.averageRating < 1 ? "star.leadinghalf.filled" : "star")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                }

                // Username — tappable to view profile
                Button {
                    showUserProfile = true
                } label: {
                    HStack(spacing: 5) {
                        if let picURL = viewModel.profilePicture(for: pin.createdByUID) {
                            CachedAsyncImage(url: URL(string: picURL)) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.tertiary)
                            }
                            .frame(width: 16, height: 16)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.tertiary)
                        }
                        Text(viewModel.username(for: pin.createdByUID))
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

                // Badges
                HStack(spacing: 6) {
                    Text(pin.difficultyLevel.label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(pin.difficultyLevel.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(pin.difficultyLevel.color.opacity(0.12), in: Capsule())

                    if let firstType = pin.spotTypes.first, firstType != .other {
                        Text(firstType.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5), in: Capsule())
                    }
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary.opacity(0.5))
        }
        .padding(16)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .glassEffect(in: .rect(cornerRadius: 18))
        .padding(.horizontal)
        .sheet(isPresented: $showUserProfile) {
            NavigationStack {
                UserProfileView(userID: pin.createdByUID, viewModel: viewModel)
            }
        }
    }
}

#Preview {
    let mockPin = PinInfo(
        pinName: "Hubba Hideout",
        pinDetails: "Classic SF spot",
        time: Date(),
        latitude: 37.7749,
        longitude: -122.4194,
        createdByUID: "123",
        createdByUsername: "skater1",
        imageURls: [],
        spotTypes: [.rail]
    )
    PinPreviewCard(pin: mockPin, viewModel: MapViewModel()) {
        print("tapped")
    } onDismiss: {
        print("dismissed")
    }
}
