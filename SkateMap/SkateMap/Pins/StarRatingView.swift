//
//  StarRatingView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/20/26.
//

import SwiftUI



struct StarRatingView: View {
    let rating: Double        // average rating to display
    var userRating: Int       // current user's rating (0 = unrated)
    var onRate: (Int) -> Void // called when user taps a star

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: starIcon(for: star))
                    .foregroundStyle(star <= userRating ? .yellow : .secondary)
                    .font(.title3)
                    .onTapGesture {
                        onRate(star)
                    }
            }
        }
    }

    func starIcon(for star: Int) -> String {
        if Double(star) <= rating {
            return "star.fill"
        } else if Double(star) - rating < 1 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StarRatingView(rating: 3.5, userRating: 4) { star in
            print("Rated \(star) stars")
        }
        StarRatingView(rating: 0, userRating: 0) { star in
            print("Rated \(star) stars")
        }
    }
    .padding()
}

