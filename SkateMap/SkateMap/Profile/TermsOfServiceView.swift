import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Last updated: April 13, 2026")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                section("Acceptance of Terms",
                    "By using SkateMap, you agree to these Terms of Service. If you do not agree, please do not use the app."
                )

                section("User Accounts",
                    "You are responsible for maintaining the security of your account and password. You must provide accurate information when creating your account. You must be at least 13 years old to use SkateMap."
                )

                section("User Content",
                    "You retain ownership of the content you post (photos, pins, comments). By posting content, you grant SkateMap a non-exclusive license to display it within the app. You are responsible for ensuring your content does not violate any laws or the rights of others."
                )

                section("Prohibited Conduct",
                    "You may not post offensive, illegal, or harmful content. You may not harass other users. You may not use the app to promote illegal activity. You may not attempt to gain unauthorized access to any part of the service. Violations may result in account termination."
                )

                section("Content Moderation",
                    "SkateMap reserves the right to remove any content that violates these terms or is reported by users. We may suspend or terminate accounts that repeatedly violate these terms."
                )

                section("Disclaimer",
                    "SkateMap provides skate spot information contributed by users. We do not guarantee the accuracy, safety, or legality of any spot. Skateboarding is an inherently risky activity. You skate at your own risk and are responsible for following all local laws and regulations."
                )

                section("Limitation of Liability",
                    "SkateMap is provided \"as is\" without warranties of any kind. We are not liable for any injuries, damages, or losses that occur from using the app or visiting spots listed on it."
                )

                section("Changes to Terms",
                    "We may update these terms from time to time. Continued use of the app after changes constitutes acceptance of the updated terms."
                )

                section("Contact",
                    "If you have questions about these terms, please contact us at skatemapapp@gmail.com."
                )
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
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
