//
//  SettingsRow.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/20/26.
//

import SwiftUI

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let label: String
    var value: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Label(label, systemImage: icon)
                    .foregroundStyle(.primary)
                Spacer()
                if let value {
                    Text(value)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .font(.subheadline)
                }
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
        }
    }
}


#Preview {
    List {  // ✅ wrap in List since it's designed to live inside one
        SettingsRow(icon: "person", label: "Username", value: "john") {
            print("tapped")
        }
        SettingsRow(icon: "envelope", label: "Email", value: "john@email.com") {
            print("tapped")
        }
        SettingsRow(icon: "lock", label: "Change Password") { // ✅ no value
            print("tapped")
        }
    }
}
