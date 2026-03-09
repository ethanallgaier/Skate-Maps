//
//  MapViewModel.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/9/26.
//

import FirebaseFirestore
import FirebaseAuth
import CoreLocation
internal import Combine

class MapViewModel: ObservableObject {
    private let dataBase = Firestore.firestore()
    
    @Published var pins: [PinInfo] = []
      
    
// Fetch all pins from Firestore
      func fetchPins() {
          dataBase.collection("pins")
              .order(by: "time", descending: true)
              .addSnapshotListener { snapshot, error in
                  if let error = error {
                      print("Error fetching pins: \(error)")
                      return
                  }
                  self.pins = snapshot?.documents.compactMap {
                      try? $0.data(as: PinInfo.self)
                  } ?? []
              }
      }
    
//Add new pin to Firestore
    func addPin(name: String, details: String, coordinate: CLLocationCoordinate2D, username: String) {
           guard let uid = Auth.auth().currentUser?.uid else { return }
           
           let newPin = PinInfo(
               pinName: name,
               pinDetails: details,
               time: Date(),
               latitude: coordinate.latitude,
               longitude: coordinate.longitude,
               createdByUID: uid,
               createdByUsername: username
           )
           
           do {
               try dataBase.collection("pins").addDocument(from: newPin)
           } catch {
               print("Error saving pin: \(error)")
           }
       }
}

