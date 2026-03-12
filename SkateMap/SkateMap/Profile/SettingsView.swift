//
//  SettingsView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/11/26.
//

import SwiftUI

struct SettingsView: View {
    
    @Environment(AuthService.self) var authService
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            
           Spacer()
            
            //Logout Button
            
            Button {
                authService.logout()
            } label: {
                Text("Logout")
                    .foregroundStyle(.red)
            }
      
                .navigationTitle("Settings")
            
        }
    }
}

#Preview {
    SettingsView()
        .environment(AuthService())
}
