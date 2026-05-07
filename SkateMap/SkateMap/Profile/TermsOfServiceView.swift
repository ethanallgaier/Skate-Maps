import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Last updated: April 30, 2026")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                section("Acceptance of Terms",
                    "By using SkateMap, you agree to these Terms of Service and our End User License Agreement (EULA). If you do not agree, please do not use the app."
                )

                section("User Accounts",
                    "You are responsible for maintaining the security of your account and password. You must provide accurate information when creating your account. You must be at least 13 years old to use SkateMap."
                )

                section("User Content",
                    "You retain ownership of the content you post (photos, pins, comments). By posting content, you grant SkateMap a non-exclusive license to display it within the app. You are responsible for ensuring your content does not violate any laws or the rights of others."
                )

                section("Zero Tolerance for Objectionable Content",
                    "SkateMap has a zero-tolerance policy for objectionable content or abusive behavior. You may not post content that is offensive, sexually explicit, violent, discriminatory, harassing, threatening, hateful, or otherwise objectionable. You may not harass, bully, or abuse other users. You may not use the app to promote illegal activity. You may not attempt to gain unauthorized access to any part of the service. Any violation of this policy will result in immediate removal of the offending content and may result in permanent account termination."
                )

                section("Content Moderation & Reporting",
                    "SkateMap actively moderates user-generated content. Users can report objectionable content or abusive users using the in-app reporting tools. All reports are reviewed within 24 hours. Content that violates these terms will be removed and the offending user's account may be suspended or permanently terminated. Users can also block other users to immediately remove their content from view."
                )

                section("Blocking Users",
                    "You may block any user at any time. Blocking a user will immediately hide all of their content from your feed and prevent them from interacting with your content. Blocking a user also sends a notification to our moderation team for review."
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
