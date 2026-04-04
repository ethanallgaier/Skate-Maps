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
    var iconColor: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(iconColor.gradient, in: RoundedRectangle(cornerRadius: 7))
                
                Text(label)
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
                    .font(.caption.weight(.semibold))
            }
        }
    }
}


#Preview {
    List {
        SettingsRow(icon: "person", label: "Username", value: "john", iconColor: .blue) {
            print("tapped")
        }
        SettingsRow(icon: "envelope", label: "Email", value: "john@email.com", iconColor: .teal) {
            print("tapped")
        }
        SettingsRow(icon: "lock", label: "Change Password", iconColor: .orange) {
            print("tapped")
        }
    }
}
