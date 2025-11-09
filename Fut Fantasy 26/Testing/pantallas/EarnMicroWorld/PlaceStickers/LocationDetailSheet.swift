//
//  LocationDetailSheet.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 05/11/25.
//

import SwiftUI
import MapKit
import Contacts

struct LocationDetailSheet: View {
    let location: CuratedLocation
    let distance: Double
    let isWithinGeofence: Bool
    @Binding var showARView: Bool
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                VStack (spacing: -20){
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
                    
                    VStack (spacing: 13){
                        HStack(spacing: 12){
                            
                            Image(systemName:location.imageName)
                                .font(.system(size: 26))
                                .foregroundStyle(.black)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(location.mainColor))
                            
                            VStack(alignment:.leading ,spacing: 4) {
                                Text(location.name)
                                    .fontWidth(.condensed)
                                    .font(.system(size: 24))
                                    .fontDesign(.default)
                                    .fontWeight(.medium)
                                    .kerning(0.3)
                                    .foregroundStyle(.white)
                                
                                if let locality = location.mapItem.placemark.locality,
                                   let country = location.mapItem.placemark.country {
                                    Text("\(locality), \(country)")
                                        .fontWidth(.condensed)
                                        .font(.system(size: 14))
                                        .fontDesign(.default)
                                        .fontWeight(.medium)
                                        .kerning(0.3)
                                        .foregroundStyle(.white.opacity(0.65))
                                }
                            }
                        }
                        .frame(alignment: .topLeading)
                        
                        
                        VStack(spacing:2){
                            EarnPoints(
                                points: 8000,
                                textColor: location.mainColor,
                                iconColor: location.mainColor
                            )
                            Text("Reward available")
                                .fontWidth(.condensed)
                                .font(.system(size: 11))
                                .fontDesign(.default)
                                .fontWeight(.medium)
                                .kerning(0)
                                .foregroundStyle(.white.opacity(0.65))
                        }
                    }
                }
               
                
                // Custom AR button
                Button {
                    dismiss()
                    showARView = true
                } label: {
                    VStack(spacing: 8) {
                        if isWithinGeofence {
                                Text("Lets Paste")
                                    .font(.headline)
                                    .foregroundStyle(.black)
                        } else {
                            Text("Get closer to unlock")
                                .font(.headline)
                                .foregroundStyle(.gray)
                            Text("\(Int(distance - 200))m away from activation")
                                .font(.caption)
                                .foregroundStyle(.gray.opacity(0.8))
                        }
                    }
                    .padding(.vertical, 7)
                    .padding(.horizontal, 50)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isWithinGeofence ? location.mainColor : Color.gray.opacity(0.2))
                    )
                }
                .disabled(!isWithinGeofence)
                .padding(.horizontal)
            }
            .padding(.top, 16)
        }
        .presentationDetents([.height(250),.fraction(0.30)])
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.30)))
        .presentationBackground(.mainBg.opacity(0.6 ))
    }
}

struct EarnPoints: View {
     let points: Int
     let textColor: Color
     let iconColor: Color
     
     var body: some View {
         HStack(spacing: 5) {
             Text("+\(points)")
                 .fontWidth(.condensed)
                 .font(.system(size: 28))
                 .fontDesign(.default)
                 .fontWeight(.semibold)
                 .kerning(0.3)
                 .foregroundStyle(textColor)
             
             Image(systemName: "star.circle.fill")
                 .font(.system(size: 24))
                 .foregroundStyle(iconColor)
         }
     }
 }


#Preview {
    let mockCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    
    let addressDictionary: [String: Any] = [
        "City": "San Francisco",
        "Country": "United States"
    ]
    
    let mockPlacemark = MKPlacemark(
        coordinate: mockCoordinate,
        addressDictionary: addressDictionary
    )
    
    let mockMapItem = MKMapItem(placemark: mockPlacemark)
    mockMapItem.name = "Soccer Stadium"
    
    let mockLocation = CuratedLocation(
        id: "preview-id",
        mapItem: mockMapItem,
        mainColor: .wpMint,
        accentColor: .wpBlueOcean,
        imageName: "soccerball"
    )
    
    return LocationDetailSheet(
        location: mockLocation,
        distance: 35.0,
        isWithinGeofence: true,
        showARView: .constant(false)
    )
}
