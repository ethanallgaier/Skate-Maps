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
            
            // MARK: - Animated Wavy Gradient
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                Canvas { context, size in
                    context.addFilter(.blur(radius: 60))
                    
                    for i in 0..<3 {
                        let x = size.width * (0.3 + 0.3 * sin(time * 0.3 + Double(i)))
                        let y = size.height * (0.3 + 0.3 * cos(time * 0.2 + Double(i)))
                        
                        let rect = CGRect(x: x - 150, y: y - 150, width: 300, height: 300)
                        
                        context.fill(
                            Path(ellipseIn: rect),
                            with: .linearGradient(
                                Gradient(colors: waveColors[i]),
                                startPoint: CGPoint(x: rect.minX, y: rect.minY),
                                endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
                            )
                        )
                    }
                }
            }
            .ignoresSafeArea()
            
            
            // MARK: - Soft Overlay (makes it clean)
            Color.black.opacity(0.15)
                .ignoresSafeArea()
            
            
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
                    .foregroundColor(.white.opacity(0.85))
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

