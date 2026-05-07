import SwiftUI

struct EULAView: View {
    @AppStorage("hasAcceptedEULA") private var hasAcceptedEULA = false
    @State private var scrolledToBottom = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("End User License Agreement")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .padding(.top, 8)

                        Text("Please read and accept the following terms before using SkateMap.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        eulaSection("User-Generated Content",
                            "SkateMap allows users to post photos, pins, comments, and other content. All user-generated content is subject to our content guidelines."
                        )

                        eulaSection("Zero Tolerance Policy",
                            "SkateMap has a ZERO TOLERANCE policy for objectionable content or abusive users. This includes but is not limited to:\n\n• Sexually explicit or pornographic material\n• Violent or graphic content\n• Hate speech or discrimination\n• Harassment, bullying, or threats\n• Spam or misleading content\n• Illegal activity promotion\n\nViolators will have their content removed and their accounts permanently terminated."
                        )

                        eulaSection("Reporting & Blocking",
                            "You can report objectionable content or block abusive users at any time using the in-app tools. All reports are reviewed within 24 hours by our moderation team."
                        )

                        eulaSection("Content Moderation",
                            "SkateMap reserves the right to remove any content and terminate any account that violates these terms without prior notice. We actively monitor and review reported content."
                        )

                        eulaSection("Your Responsibility",
                            "By using SkateMap, you agree to not post any objectionable content and to use the reporting tools if you encounter inappropriate content from other users."
                        )

                        Color.clear
                            .frame(height: 1)
                            .onAppear { scrolledToBottom = true }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }

                Divider()

                VStack(spacing: 12) {
                    Button {
                        withAnimation {
                            hasAcceptedEULA = true
                        }
                    } label: {
                        Text("I Agree to the Terms")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                scrolledToBottom
                                    ? AnyShapeStyle(LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                                    : AnyShapeStyle(Color.gray.opacity(0.35))
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(!scrolledToBottom)

                    if !scrolledToBottom {
                        Text("Please scroll to read the full agreement")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(.bar)
            }
        }
    }

    private func eulaSection(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
