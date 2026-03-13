import SwiftUI
import MapKit

struct MapView: View {

    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var locationManager = LocationManager()
    @StateObject var viewModel = MapViewModel()
    @State private var selectedPin: PinInfo?
    @State private var showAddPin = false
    @State private var selectedType: SpotType? = nil
    @State private var searchText: String = ""

    var filteredPins: [PinInfo] {
        guard let selectedType else { return viewModel.pins }
        return viewModel.pins.filter { $0.spotType == selectedType }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition) {
                
                // MARK: - USERS CURRENT LOCATION CIRCLE
                UserAnnotation()
                
                //MARK: - USER PINS
                ForEach(filteredPins) { pin in
                    Annotation(pin.pinName, coordinate: pin.coordinate) {
                        Button {
                            selectedPin = pin
                        } label: {
                            Image(systemName: "mappin")
                                .frame(width: 10, height: 20)
                        }
                        .buttonStyle(.glass)
                    }
                }
            }
            .mapStyle(.imagery)
            .onAppear { viewModel.fetchPins() }
            .sheet(isPresented: $showAddPin) {
                AddPinView(viewModel: viewModel, locationManager: locationManager)
            }
            .sheet(item: $selectedPin) { pin in
                PinInfoView(pin: pin, viewModel: viewModel)
            }

            VStack(spacing: 8) {
                
                //MARK: -  SEARCH BAR
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
                
                //MARK: - SEARCH RESULTS
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
                
           
                
                // MARK: - CHOOSE SPOT TYPE
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button {
                            selectedType = nil
                        } label: {
                            Text("All")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .foregroundStyle(selectedType == nil ? .red : .primary)
                                .glassEffect()
                        }
                        
                        ForEach(SpotType.allCases, id: \.self) { type in
                            Button {
                                selectedType = type
                            } label: {
                                Label(type.rawValue, systemImage: type.icon)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .foregroundStyle(selectedType == type ? .red : .primary)
                                    .glassEffect()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                Spacer()
                //MARK: - USER BOTTONS
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Button {
                            cameraPosition = .userLocation(fallback: .automatic)
                        } label: {
                            Image(systemName: "location.fill")
                                .foregroundStyle(.red)
                                .bold()
                                .frame(width: 30, height: 40)
                        }
                        .buttonStyle(.glass)

                        Button {
                            showAddPin = true
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(.red)
                                .bold()
                                .frame(width: 30, height: 40)
                        }
                        .buttonStyle(.glass)
                        Spacer()
                    }
                    .padding(.trailing)
                }
            }
        }
    }
}

#Preview {
    MapView()
}
