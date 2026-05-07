import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @State var showSaved: Bool = false
    @State private var selectedPin: PinInfo?
    @State private var showPinDetail = false
    @Namespace private var pinTransition
    @ObservedObject var viewModel: MapViewModel
    @Environment(AuthService.self) var authService
    var profileRefreshID: UUID = UUID()
    var validSavedPins: [PinInfo] {
        viewModel.filteredPins.filter { viewModel.savedPinIDs.contains($0.id ?? "") }
    }


    var myPins: [PinInfo] {
        guard let uid = Auth.auth().currentUser?.uid else { return [] }
        return viewModel.pins.filter { $0.createdByUID == uid }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    // MARK: - Profile Header
                    VStack(spacing: 12) {
                        profileAvatar
                            .frame(width: 110, height: 110)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.background, lineWidth: 3))
                            .shadow(radius: 4)
                            .id(authService.profileRefreshID)

                        Text(authService.currentUser?.username ?? "Skater")
                            .font(.title2.bold())

                        if let bio = authService.currentUser?.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }

                        // Stats
                        HStack(spacing: 0) {
                            StatBadge(value: myPins.count, label: "Spots")
                            Divider().frame(height: 30)
                            Button {
                                showSaved = true
                            } label: {
                                StatBadge(value: validSavedPins.count, label: "Saved")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 24)

                    Divider()

                    // MARK: - My Spots
                    VStack(alignment: .leading, spacing: 12) {
                        Text("My Spots")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top, 16)

                        if myPins.isEmpty {
                            ContentUnavailableView(
                                "No Spots Yet",
                                systemImage: "mappin.slash",
                                description: Text("Drop a pin on the map to see it here.")
                            )
                            .padding(.top)
                        } else {
                            ForEach(myPins) { pin in
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
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView(viewModel: viewModel)) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showPinDetail) {
            if let pin = selectedPin {
                PinInfoView(pin: pin, viewModel: viewModel)
                    .navigationTransition(.zoom(sourceID: pin.id, in: pinTransition))
            }
        }
        .fullScreenCover(isPresented: $showSaved) {
            SavedSpotsView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    var profileAvatar: some View {
        if let url = authService.currentUser?.profilePicture, !url.isEmpty {
            CachedAsyncImage(url: URL(string: url)) {
                Color.secondary.opacity(0.2)
            }
            .id(url)
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Stat Badge
    struct StatBadge: View {
        let value: Int
        let label: String
        var body: some View {
            VStack(spacing: 2) {
                Text("\(value)")
                    .font(.title2.bold())
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    let viewModel = MapViewModel()
    viewModel.pins = [
        PinInfo(id: "1", pinName: "Orem Skatepark", pinDetails: "Nice bowl.", latitude: 40.2969,
                longitude: -111.6946, createdByUID: "previewUID", createdByUsername: "Ethan", spotTypes: [.bowl]),
        PinInfo(id: "2", pinName: "Provo Gap", pinDetails: "Sketchy.", latitude: 40.2338,
                longitude: -111.6585, createdByUID: "previewUID", createdByUsername: "Ethan", spotTypes: [.gap])
    ]
    return ProfileView(viewModel: viewModel)
        .environment(AuthService())
}
