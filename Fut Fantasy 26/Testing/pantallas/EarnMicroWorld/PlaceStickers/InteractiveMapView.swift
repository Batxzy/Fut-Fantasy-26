//
//  InteractiveMapView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 05/11/25.
//

import SwiftUI
import MapKit

struct InteractiveMapView: View {
    @State private var locationManager = LocationManager()
    let manager = CLLocationManager()
    @State private var selectedLocation: CuratedLocation?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var sheetID = UUID()  // Add this
    
    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition) {
                ForEach(locationManager.locations) { location in
                    Annotation(location.name, coordinate: location.coordinate) {
                        Image(systemName: "soccerball")
                            .font(.callout)
                            .foregroundStyle(.black, .white)
                            .padding(5)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.wpMint)
                            )
                            .onTapGesture {
                                selectedLocation = nil
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    sheetID = UUID()
                                    selectedLocation = location
                                }
                            }
                    }
                    .tag(location.id)
                }
                
                if locationManager.userLocation != nil {
                    UserAnnotation()
                }
            }
            .mapStyle(.standard(elevation: .realistic, emphasis: .muted, pointsOfInterest: .excludingAll, showsTraffic: false))
            .toolbar(.hidden, for: .tabBar)
            .task {
                await locationManager.loadPlaces()
                locationManager.startTracking()
            }
            .sheet(item: $selectedLocation) { location in
                LocationDetailSheet(
                    location: location,
                    distance: locationManager.distancesToLocations[location.id] ?? 0,
                    isWithinGeofence: locationManager.isWithinGeofence(locationId: location.id)
                )
                .id(sheetID) 
            }
            .onAppear() {
                locationManager.startTracking()
                manager.requestAlwaysAuthorization()
            }
        }
    }
}



#Preview{
    InteractiveMapView()
}
