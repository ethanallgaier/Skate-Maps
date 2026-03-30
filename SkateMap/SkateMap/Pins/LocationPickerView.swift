import SwiftUI
import MapKit

struct LocationPickerView: View {
    @Binding var coordinate: CLLocationCoordinate2D?
    var initialRegion: MKCoordinateRegion

    @State private var cameraPosition: MapCameraPosition
    @State private var pickedCoordinate: CLLocationCoordinate2D
    @Environment(\.dismiss) var dismiss

    init(coordinate: Binding<CLLocationCoordinate2D?>, initialRegion: MKCoordinateRegion) {
        self._coordinate = coordinate
        self.initialRegion = initialRegion
        _cameraPosition = State(initialValue: .region(initialRegion))
        _pickedCoordinate = State(initialValue: initialRegion.center)
    }

    var body: some View {
        ZStack {
            // MARK: - Map
            Map(position: $cameraPosition)
                .mapStyle(.hybrid(pointsOfInterest: .excludingAll))
                .mapControls { }
                .onMapCameraChange { context in
                    pickedCoordinate = context.region.center
                }

            // MARK: - Pin Overlay
            MapViewModel.CircularTextPin()
                .allowsHitTesting(false)
                .offset(y: -20)

            // MARK: - UI Overlay
            VStack {
                // Top bar with cancel
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
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

                // Bottom controls
                HStack(alignment: .bottom) {
                    Spacer()

                    // Current location button
                    Button {
                        cameraPosition = .userLocation(fallback: .automatic)
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                // Confirm button
                Button {
                    coordinate = pickedCoordinate
                    dismiss()
                } label: {
                    Text("Confirm Location")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue, in: Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .ignoresSafeArea()
    }
}
