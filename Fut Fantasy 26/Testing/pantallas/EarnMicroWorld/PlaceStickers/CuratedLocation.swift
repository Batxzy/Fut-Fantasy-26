//
//  CuratedLocation.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 05/11/25.
//

import SwiftUI
import MapKit


struct CuratedLocation: Identifiable, Equatable {
    let id: String
    let mapItem: MKMapItem
    
    var name: String { mapItem.name ?? "Unknown Location" }
    var coordinate: CLLocationCoordinate2D { mapItem.placemark.coordinate }
    
    static func == (lhs: CuratedLocation, rhs: CuratedLocation) -> Bool {
        lhs.id == rhs.id
    }
}
