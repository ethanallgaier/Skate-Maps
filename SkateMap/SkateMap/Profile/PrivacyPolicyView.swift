import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Last updated: April 13, 2026")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                section("Information We Collect",
                    "When you create an account, we collect your email address, username, and optional profile photo. When you use the app, we collect location data to show nearby skate spots and provide directions. Photos you upload to skate spots are stored on our servers."
                )

                section("How We Use Your Information",
                    "We use your information to provide and improve SkateMap's features, including displaying skate spots on the map, showing your profile to other users, and enabling community features like ratings and comments."
                )

                section("Location Data",
                    "SkateMap accesses your location only while the app is in use. Your precise location is used to show your position on the map and calculate distances to skate spots. You can disable location access at any time in your device Settings."
                )

                section("Data Storage",
                    "Your data is stored securely using Google Firebase services, including Firebase Authentication, Cloud Firestore, and Firebase Storage. Data is transmitted using encrypted connections."
                )

                section("Data Sharing",
                    "We do not sell your personal information to third parties. Your username, profile photo, and spots you create are visible to other SkateMap users. We may share data if required by law."
                )

                section("Account Deletion",
                    "You can delete your account at any time from the Settings screen. When you delete your account, all of your data is permanently removed, including your profile, pins, photos, and comments."
                )

                section("Contact",
                    "If you have questions about this privacy policy, please contact us at skatemapapp@gmail.com."
                )
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
