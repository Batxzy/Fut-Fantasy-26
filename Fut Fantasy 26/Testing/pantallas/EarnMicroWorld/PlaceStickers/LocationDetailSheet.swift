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
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text(location.name)
                .font(.title)
            
            Text("\(Int(distance))m away")
                .foregroundColor(.secondary)
            
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
