import SwiftUI
import MapKit

struct MapView: View {
    
    // MARK: - State
    
    @ObservedObject var viewModel: MapViewModel
    @ObservedObject var locationManager: LocationManager
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selectedPin: PinInfo?
    @State private var showAddPin = false
    @State private var showPinDetail = false
    @State private var selectedTypes: Set<SpotType> = []
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var selectedSkatepark: Skatepark?
    @State private var showGuestAlert = false
    
    @Environment(AuthService.self) var authService
    
    @Namespace private var pinTransition
    @State private var ignoreNextCameraChange = false
    
    @State private var currentRegion: MKCoordinateRegion = MKCoordinateRegion()
    
    var filteredPins: [PinInfo] {
        guard !selectedTypes.isEmpty else { return viewModel.filteredPins }
        
        return viewModel.filteredPins.filter { pin in
            pin.spotTypes.contains { type in
                selectedTypes.contains(type)
            }
        }
    }

    /// All pins (user + skateparks) unified and clustered, capped at 50
    var unifiedClusters: [[MapPin]] {
        guard currentRegion.span.latitudeDelta > 0.0001 else { return [] }

        var allPins: [MapPin] = filteredPins.compactMap { pin in
            guard pin.id != nil else { return nil }
            return .userPin(pin)
        }

        if viewModel.showSkateparks, !viewModel.skateparks.isEmpty {
            let halfLat = currentRegion.span.latitudeDelta / 2 * 1.1
            let halfLon = currentRegion.span.longitudeDelta / 2 * 1.1
            let visibleParks = viewModel.skateparks.filter { park in
                abs(park.latitude - currentRegion.center.latitude) <= halfLat &&
                abs(park.longitude - currentRegion.center.longitude) <= halfLon
            }
            allPins += visibleParks.map { .skatepark($0) }
        }

        guard !allPins.isEmpty else { return [] }

        let clusters = viewModel.clusteredMapPins(for: currentRegion, from: allPins)
        guard clusters.count > 50 else { return clusters }

        let center = currentRegion.center
        return Array(clusters.sorted { a, b in
            let aPin = a.first!
            let bPin = b.first!
            let aDist = abs(aPin.latitude - center.latitude) + abs(aPin.longitude - center.longitude)
            let bDist = abs(bPin.latitude - center.latitude) + abs(bPin.longitude - center.longitude)
            return aDist < bDist
        }.prefix(50))
    }
    
