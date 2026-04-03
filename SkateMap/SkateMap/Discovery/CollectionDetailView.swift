//
//  CollectionDetailView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/31/26.
//

import SwiftUI

struct CollectionDetailView: View {
    let collection: CuratedCollection
    @ObservedObject var viewModel: MapViewModel

    @State private var selectedPin: PinInfo?
    @Namespace private var pinTransition
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(collection.pins) { pin in
                        Button {
                            selectedPin = pin
                        } label: {
                            PinListRow(pin: pin)
                        }
                        .buttonStyle(.plain)
                        .matchedTransitionSource(id: pin.id, in: pinTransition)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .navigationTitle(collection.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .fullScreenCover(item: $selectedPin) { pin in
                PinInfoView(pin: pin, viewModel: viewModel)
                    .navigationTransition(.zoom(sourceID: pin.id, in: pinTransition))
            }
        }
    }
}
