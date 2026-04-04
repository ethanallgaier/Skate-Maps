//
//  CollectionCard.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/31/26.
//

import SwiftUI

struct CollectionCard: View {
    let collection: CuratedCollection

    private var accentColor: Color {
        switch collection.icon {
        case "star.fill": return .yellow
        case "light.beacon.max": return .red
        case "shield.checkered": return .green
        case "figure.stairs": return .purple
        default: return .blue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: collection.icon)
                    .font(.title3)
                    .foregroundStyle(accentColor)
                Spacer()
                Text("\(collection.pins.count)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accentColor.opacity(0.12), in: Capsule())
            }

            Spacer(minLength: 0)

            Text(collection.title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(collection.subtitle)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 120)
        .padding(14)
        .glassEffect(in: .rect(cornerRadius: 16))
    }
}