    // MARK: - Main
    var body: some View {
        ZStack(alignment: .top) {
            
            // MARK: -  MAP
            Map(position: $cameraPosition) {
                UserAnnotation()//forogt what this is
                // MARK: - Unified Pin Annotations
                ForEach(unifiedClusters, id: \.first?.id) { cluster in
                    if cluster.count == 1, let item = cluster.first {
                        switch item {
                        case .userPin(let pin):
                            Annotation(pin.pinName, coordinate: pin.coordinate) {
                                MapViewModel.PinMarker {
                                    selectedPin = pin
                                    ignoreNextCameraChange = true
                                    withAnimation(.spring) {
                                        cameraPosition = .region(MKCoordinateRegion(
                                            center: pin.coordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                        ))
                                    }
                                }
                            }
                        case .skatepark(let park):
                            Annotation(park.name, coordinate: park.coordinate) {
                                MapViewModel.SkateparkMarker {
                                    selectedPin = nil
                                    selectedSkatepark = park
                                    viewModel.resolveNameIfNeeded(for: park)
                                    ignoreNextCameraChange = true
                                    withAnimation(.spring) {
                                        cameraPosition = .region(MKCoordinateRegion(
                                            center: park.coordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                        ))
                                    }
                                }
                            }
                        }
                    } else if cluster.first != nil {
                        let center = viewModel.centerCoordinate(of: cluster)
                        Annotation("", coordinate: center) {
                            Button {
                                ignoreNextCameraChange = true
                                withAnimation(.spring) {
                                    cameraPosition = .region(MKCoordinateRegion(
                                        center: center,
                                        span: MKCoordinateSpan(
                                            latitudeDelta: currentRegion.span.latitudeDelta * 0.4,
                                            longitudeDelta: currentRegion.span.longitudeDelta * 0.4
                                        )
                                    ))
                                }
                            } label: {
                                MapViewModel.ClusterBubble(count: cluster.count)
                            }
                        }
                    }
                }
            }
            
            
            .onMapCameraChange(frequency: .onEnd) { context in
                currentRegion = context.region
                if ignoreNextCameraChange {
                    ignoreNextCameraChange = false
                } else if !showPinDetail {
                    selectedPin = nil
                    selectedSkatepark = nil
                }
                viewModel.fetchSkateparksIfNeeded(for: context.region)
            }
            .mapStyle(.hybrid(pointsOfInterest: .excludingAll))
            .mapControls { }//Leaving empty so compass wont appear
            .onAppear { viewModel.fetchPins() }
            
            .sheet(isPresented: $showAddPin) {
                AddPinView(viewModel: viewModel, initialRegion: currentRegion)
            }
            .fullScreenCover(isPresented: $showPinDetail) {
                if let pin = selectedPin {
                    PinInfoView(pin: pin, viewModel: viewModel)
                        .navigationTransition(.zoom(sourceID: pin.id, in: pinTransition))
                }
            }
            
            
            
            // MARK: TOP FEATURES
            VStack(spacing: 0) {
                searchBar
                searchResults

                categoryChips
                    .padding(.top, 8)
                    .offset(y: showFilters ? 0 : -50)
                    .opacity(showFilters ? 1 : 0)
                    .clipped()
                    .frame(height: showFilters ? nil : 0, alignment: .top)
            }
            .padding(.top, 5)
            .animation(.smooth(duration: 0.3), value: showFilters)
            
            // MARK: SIDE FEATURES
            ZStack(alignment: .bottomTrailing) {
                    Color.clear
                    VStack(spacing: 8) {
                       
                        addPinButton
                       
                        skateparkToggle
                        locationButton
                    }
                    .padding(.trailing)
                    .padding(.bottom, (selectedPin != nil || selectedSkatepark != nil) ? 140 : 40)
                }
            
            // MARK:  PIN DETAIL CARD
            if let pin = selectedPin {
                VStack {
                    Spacer()
                    PinPreviewCard(pin: pin, viewModel: viewModel) {
                        withAnimation(.spring(duration: 0.8, bounce: 0.2)) {
                            showPinDetail = true
                        }
                    } onDismiss: {
                        selectedPin = nil
                        
                    }
                    .matchedTransitionSource(id: pin.id, in: pinTransition)
                    .padding(.bottom, 20)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // MARK: SKATEPARK PREVIEW CARD
            if let parkID = selectedSkatepark?.id,
               let park = viewModel.skateparks.first(where: { $0.id == parkID }) {
                VStack {
                    Spacer()
                    skateparkPreviewCard(park)
                        .padding(.bottom, 20)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring, value: selectedPin)
        .animation(.spring, value: selectedSkatepark)
    }
    
    
    
    // MARK: - SEARCH BAR
    var searchBar: some View {
        HStack(spacing: 10) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color(.placeholderText))
                TextField("Search city or place...", text: $searchText)
                    .onChange(of: searchText) { _, newValue in
                        if newValue.isEmpty {
                            viewModel.searchResults = []
                        } else {
                            viewModel.searchLocation(query: newValue)
                        }
                    }
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        viewModel.searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .glassEffect()

            // Filter toggle
            Button {
                showFilters.toggle()
            } label: {
                Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(!selectedTypes.isEmpty ? Color(red: 0.0, green: 0.1, blue: 0.4) : .white)
                    .padding(10)
                    .contentShape(Rectangle())
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .glassEffect()
        }
        .padding(.horizontal)
    }
    
    
    
    @ViewBuilder
    
    //MARK: - SEARCH RESULTS
    var searchResults: some View {
        if !viewModel.searchResults.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.searchResults, id: \.self) { item in
                    Button {
                        let coord = item.location.coordinate
                        cameraPosition = .region(MKCoordinateRegion(
                            center: coord,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        ))
                        searchText = item.name ?? ""
                        viewModel.searchResults = []
                    } label: {
                        Text(item.name ?? "")
                            .foregroundStyle(.primary)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .glassEffect()
                    }
                    Divider()
                }
            }
            .padding(.horizontal)
        }
    }
    
    
    //MARK: - SPOT TYPE
    var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    selectedTypes = []
                } label: {
                    Text("All")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .foregroundStyle(selectedTypes.isEmpty ? .white : .primary)
                        .background(selectedTypes.isEmpty ? Color(red: 0.0, green: 0.1, blue: 0.4) : .clear, in: Capsule())
                        .glassEffect()
                }
                ForEach(SpotType.allCases, id: \.self) { type in
                    Button {
                        if selectedTypes.contains(type) {
                            selectedTypes.remove(type)
                        } else {
                            selectedTypes.insert(type)
                        }
                    } label: {
                        Text(type.rawValue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .foregroundStyle(selectedTypes.contains(type) ? .white : .primary)
                            .background(selectedTypes.contains(type) ? Color(red: 0.0, green: 0.1, blue: 0.4) : .clear, in: Capsule())
                            .glassEffect()
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    
    //MARK: - CURRENT LOCATION BUTTON
    var locationButton: some View {
        Button {
            cameraPosition = .userLocation(fallback: .automatic)
        } label: {
            Image(systemName: "location.fill")
                .foregroundStyle(.white)
                .bold()
                .frame(width: 55, height: 55)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassEffect()
    }
    
    
    //MARK: - ADD NEW PIN BUTTON
    var addPinButton: some View {
        Button {
            if authService.isGuest {
                showGuestAlert = true
            } else {
                showAddPin = true
            }
        } label: {
            Image(systemName: "plus")
                .foregroundStyle(.white)
                .bold()
                .frame(width: 55, height: 55)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassEffect()
        .alert("Sign In Required", isPresented: $showGuestAlert) {
            Button("Sign In") {
                authService.exitGuestMode()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You need to sign in to add a pin.")
        }
    }

    // MARK: - SKATEPARK TOGGLE BUTTON
    var skateparkToggle: some View {
        Button {
            withAnimation {
                viewModel.showSkateparks.toggle()
                if !viewModel.showSkateparks {
                    selectedSkatepark = nil
                }
            }
        } label: {
            Group {
                if viewModel.isLoadingSkateparks && viewModel.showSkateparks {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "figure.skating")
                        .foregroundStyle(viewModel.showSkateparks ? .white : .gray)
                        .bold()
                }
            }
            .frame(width: 55, height: 55)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassEffect()
    }

    // MARK: - SKATEPARK PREVIEW CARD
    func skateparkPreviewCard(_ park: Skatepark) -> some View {
        Button {
            // Open in Apple Maps
            let mapItem = MKMapItem(location: CLLocation(latitude: park.latitude, longitude: park.longitude), address: nil)
            mapItem.name = park.name
            mapItem.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ])
        } label: {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.green.opacity(0.2))
                        .frame(width: 70, height: 70)
                    Image(systemName: "figure.skating")
                        .font(.title)
                        .foregroundStyle(.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(park.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                        .lineLimit(2)
                    HStack(spacing: 8) {
                        if let surface = park.surface {
                            Text(surface.capitalized)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(.green.opacity(0.15), in: Capsule())
                        }
                        Text("Tap for directions")
                            .font(.system(size: 10))
                            .foregroundStyle(.green)
                    }
                }

                Spacer()

                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                    .foregroundStyle(.green)
            }
            .padding()
            .glassEffect(in: .rect(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
}

//#Preview {
//    MapView()
//}
