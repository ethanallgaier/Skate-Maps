//
//  ContentView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/2/26.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                
           
               profileCard()
                
                VStack {
                    
                   
                    
                  
                }
//                    .padding()
//                    .frame(width: 370, height: 350)
//                    .background(.ultraThinMaterial)
//                    .clipShape(RoundedRectangle(cornerRadius: 20))
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 20)
//                            .stroke(.white.opacity(0.2), lineWidth: 1)
//                    )
//                    .padding()
       
            }
            .padding()
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
    }
}
func profileCard() -> some View {
    NavigationStack {
        VStack {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.custom( "", size: 55))
                                VStack(alignment: .leading) {
                    Text("Ethan")
                        .bold()
                    Text("ethan@brnadistry.com")
                }
                Spacer()
                Image(systemName: "square.and.pencil")
            }
            .padding()
            .frame(width: 370, height: 120)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .padding()
        }
    }
}

func largeProfileCard(image: String, topic: String, detail: String) -> some View {
    NavigationStack {
        VStack {
            HStack {
                Image(systemName: image)
                    .font(.custom( "", size: 35))
                    .padding()
                                VStack(alignment: .leading) {
                    Text(topic)
                        .bold()
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            
        }
    }
}


#Preview {
    ProfileView()
}
