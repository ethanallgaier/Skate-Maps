//
//  LocationManager.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/5/26.
//



import CoreLocation
import Foundation
internal import Combine

//turns on the device GPS, asks for permission, and continuously tracks where the user is.
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D?

    override init() {
        super.init()
        manager.requestWhenInUseAuthorization()
        manager.delegate = self
        manager.startUpdatingLocation()
    }
    
    //fires every time the user's location updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            userLocation = locations.first?.coordinate
        }
}



//ObservableObject + @Published var userLocation — now any view can watch the user's location and react when it updates
