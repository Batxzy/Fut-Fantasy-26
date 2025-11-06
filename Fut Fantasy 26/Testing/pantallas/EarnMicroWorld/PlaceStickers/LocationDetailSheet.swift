//
//  LocationDetailSheet.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 05/11/25.
//

import SwiftUI
import MapKit

struct LocationDetailSheet: View {
    let location: CuratedLocation
    let distance: Double
    let isWithinGeofence: Bool
    @Binding var showARView: Bool
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text(location.name)
                .font(.title)
            
            Text("\(Int(distance))m away")
                .foregroundColor(.secondary)
            
            Button("View in AR") {
                dismiss()
                showARView = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isWithinGeofence)
            
            Button("Open in Apple Maps") {
                location.mapItem.openInMaps()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .presentationDetents([.fraction(0.3), .medium])
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
    }
}

#Preview {
    let mockCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    let mockPlacemark = MKPlacemark(coordinate: mockCoordinate)
    let mockMapItem = MKMapItem(placemark: mockPlacemark)
    mockMapItem.name = "Soccer Stadium"
    let mockLocation = CuratedLocation(id: "preview-id", mapItem: mockMapItem)
    
    return LocationDetailSheet(
        location: mockLocation,
        distance: 35.0,
        isWithinGeofence: true,
        showARView: .constant(false)
    )
}
