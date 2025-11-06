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
        VStack(spacing: 16) {
            HStack {
                // Circular Apple Maps button
                Button {
                    location.mapItem.openInMaps()
                } label: {
                    Image(systemName: "map.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }
                .glassEffect(.regular.interactive())
                Spacer()
                
                // Location details (center)
                VStack(spacing: 4) {
                    Text(location.name)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    if let locality = location.mapItem.placemark.locality,
                       let country = location.mapItem.placemark.country {
                        Text("\(locality), \(country)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Dismiss button
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }
                .glassEffect(.regular.interactive())
            }
            .padding(.horizontal)
            
            EarnButton(
                points: 8000,
                backgroundColor: location.mainColor,
                textColor: location.accentColor,
                iconColors: (location.mainColor, location.accentColor)
            )
            
            // Custom AR button
            Button {
                dismiss()
                showARView = true
            } label: {
                VStack(spacing: 8) {
                    if isWithinGeofence {
                        HStack {
                            Image(systemName: "document.fill")
                                .foregroundStyle(location.accentColor)
                            
                            Text("Lets Paste")
                                .font(.headline)
                                .foregroundStyle(location.accentColor)
                        }
                    } else {
                        Text("Get closer to unlock")
                            .font(.headline)
                            .foregroundStyle(.gray)
                        Text("\(Int(distance - 200))m away from activation")
                            .font(.caption)
                            .foregroundStyle(.gray.opacity(0.8))
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isWithinGeofence ? location.mainColor : Color.gray.opacity(0.2))
                )
            }
            .disabled(!isWithinGeofence)
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top,16)
        .padding(.vertical)
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
    let mockLocation = CuratedLocation(
        id: "preview-id",
        mapItem: mockMapItem,
        mainColor: .wpMint,
        accentColor: .wpBlueOcean
    )
    
    return LocationDetailSheet(
        location: mockLocation,
        distance: 35.0,
        isWithinGeofence: true,
        showARView: .constant(false)
    )
}
