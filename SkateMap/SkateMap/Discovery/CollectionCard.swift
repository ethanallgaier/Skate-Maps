//
//  CollectionCard.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/31/26.
//

import SwiftUI

struct CollectionCard: View {
    let collection: CuratedCollection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: collection.icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .padding(.bottom, 2)

            Text(collection.title)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(collection.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text("\(collection.pins.count) spots")
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.blue.opacity(0.15), in: Capsule())
                .foregroundStyle(.blue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 120)
        .padding(14)
        .glassEffect(in: .rect(cornerRadius: 16))
    }
}
