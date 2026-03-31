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
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: collection.icon)
                .font(.title2)
                .foregroundStyle(.blue)

            Text(collection.title)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(collection.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(collection.pins.count) spots")
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.blue.opacity(0.15), in: Capsule())
                .foregroundStyle(.blue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 16))
    }
}
