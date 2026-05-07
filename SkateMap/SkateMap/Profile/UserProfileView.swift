//
//  UserProfileView.swift
//  SkateMap
//
//  Public profile view for viewing another user's profile.
//

import SwiftUI
import FirebaseAuth

struct UserProfileView: View {
    let userID: String
    @ObservedObject var viewModel: MapViewModel

    @State private var user: UserInfo?
    @State private var userPins: [PinInfo] = []
    @State private var isLoading = true
    @State private var selectedPin: PinInfo?
    @State private var showPinDetail = false
    @State private var showBlockConfirm = false
    @State private var showBlockedAlert = false
    @State private var showReportSheet = false
    @State private var reportReason = ""
    @State private var showReportConfirmation = false
    @Namespace private var pinTransition

    @Environment(\.dismiss) var dismiss

    var isCurrentUser: Bool {
        Auth.auth().currentUser?.uid == userID
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // MARK: - Profile Header
                VStack(spacing: 12) {
                    // Avatar
                    if let url = user?.profilePicture, !url.isEmpty {
                        CachedAsyncImage(url: URL(string: url)) {
                            Color.secondary.opacity(0.2)
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.background, lineWidth: 3))
                        .shadow(radius: 4)
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundStyle(.secondary)
                    }

                    Text(user?.username ?? "...")
                        .font(.system(size: 24, weight: .bold, design: .rounded))

                    if let bio = user?.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    // Stats
                    HStack(spacing: 0) {
                        VStack(spacing: 2) {
                            Text("\(userPins.count)")
                                .font(.title2.bold())
                            Text("Spots")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 4)
                }
                .padding(.vertical, 24)

                Divider()

                // MARK: - User's Spots
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(user?.username ?? "User")'s Spots")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top, 16)

                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else if userPins.isEmpty {
                        ContentUnavailableView(
                            "No Spots Yet",
                            systemImage: "mappin.slash",
                            description: Text("This skater hasn't dropped any pins yet.")
                        )
                        .padding(.top)
                    } else {
                        ForEach(userPins) { pin in
                            Button {
                                selectedPin = pin
                                showPinDetail = true
                            } label: {
                                PinListRow(pin: pin)
                            }
                            .buttonStyle(.plain)
                            .matchedTransitionSource(id: pin.id, in: pinTransition)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isCurrentUser {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showReportSheet = true
                        } label: {
                            Label("Report User", systemImage: "flag")
                        }
                        if viewModel.isBlocked(userID) {
                            Button {
                                Task { await viewModel.unblockUser(userID) }
                            } label: {
                                Label("Unblock User", systemImage: "person.badge.plus")
                            }
                        } else {
                            Button(role: .destructive) {
                                showBlockConfirm = true
                            } label: {
                                Label("Block User", systemImage: "person.slash.fill")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .confirmationDialog("Block this user?", isPresented: $showBlockConfirm, titleVisibility: .visible) {
            Button("Block", role: .destructive) {
                Task {
                    await viewModel.blockUser(userID)
                    showBlockedAlert = true
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Their content will be hidden from your feed. This also notifies our moderation team.")
        }
        .alert("User Blocked", isPresented: $showBlockedAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("You will no longer see content from this user.")
        }
        .sheet(isPresented: $showReportSheet) {
            NavigationStack {
                Form {
                    Section("Why are you reporting this user?") {
                        Picker("Reason", selection: $reportReason) {
                            Text("Select a reason").tag("")
                            Text("Inappropriate content").tag("Inappropriate content")
                            Text("Spam").tag("Spam")
                            Text("Harassment").tag("Harassment")
                            Text("Impersonation").tag("Impersonation")
                            Text("Other").tag("Other")
                        }
                    }
                }
                .navigationTitle("Report User")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            reportReason = ""
                            showReportSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Submit") {
                            Task {
                                await viewModel.reportUser(userID, reason: reportReason)
                                reportReason = ""
                                showReportSheet = false
                                showReportConfirmation = true
                            }
                        }
                        .disabled(reportReason.isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .alert("Report Submitted", isPresented: $showReportConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Thanks for letting us know. We'll review this user's account.")
        }
        .task {
            await loadUser()
        }
        .fullScreenCover(isPresented: $showPinDetail) {
            if let pin = selectedPin {
                PinInfoView(pin: pin, viewModel: viewModel)
                    .navigationTransition(.zoom(sourceID: pin.id, in: pinTransition))
            }
        }
    }

    private func loadUser() async {
        // Load user info
        if let cached = viewModel.usernameCache[userID] {
            let pic = viewModel.profilePictureCache[userID] ?? ""
            user = UserInfo(id: userID, username: cached, profilePicture: pic)
        } else {
            _ = viewModel.username(for: userID)
            try? await Task.sleep(for: .milliseconds(500))
            let name = viewModel.usernameCache[userID] ?? "Unknown"
            let pic = viewModel.profilePictureCache[userID] ?? ""
            user = UserInfo(id: userID, username: name, profilePicture: pic)
        }

        // Load user's pins
        userPins = viewModel.filteredPins.filter { $0.createdByUID == userID }
        isLoading = false
    }
}
