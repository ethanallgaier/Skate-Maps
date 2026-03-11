//
//  PinInfoView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/2/26.
//

import SwiftUI

struct PinInfoView: View {
    
    var pin: PinInfo
    
    var body: some View {
        Text(pin.pinName)
        Text(pin.pinDetails)
    }
}

//#Preview {
//    PinInfoView()
//}
