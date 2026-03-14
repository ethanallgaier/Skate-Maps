import SwiftUI
import MapKit

struct MapView: View {

    // MARK: - State
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var locationManager = LocationManager()
    @StateObject var viewModel = MapViewModel()
    @State private var selectedPin: PinInfo?
    @State private var showAddPin = false
    @State private var showPinDetail = false
    @State private var selectedType: SpotType? = nil
    @State private var searchText = ""
    
    @State private var ignoreNextCameraChange = false


    var filteredPins: [PinInfo] {
        guard let selectedType else { return viewModel.pins }
        return viewModel.pins.filter { $0.spotType == selectedType }
    }

    // MARK: - Main
    var body: some View {
        ZStack(alignment: .top) {

            // MARK: MAP
            Map(position: $cameraPosition) {
                UserAnnotation()
                ForEach(filteredPins) { pin in
                    Annotation(pin.pinName, coordinate: pin.coordinate) {
                        Button {
                            selectedPin = pin
                            ignoreNextCameraChange = true
                            withAnimation(.spring) {
                                cameraPosition = .region(MKCoordinateRegion(
                                    center: pin.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                ))
                            }
                        } label: {
                            Image(systemName: "mappin")
                                .frame(width: 10, height: 20)
                        }
                        .buttonStyle(.glass)
                    }
                }
            }
            .onMapCameraChange(frequency: .onEnd) {
                if ignoreNextCameraChange {
                    ignoreNextCameraChange = false // first fire = our animation, ignore it
                } else {
                    selectedPin = nil // second fire = user panning, dismiss the card
                }
            }
            .mapStyle(.imagery)
            .mapControls { }
            .onAppear { viewModel.fetchPins() }
            
            .sheet(isPresented: $showAddPin) {
                AddPinView(viewModel: viewModel, locationManager: locationManager)
            }
            .sheet(isPresented: $showPinDetail) {
                if let pin = selectedPin {
                    PinInfoView(pin: pin, viewModel: viewModel)
                }
            }

            // MARK: TOP STUFF
            VStack(spacing: 8) {
                searchBar
                searchResults
                categoryChips
            }
            .padding(.top, 5)

            // MARK: SIDE STUFF
            ZStack(alignment: .bottomTrailing) {
                Color.clear
                VStack(spacing: 8) {
                    locationButton
                    addPinButton
                }
                .padding(.trailing)
                .padding(.bottom, selectedPin != nil ? 140 : 40)
            }

            // MARK: PIN CARD
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
                Button { selectedType = nil } label: {
                    Text("All")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .foregroundStyle(selectedType == nil ? .black : .primary)
                        .glassEffect()
                }
                ForEach(SpotType.allCases, id: \.self) { type in
                    Button { selectedType = type } label: {
                        Label(type.rawValue, systemImage: type.icon)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .foregroundStyle(selectedType == type ? .black : .primary)
                            .glassEffect()
                    }
                }
            }
            .padding(.horizontal)
        }
    }
//MARK: - CURRENT LOCATION
    var locationButton: some View {
        Button {
            cameraPosition = .userLocation(fallback: .automatic)
        } label: {
            Image(systemName: "location.fill")
                .foregroundStyle(.black)
                .bold()
                .frame(width: 30, height: 40)
        }
        .buttonStyle(.glass)
    }
//MARK: - ADD NEW PIN
    var addPinButton: some View {
        Button {
            showAddPin = true
        } label: {
            Image(systemName: "plus")
                .foregroundStyle(.black)
                .bold()
                .frame(width: 30, height: 40)
        }
        .buttonStyle(.glass)
    }
}

#Preview {
    MapView()
}
