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
    @State private var appeared = false
    @Namespace private var pinTransition
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(collection.pins.enumerated()), id: \.element.id) { index, pin in
                        Button {
                            selectedPin = pin
                        } label: {
                            PinListRow(pin: pin)
                        }
                        .buttonStyle(CardPressStyle())
                        .matchedTransitionSource(id: pin.id, in: pinTransition)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 14)
                        .animation(
                            .spring(duration: 0.4, bounce: 0.15).delay(Double(index) * 0.04),
                            value: appeared
                        )
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
            .onAppear {
                guard !appeared else { return }
                withAnimation {
                    appeared = true
                }
            }
            .fullScreenCover(item: $selectedPin) { pin in
                PinInfoView(pin: pin, viewModel: viewModel)
                    .navigationTransition(.zoom(sourceID: pin.id, in: pinTransition))
            }
        }
    }
}
