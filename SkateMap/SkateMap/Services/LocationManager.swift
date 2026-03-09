//
//  LocationManager.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/5/26.
//



import CoreLocation
//Asks the user permission for current location
class LocationManager: NSObject {
    let manager = CLLocationManager()

    override init() {
        super.init()
        manager.requestWhenInUseAuthorization()
    }
}
