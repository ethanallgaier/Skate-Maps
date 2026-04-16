//
//  LocationManager.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/5/26.
//

import CoreLocation
import Foundation
internal import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        authorizationStatus = manager.authorizationStatus
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.first?.coordinate
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    /// Returns distance in meters from the user to a given coordinate.
    func distance(to coordinate: CLLocationCoordinate2D) -> Double? {
        guard let userLocation else { return nil }
        let userCL = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let targetCL = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return userCL.distance(from: targetCL)
    }

    var locationDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }
}
