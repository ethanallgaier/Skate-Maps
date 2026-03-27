import SwiftUI
import MapKit

struct MapView: View {
    
    // MARK: - State
    
    @ObservedObject var viewModel: MapViewModel
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var pinCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()//dragndrop
    @State private var locationManager = LocationManager()
    @State private var selectedPin: PinInfo?
    @State private var showAddPin = false
    @State private var showPinDetail = false
    @State private var selectedTypes: Set<SpotType> = []
    @State private var searchText = ""
    
    @State private var ignoreNextCameraChange = false
    
    //track the camera
    @State private var position: MapCameraPosition = .automatic
    @State private var currentRegion: MKCoordinateRegion = MKCoordinateRegion()
    
    var filteredPins: [PinInfo] {
        guard !selectedTypes.isEmpty else { return viewModel.pins }
        
        return viewModel.pins.filter { pin in
            pin.spotTypes.contains { type in
                selectedTypes.contains(type)
            }
        }
    }
    
    // MARK: - Main
    var body: some View {
        ZStack(alignment: .top) {
            
            // MARK: -  MAP
            Map(position: $cameraPosition) {
                UserAnnotation()//forogt what this is
                //Each pin
                ForEach(viewModel.clusteredPins(for: currentRegion, from: filteredPins), id: \.first?.id) { cluster in
                    if cluster.count == 1, let pin = cluster.first {
                        // SINGLE PIN
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
                    } else if cluster.first != nil {
                        
                        let center = viewModel.centerCoordinate(of: cluster)
//COMBINED PINS
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
            
            .gesture(
                LongPressGesture(minimumDuration: 0.5)
                    .sequenced(before: DragGesture(minimumDistance: 0))
                    .onEnded { value in
                        // Get the coordinate of the map center (or you could calculate from touch location if using UIKit)
                        pinCoordinate = currentRegion.center
                        showAddPin = true
                    }
            )
            
            //for dragndrop pin
            .onMapCameraChange { context in
                let center = context.region.center
                let span = context.region.span
                
                // tweak this number to control how high the pin sits
                let verticalOffset = span.latitudeDelta * 0.25
                
                pinCoordinate = CLLocationCoordinate2D(
                    latitude: center.latitude + verticalOffset,
                    longitude: center.longitude
                )
            }
            //Whats this
            .onMapCameraChange(frequency: .onEnd) { context in //
                currentRegion = context.region //
                if ignoreNextCameraChange {
                    ignoreNextCameraChange = false
                } else {
                    selectedPin = nil
                }
            }
            .mapStyle(.hybrid(pointsOfInterest: .excludingAll))
            .mapControls { }//Leaving empty so compass wont appear
            .onAppear { viewModel.fetchPins() }
            
            .sheet(isPresented: $showAddPin) {
                AddPinView(viewModel: viewModel, coordinate: $pinCoordinate)
                    .presentationDetents([.medium])
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                    .interactiveDismissDisabled()
            }
            .fullScreenCover(isPresented: $showPinDetail) {
                if let pin = selectedPin {
                    PinInfoView(pin: pin, viewModel: viewModel)
                }
            }
            
            //PIN PLACEMENT
            if showAddPin {
                GeometryReader { geo in
                    ZStack {
                        MapViewModel.CircularTextPin()
                    }
                    .offset(y: -50)  // shifts image up so the tip lands at center
                    .position(x: geo.size.width / 2, y: geo.size.height / 2 - 160)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
            
            // MARK: TOP FEATURES
            if !showAddPin {
                VStack(spacing: 8) {
                    searchBar
                    searchResults
                    categoryChips
                }
                .padding(.top, 5)
            }
            
            // MARK: SIDE FEATURES
            if !showAddPin {
                ZStack(alignment: .bottomTrailing) {
                    Color.clear
                    VStack(spacing: 8) {
                        locationButton
                        addPinButton
                    }
                    .padding(.trailing)
                    .padding(.bottom, selectedPin != nil ? 140 : 40)
                }
            }
            
            // MARK:  PIN DETAIL CARD
            if let pin = selectedPin {
                VStack {
                    Spacer()
                    PinPreviewCard(pin: pin) {
                        showPinDetail = true
                    } onDismiss: {
                        selectedPin = nil
                        
                    }
                    .padding(.bottom, 20)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring, value: selectedPin)
    }
    
    
    
    // MARK: - SEARCH BAR
    var searchBar: some View {
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
                        .foregroundStyle(selectedTypes.isEmpty ? .blue : .primary)
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
                        Label(type.rawValue, systemImage: type.icon)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .foregroundStyle(selectedTypes.contains(type) ? .blue : .primary)
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
                .frame(width: 30, height: 40)
        }
        .buttonStyle(.glassProminent)
    }
    
    
    //MARK: - ADD NEW PIN BUTTON
    var addPinButton: some View {
        Button {
            pinCoordinate = currentRegion.center//center the map
            showAddPin = true
        } label: {
            Image(systemName: "plus")
                .foregroundStyle(.white)
                .bold()
                .frame(width: 30, height: 40)
        }
        .buttonStyle(.glassProminent)
    }
}

//#Preview {
//    MapView()
//}
