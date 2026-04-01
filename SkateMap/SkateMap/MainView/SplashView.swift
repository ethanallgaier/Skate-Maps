//
//  SplashView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/14/26.
//

import SwiftUI



import SwiftUI

struct SplashView: View {
    
    @State private var animate = false
    @State private var showLogo = false
    
    var body: some View {
        ZStack {
            
    
            
            
            // MARK: - Logo
            VStack(spacing: 12) {
//                Image("logo")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 90)
//                    .scaleEffect(showLogo ? 1 : 0.8)
//                    .opacity(showLogo ? 1 : 0)
//                
                Text("Skate-Map") // change name
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(.red.opacity(0.85))
                    .opacity(showLogo ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                showLogo = true
            }
        }
    }
}

// MARK: - Color Sets
let waveColors: [[Color]] = [
    [Color.blue, Color.purple],
    [Color.cyan, Color.blue],
    [Color.pink, Color.purple]
]

#Preview {
    SplashView()
}

