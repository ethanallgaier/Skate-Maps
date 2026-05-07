//
//  PinInfoView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/2/26.
//

import SwiftUI
import PhotosUI
import FirebaseAuth
import MapKit

// MARK: - Main View

struct PinInfoView: View {
    var pin: PinInfo

    @ObservedObject var viewModel: MapViewModel

    @State private var currentPage: Int = 0
    @State private var isExpanded: Bool = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var isUploading = false
    @State private var showCamera = false
    @State private var showDeleteConfirm = false

    @State private var isEditing = false
    @State private var editedName = ""
    @State private var editedDetails = ""
    @State private var editedSpotTypes: Set<SpotType> = []
    @State private var editedRiskLevel: RiskLevel = .low
    @State private var editedDifficulty: DifficultyLevel = .beginner
    @State private var editedSurface: SurfaceQuality = .decent
    @State private var editedBestTimes: Set<BestTime> = []
    @State private var isSaving = false
    @State private var showEditContentFilterAlert = false

    @State private var showReportSheet = false
    @State private var reportReason = ""
    @State private var showReportConfirmation = false
    @State private var showGuestAlert = false
    @State private var showBlockConfirm = false
    @State private var showBlockedAlert = false
    @State private var showCommentFilterAlert = false
    @State private var showCommentReportSheet = false
    @State private var commentToReport: Comment?
    @State private var commentReportReason = ""
    @State private var showCommentReportConfirmation = false

    @State private var weather: SpotWeather?
    @State private var distanceText: String?
    @State private var showRatingSheet = false

    @State private var comments: [Comment] = []
    @State private var commentsExpanded = false
    @State private var newCommentText = ""
    @State private var isPostingComment = false

    @State private var profileUserID: String?

    @Environment(\.dismiss) var dismiss
    @Environment(AuthService.self) var authService

    var isOwner: Bool {
        Auth.auth().currentUser?.uid == currentPin.createdByUID
    }

    @State private var currentPin: PinInfo

    init(pin: PinInfo, viewModel: MapViewModel) {
        self.pin = pin
        self.viewModel = viewModel
        _currentPin = State(initialValue: pin)
    }

    var myRating: Int {
        guard let uid = Auth.auth().currentUser?.uid else { return 0 }
        return currentPin.ratings[uid] ?? 0
    }

    private let overviewPreviewLength = 120

