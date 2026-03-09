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
    
    var body: some View {
        Map(position: $cameraPosition) {
            
            UserAnnotation()
           
            ForEach(viewModel.pins) { pin in
                Annotation(pin.pinName, coordinate: pin.coordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(Color.red)
                        .font(.largeTitle)
                }
            }
        }
        .mapStyle(.imagery)
//Map buttons
        .mapControls {
            MapUserLocationButton()//current location
            MapScaleView()//idk
        }
        .onAppear {
            viewModel.fetchPins()
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                //Sheet to add pin
            } label: {
                Image(systemName: "plus")
                    .font(.title)
                    
                    
            }
            .padding()
            .buttonStyle(.glass)
        }

       
    }
}



#Preview {
    MapView()
}
