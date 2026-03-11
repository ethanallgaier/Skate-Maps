//
//  MapView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/2/26.
//

import SwiftUI
import MapKit

struct MapView: View {
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)//preset if no current location
    @State private var locationManager = LocationManager()
    @StateObject var viewModel = MapViewModel()        //What is StateObject?
    @State private var showAddPin = false
    @State private var showPinDetail = false
    @State private var selectedPin: PinInfo?
    
    var body: some View {
        Map(position: $cameraPosition) {
            
            UserAnnotation()//user position
            
            ForEach(viewModel.pins) { pin in
                Annotation(pin.pinName, coordinate: pin.coordinate) {
                    Button {
                        showPinDetail = true
                        selectedPin = pin
                    } label: {
                        Image(systemName: "mappin")
                            .frame(width: 10, height: 20)
                    }
                    .buttonStyle(.glass)
                }
            }
        }
        .mapStyle(.hybrid)
      
        .mapControls {
            MapUserLocationButton()// Tap for current location
        }
        //new pin button
        .overlay(alignment: .topTrailing) {
            Button {
                showAddPin = true
            } label: {
                Image(systemName: "plus")
                    .foregroundStyle(.blue)
                    .frame(width: 20, height: 30)
                    .bold(true)
            }
            .padding(.top, 60)
            .padding()
            .buttonStyle(.glass)
        }
        //show all pins
        .onAppear {
            viewModel.fetchPins()
        }
        //new pin
        .sheet(isPresented: $showAddPin) {
            AddPinView(viewModel: viewModel, locationManager: locationManager)
        }
        //pin details
        .sheet(item: $selectedPin) { pin in
            PinInfoView(pin: pin)
        }
        
    }
}



#Preview {
    MapView()
}