    var overviewText: String {
        let details = currentPin.pinDetails
        if isExpanded || details.count <= overviewPreviewLength {
            return details
        }
        return String(details.prefix(overviewPreviewLength))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: Photos
                    captures

                    // MARK: - Photo Management (inline with carousel)
                    if isOwner {
                        photosSection
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                    }

                    // MARK: - Content
                    VStack(alignment: .leading, spacing: 20) {

                        // MARK: - Title
                        if isEditing {
                            TextField("Spot name", text: $editedName)
                                .font(.system(size: 30, weight: .black, design: .rounded))
                                .submitLabel(.done)
                        } else {
                            Text(currentPin.pinName)
                                .font(.system(size: 30, weight: .black, design: .rounded))
                        }

                        // MARK: - Subtitle: creator + date + rating
                        if !isEditing {
                            HStack(spacing: 6) {
                                Button {
                                    profileUserID = currentPin.createdByUID
                                } label: {
                                    HStack(spacing: 5) {
                                        if let picURL = viewModel.profilePicture(for: currentPin.createdByUID) {
                                            CachedAsyncImage(url: URL(string: picURL)) {
                                                Image(systemName: "person.circle.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundStyle(.secondary)
                                            }
                                            .frame(width: 18, height: 18)
                                            .clipShape(Circle())
                                        } else {
                                            Image(systemName: "person.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(.secondary)
                                        }
                                        Text(viewModel.username(for: currentPin.createdByUID))
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                                Text("·")
                                    .foregroundColor(.secondary.opacity(0.6))
                                Text(currentPin.time.formatted(date: .abbreviated, time: .omitted))
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                Text("·")
                                    .foregroundColor(.secondary.opacity(0.6))
                                HStack(spacing: 3) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.yellow)
                                    Text(currentPin.averageRating > 0 ? String(format: "%.1f", currentPin.averageRating) : "—")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Text("(\(currentPin.ratings.count))")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary.opacity(0.7))
                                }
                            }
                        }

                        // MARK: - Action Bar
                        if !isEditing {
                            actionBar
                        }

                        // MARK: - OVERVIEW (first per 3B)
                        if !currentPin.pinDetails.isEmpty || isEditing {
                            overviewSection
                        }

                        // MARK: - SPOT TYPE CHIPS (no icons, filled capsules)
                        spotTypeSection

                        // MARK: - INFO CARD GRID (2x2, equal height)
                        infoCardSection

                        // MARK: - WEATHER
                        if !isEditing {
                            weatherSection
                        }

                        // MARK: - COMMENTS
                        if !isEditing {
                            commentsSection
                        }

                        // MARK: Location Map
                        if !isEditing {
                            locationSection
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
        }
        .navigationBarHidden(true)
        .task {
            weather = await WeatherService.shared.fetchWeather(
                latitude: currentPin.latitude,
                longitude: currentPin.longitude
            )

            // Calculate distance/travel time from user's location
            await calculateDistance()

            // Fetch comments (filter out blocked users)
            let allComments = await viewModel.fetchComments(for: currentPin)
            comments = allComments.filter { !viewModel.isBlocked($0.authorUID) }
        }
        .onChange(of: viewModel.pins) { _, newPins in
            if let updated = newPins.first(where: { $0.id == currentPin.id }) {
                currentPin = updated
            }
        }
        .fullScreenCover(isPresented: $showCamera, onDismiss: {
            guard !selectedImages.isEmpty else { return }
            let imagesToUpload = selectedImages
            isUploading = true
            Task {
                await viewModel.addPhotos(to: currentPin, images: imagesToUpload)
                await MainActor.run {
                    selectedImages = []
                    isUploading = false
                }
            }
        }) {
            CameraPicker(images: $selectedImages)
        }
        .sheet(isPresented: $showReportSheet) {
            NavigationStack {
                Form {
                    Section("Why are you reporting this spot?") {
                        Picker("Reason", selection: $reportReason) {
                            Text("Select a reason").tag("")
                            Text("Inappropriate content").tag("Inappropriate content")
                            Text("Spam").tag("Spam")
                            Text("Wrong location").tag("Wrong location")
                            Text("Offensive language").tag("Offensive language")
                            Text("Other").tag("Other")
                        }
                    }
                }
                .navigationTitle("Report Spot")
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
                                await viewModel.reportPin(currentPin, reason: reportReason)
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
            Text("Thanks for letting us know. We'll review this spot.")
        }
        .confirmationDialog("Block this user?", isPresented: $showBlockConfirm, titleVisibility: .visible) {
            Button("Block", role: .destructive) {
                Task {
                    await viewModel.blockUser(currentPin.createdByUID)
                    showBlockedAlert = true
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All content from \(viewModel.username(for: currentPin.createdByUID)) will be hidden from your feed. This also notifies our moderation team.")
        }
        .alert("User Blocked", isPresented: $showBlockedAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("You will no longer see content from this user.")
        }
        .sheet(isPresented: $showRatingSheet) {
            VStack(spacing: 16) {
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)

                Text("Rate this spot")
                    .font(.system(size: 20, weight: .bold))

                Text(currentPin.pinName)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)

                StarRatingView(rating: currentPin.averageRating, userRating: myRating) { stars in
                    Task {
                        await viewModel.ratePin(currentPin, stars: stars)
                        showRatingSheet = false
                    }
                }
                .padding(.vertical, 8)

                if currentPin.averageRating > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f avg", currentPin.averageRating))
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Text("(\(currentPin.ratings.count) \(currentPin.ratings.count == 1 ? "rating" : "ratings"))")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary.opacity(0.7))
                    }
                }

                if myRating > 0 {
                    Button {
                        Task {
                            await viewModel.removeRating(currentPin)
                            showRatingSheet = false
                        }
                    } label: {
                        Text("Remove my rating")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.hidden)
        }
        .alert("Content Not Allowed", isPresented: $showEditContentFilterAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your spot name or details contain inappropriate content. Please revise and try again.")
        }
        .alert("Comment Not Allowed", isPresented: $showCommentFilterAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your comment contains inappropriate content. Please revise and try again.")
        }
        .sheet(isPresented: $showCommentReportSheet) {
            NavigationStack {
                Form {
                    Section("Why are you reporting this comment?") {
                        Picker("Reason", selection: $commentReportReason) {
                            Text("Select a reason").tag("")
                            Text("Inappropriate content").tag("Inappropriate content")
                            Text("Spam").tag("Spam")
                            Text("Harassment").tag("Harassment")
                            Text("Offensive language").tag("Offensive language")
                            Text("Other").tag("Other")
                        }
                    }
                }
                .navigationTitle("Report Comment")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            commentReportReason = ""
                            commentToReport = nil
                            showCommentReportSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Submit") {
                            Task {
                                if let comment = commentToReport {
                                    await viewModel.reportComment(comment, on: currentPin, reason: commentReportReason)
                                }
                                commentReportReason = ""
                                commentToReport = nil
                                showCommentReportSheet = false
                                showCommentReportConfirmation = true
                            }
                        }
                        .disabled(commentReportReason.isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .alert("Report Submitted", isPresented: $showCommentReportConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Thanks for letting us know. We'll review this comment.")
        }
        .alert("Sign In Required", isPresented: $showGuestAlert) {
            Button("Sign In") {
                authService.exitGuestMode()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You need to sign in to interact with pins.")
        }
        .sheet(isPresented: Binding(
            get: { profileUserID != nil },
            set: { if !$0 { profileUserID = nil } }
        )) {
            if let userID = profileUserID {
                NavigationStack {
                    UserProfileView(userID: userID, viewModel: viewModel)
                }
            }
        }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 10) {
            // Save
            actionButton(
                icon: viewModel.isSaved(currentPin) ? "bookmark.fill" : "bookmark",
                label: viewModel.isSaved(currentPin) ? "Saved" : "Save",
                active: viewModel.isSaved(currentPin)
            ) {
                if authService.isGuest {
                    showGuestAlert = true
                } else {
                    viewModel.toggleSave(pin: currentPin)
                }
            }

            // Edit (owner only)
            if isOwner {
                actionButton(icon: "pencil", label: "Edit") {
                    editedName = currentPin.pinName
                    editedDetails = currentPin.pinDetails
                    editedSpotTypes = Set(currentPin.spotTypes)
                    editedRiskLevel = currentPin.riskLevel
                    editedDifficulty = currentPin.difficultyLevel
                    editedSurface = currentPin.surfaceQuality ?? .decent
                    editedBestTimes = Set(currentPin.bestTimes ?? [])
                    isEditing = true
                }
            }

            // Rate
            actionButton(
                icon: myRating > 0 ? "star.fill" : "star",
                label: "Rate",
                active: myRating > 0
            ) {
                if authService.isGuest {
                    showGuestAlert = true
                } else {
                    showRatingSheet = true
                }
            }

            // Delete (owner) or Report (non-owner)
            if isOwner {
                actionButton(icon: "trash", label: "Delete", destructive: true) {
                    showDeleteConfirm = true
                }
                .confirmationDialog("Delete this pin?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                    Button("Delete", role: .destructive) {
                        Task {
                            await viewModel.deletePin(currentPin)
                            dismiss()
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
            } else if !authService.isGuest {
                actionButton(icon: "flag", label: "Report") {
                    showReportSheet = true
                }

                actionButton(icon: "person.slash.fill", label: "Block", destructive: true) {
                    showBlockConfirm = true
                }
            }
        }
    }

    private func actionButton(icon: String, label: String, active: Bool = false, destructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .frame(width: 44, height: 44)
                    .background(
                        destructive ? Color.red.opacity(0.1) :
                        active ? Color.blue.opacity(0.15) :
                        Color(.systemGray6)
                    )
                    .clipShape(Circle())
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(destructive ? .red : active ? .blue : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Overview")

            if isEditing {
                TextEditor(text: $editedDetails)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .frame(minHeight: 80, maxHeight: 150)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
            } else {
                Text(overviewText)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.primary.opacity(0.8))
                    .lineSpacing(5)

                if !isExpanded && currentPin.pinDetails.count > overviewPreviewLength {
                    HStack(spacing: 0) {
                        Text("… ")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                        Button("read more") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded = true
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                    }
                }
            }
        }
    }

    // MARK: - Spot Type Section

    @ViewBuilder
    private var spotTypeSection: some View {
        if isEditing || !currentPin.spotTypes.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader("Spot Type")

                if isEditing {
                    FlowLayout(spacing: 8) {
                        ForEach(SpotType.allCases, id: \.self) { type in
                            Button {
                                if editedSpotTypes.contains(type) {
                                    editedSpotTypes.remove(type)
                                } else {
                                    editedSpotTypes.insert(type)
                                }
                            } label: {
                                Text(type.rawValue)
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(editedSpotTypes.contains(type) ? Color.blue : Color(.systemGray5))
                                    .foregroundStyle(editedSpotTypes.contains(type) ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(currentPin.spotTypes, id: \.self) { type in
                            Text(type.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray5))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    // MARK: - Info Card Grid Section

    private var infoCardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Spot Details")

            if isEditing {
                editingInfoCards
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    InfoCard(
                        title: "Difficulty",
                        value: currentPin.difficultyLevel.label,
                        icon: currentPin.difficultyLevel.icon,
                        color: currentPin.difficultyLevel.color
                    )
                    InfoCard(
                        title: "Bust Factor",
                        value: currentPin.riskLevel.label,
                        subtitle: currentPin.riskLevel.subtitle,
                        icon: currentPin.riskLevel.icon,
                        color: currentPin.riskLevel.color
                    )
                    InfoCard(
                        title: "Surface",
                        value: (currentPin.surfaceQuality ?? .decent).label,
                        icon: (currentPin.surfaceQuality ?? .decent).icon,
                        color: (currentPin.surfaceQuality ?? .decent).color
                    )
                    InfoCard(
                        title: "Best Time",
                        value: (currentPin.bestTimes ?? []).isEmpty ? "Anytime" : (currentPin.bestTimes ?? []).map(\.rawValue).joined(separator: ", "),
                        icon: (currentPin.bestTimes ?? []).first?.icon ?? "clock.fill",
                        color: (currentPin.bestTimes ?? []).first?.color ?? .blue
                    )
                }
            }
        }
    }

    // MARK: - Weather Section

    private var weatherSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Current Weather")

            if let weather {
                HStack(spacing: 16) {
                    // Weather icon + condition
                    VStack(spacing: 6) {
                        Image(systemName: weather.icon)
                            .font(.system(size: 32))
                            .foregroundStyle(.blue)
                            .symbolRenderingMode(.multicolor)
                        Text(weather.conditionLabel)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 80)

                    // Stats
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Label("\(Int(weather.temperature))°F", systemImage: "thermometer.medium")
                                .font(.system(size: 14, weight: .semibold))
                            Label("\(Int(weather.windSpeed)) mph", systemImage: "wind")
                                .font(.system(size: 14, weight: .semibold))
                        }

                        // Skate verdict
                        HStack(spacing: 6) {
                            Circle()
                                .fill(weather.verdictColor == "green" ? Color.green : weather.verdictColor == "orange" ? Color.orange : Color.red)
                                .frame(width: 8, height: 8)
                            Text(weather.skateVerdict)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(weather.verdictColor == "green" ? Color.green : weather.verdictColor == "orange" ? Color.orange : Color.red)
                        }
                    }

                    Spacer()
                }
                .padding(16)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Loading weather…")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Comments Section

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Comments")

            // Collapsed card preview
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    commentsExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(comments.isEmpty ? "No comments yet" : "\(comments.count) \(comments.count == 1 ? "comment" : "comments")")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                        if let latest = comments.first {
                            Text("\(latest.authorUsername): \(latest.text)")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        } else {
                            Text("Be the first to comment")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(commentsExpanded ? 90 : 0))
                }
                .padding(14)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            // Expanded comments list
            if commentsExpanded {
                VStack(spacing: 0) {
                    // Comment input
                    HStack(spacing: 10) {
                        TextField("Add a comment…", text: $newCommentText)
                            .font(.system(size: 14))
                            .textFieldStyle(.plain)

                        Button {
                            guard !newCommentText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            isPostingComment = true
                            let text = newCommentText
                            newCommentText = ""
                            Task {
                                guard ContentFilter.isClean(text) else {
                                    showCommentFilterAlert = true
                                    isPostingComment = false
                                    return
                                }
                                await viewModel.addComment(
                                    to: currentPin,
                                    text: text,
                                    username: authService.currentUser?.username ?? "Unknown"
                                )
                                comments = await viewModel.fetchComments(for: currentPin)
                                isPostingComment = false
                            }
                        } label: {
                            Image(systemName: isPostingComment ? "hourglass" : "arrow.up.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(newCommentText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.secondary : Color.blue)
                        }
                        .disabled(newCommentText.trimmingCharacters(in: .whitespaces).isEmpty || isPostingComment)
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    if comments.isEmpty {
                        Text("No comments yet. Start the conversation!")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(comments) { comment in
                            commentRow(comment)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func commentRow(_ comment: Comment) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if let picURL = viewModel.profilePicture(for: comment.authorUID) {
                CachedAsyncImage(url: URL(string: picURL)) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary.opacity(0.5))
                }
                .frame(width: 30, height: 30)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary.opacity(0.5))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Button {
                        profileUserID = comment.authorUID
                    } label: {
                        Text(comment.authorUsername)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    Text(comment.time.formatted(.relative(presentation: .named)))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Text(comment.text)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary.opacity(0.85))
            }

            Spacer()

            if comment.authorUID == Auth.auth().currentUser?.uid {
                // Delete button for own comments
                Button {
                    Task {
                        if let commentID = comment.id {
                            await viewModel.deleteComment(from: currentPin, commentID: commentID)
                            comments = await viewModel.fetchComments(for: currentPin)
                        }
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            } else if !authService.isGuest {
                // Report button for other users' comments
                Menu {
                    Button {
                        commentToReport = comment
                        showCommentReportSheet = true
                    } label: {
                        Label("Report Comment", systemImage: "flag")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
    }

    // MARK: - Photos Section

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if isEditing {
                sectionHeader("Manage Photos")
            }

            if isEditing && !currentPin.imageURls.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(currentPin.imageURls.enumerated()), id: \.offset) { index, url in
                            ZStack(alignment: .topTrailing) {
                                CachedAsyncImage(url: URL(string: url)) {
                                    Rectangle()
                                        .fill(Color(.systemGray5))
                                        .overlay(ProgressView())
                                }
                                .frame(width: 90, height: 90)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                                Button {
                                    Task {
                                        await viewModel.deletePhoto(from: currentPin, at: index)
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(.white, .black.opacity(0.7))
                                        .padding(4)
                                }
                            }
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .images) {
                    Label(isUploading ? "Uploading…" : "Library", systemImage: "photo.on.rectangle.angled")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }
                .disabled(isUploading)
                .onChange(of: selectedItems) { _, newItems in
                    guard !newItems.isEmpty else { return }
                    isUploading = true
                    Task {
                        var images: [UIImage] = []
                        for item in newItems {
                            if let data = try? await item.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                images.append(image)
                            }
                        }
                        await viewModel.addPhotos(to: currentPin, images: images)
                        await MainActor.run {
                            selectedItems = []
                            selectedImages = []
                            isUploading = false
                        }
                    }
                }

                Button {
                    showCamera = true
                } label: {
                    Label(isUploading ? "Uploading…" : "Camera", systemImage: "camera")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }
                .disabled(isUploading)
            }
        }
    }

    // MARK: - Location Section

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Location")

            Map(initialPosition: .region(MKCoordinateRegion(
                center: currentPin.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))) {
                Marker(currentPin.pinName, coordinate: currentPin.coordinate)
                    .tint(.red)
            }
            .mapStyle(.hybrid)
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .disabled(true)
        }
    }

    // MARK: - Editing Info Cards

    private var editingInfoCards: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Difficulty
            editPickerSection(title: "Difficulty", subtitle: "How hard is this spot to skate?") {
                HStack(spacing: 8) {
                    ForEach(DifficultyLevel.allCases, id: \.self) { level in
                        editPickerCard(
                            icon: level.icon,
                            label: level.label,
                            color: level.color,
                            selected: editedDifficulty == level
                        ) {
                            editedDifficulty = level
                        }
                    }
                }
            }

            // Bust Factor
            editPickerSection(title: "Bust Factor", subtitle: "How likely are you to get kicked out?") {
                HStack(spacing: 8) {
                    ForEach(RiskLevel.allCases, id: \.self) { level in
                        editPickerCard(
                            icon: level.icon,
                            label: level.label,
                            color: level.color,
                            selected: editedRiskLevel == level
                        ) {
                            editedRiskLevel = level
                        }
                    }
                }
            }

            // Surface Quality
            editPickerSection(title: "Surface Quality", subtitle: "How smooth is the ground?") {
                HStack(spacing: 8) {
                    ForEach(SurfaceQuality.allCases, id: \.self) { level in
                        editPickerCard(
                            icon: level.icon,
                            label: level.label,
                            color: level.color,
                            selected: editedSurface == level
                        ) {
                            editedSurface = level
                        }
                    }
                }
            }

            // Best Time to Skate
            editPickerSection(title: "Best Time to Skate", subtitle: "Select all that apply") {
                HStack(spacing: 8) {
                    ForEach(BestTime.allCases, id: \.self) { time in
                        editPickerCard(
                            icon: time.icon,
                            label: time.rawValue,
                            color: time.color,
                            selected: editedBestTimes.contains(time)
                        ) {
                            if editedBestTimes.contains(time) {
                                editedBestTimes.remove(time)
                            } else {
                                editedBestTimes.insert(time)
                            }
                        }
                    }
                }
            }
        }
    }

    private func editPickerSection<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func editPickerCard(icon: String, label: String, color: Color, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selected ? color.opacity(0.15) : Color(.systemGray6))
            .foregroundStyle(selected ? color : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(selected ? color.opacity(0.5) : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Top Picture Bar

    @ViewBuilder
    private var captures: some View {
        ZStack(alignment: .bottom) {
            if currentPin.imageURls.isEmpty {
                LinearGradient(
                    colors: [Color(red: 0.12, green: 0.12, blue: 0.16), Color(red: 0.22, green: 0.22, blue: 0.28)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    Image(systemName: "figure.skateboarding")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.18))
                )
            } else {
                TabView(selection: $currentPage) {
                    ForEach(Array(currentPin.imageURls.enumerated()), id: \.offset) { index, url in
                        CachedAsyncImage(url: URL(string: url)) {
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .overlay(ProgressView())
                        }
                        .tag(index)
                        .clipped()
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.25)],
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 56)
                Spacer()
            }

            if currentPin.imageURls.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<currentPin.imageURls.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? Color.blue : Color.white.opacity(0.6))
                            .frame(width: currentPage == index ? 20 : 7, height: 7)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 14)
            }
        }
        .frame(height: 300)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            if isEditing {
                Button {
                    guard ContentFilter.isClean(editedName) && ContentFilter.isClean(editedDetails) else {
                        showEditContentFilterAlert = true
                        return
                    }
                    isSaving = true
                    Task {
                        await viewModel.updatePin(
                            currentPin,
                            name: editedName,
                            details: editedDetails,
                            spotTypes: Array(editedSpotTypes),
                            riskLevel: editedRiskLevel,
                            difficultyLevel: editedDifficulty,
                            surfaceQuality: editedSurface,
                            bestTimes: Array(editedBestTimes)
                        )
                        isSaving = false
                        isEditing = false
                    }
                } label: {
                    Label(isSaving ? "Saving…" : "Save Changes", systemImage: isSaving ? "hourglass" : "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue, in: Capsule())
                }
                .disabled(isSaving || editedName.trimmingCharacters(in: .whitespaces).isEmpty)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    if let distanceText {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16))
                            Text(distanceText)
                                .font(.system(size: 22, weight: .bold))
                        }
                        Text("away")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    } else {
                        HStack(spacing: 6) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Calculating…")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Button {
                    openInMaps()
                } label: {
                    Label("Get Directions", systemImage: "map.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 16)
                        .background(Color.blue, in: Capsule())
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            .ultraThinMaterial
                .shadow(.drop(color: .black.opacity(0.08), radius: 12, y: -4))
        )
        .animation(.easeInOut(duration: 0.2), value: isEditing)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }

    private func calculateDistance() async {
        let pinLocation = CLLocation(latitude: currentPin.latitude, longitude: currentPin.longitude)
        let destination = MKMapItem(location: pinLocation, address: nil)

        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destination
        request.transportType = .automobile

        do {
            let directions = MKDirections(request: request)
            let response = try await directions.calculate()
            if let route = response.routes.first {
                let seconds = route.expectedTravelTime
                if seconds < 3600 {
                    let minutes = Int(seconds / 60)
                    distanceText = "\(max(1, minutes)) min"
                } else {
                    let hours = seconds / 3600
                    distanceText = String(format: "%.1f hr", hours)
                }
            }
        } catch {
            // Fallback to straight-line distance
            let userLocation = CLLocationManager().location
            if let userLocation {
                let pinLocation = CLLocation(latitude: currentPin.latitude, longitude: currentPin.longitude)
                let meters = userLocation.distance(from: pinLocation)
                let miles = meters / 1609.34
                if miles < 0.5 {
                    let feet = Int(meters * 3.281)
                    distanceText = "\(feet) ft"
                } else {
                    distanceText = String(format: "%.1f mi", miles)
                }
            } else {
                distanceText = nil
            }
        }
    }

    func openInMaps() {
        let location = CLLocation(latitude: currentPin.coordinate.latitude, longitude: currentPin.coordinate.longitude)
        let mapItem = MKMapItem(location: location, address: nil)
        mapItem.name = currentPin.pinName
        mapItem.openInMaps()
    }
}

// MARK: - Info Card Component

struct InfoCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title at the top so users know the category immediately
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(0.5)

            Spacer(minLength: 0)

            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .padding(14)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}
