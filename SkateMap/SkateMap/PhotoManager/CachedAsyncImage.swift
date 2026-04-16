//
//  CachedAsyncImage.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/31/26.
//

import SwiftUI

// MARK: - Image Cache

final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB
    }

    func image(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func set(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }

    func remove(for key: String) {
        cache.removeObject(forKey: key as NSString)
    }
}

// MARK: - Cached Async Image

struct CachedAsyncImage<Placeholder: View>: View {
    let url: URL?
    let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var isLoading = false

    init(url: URL?, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder()
                    .onAppear { loadImage() }
            }
        }
        .onChange(of: url) { _, newURL in
            // Reset and reload when URL changes
            image = nil
            isLoading = false
            if newURL != nil {
                loadImage()
            }
        }
    }

    private func loadImage() {
        guard let url, !isLoading else { return }
        let key = url.absoluteString

        // Check memory cache first
        if let cached = ImageCache.shared.image(for: key) {
            self.image = cached
            return
        }

        isLoading = true
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let downloaded = UIImage(data: data) {
                    ImageCache.shared.set(downloaded, for: key)
                    await MainActor.run {
                        self.image = downloaded
                    }
                }
            } catch {
                // Image load failed
            }
            await MainActor.run { isLoading = false }
        }
    }
}
