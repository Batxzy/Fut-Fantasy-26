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
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var sheetID = UUID()
    @State private var showARView = false
    
    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition) {
                ForEach(locationManager.locations) { location in
                    Annotation(location.name, coordinate: location.coordinate) {
                        Image(systemName: location.imageName )
                            .font(.system(size: 24))
                            .foregroundStyle(.black, .white)
                            .padding(5)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(location.mainColor)
                            )
                            .onTapGesture {
                                selectedLocation = nil
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    sheetID = UUID()
                                    selectedLocation = location
                                }
                                
                                withAnimation(.easeInOut(duration: 1.0)) {
                                    cameraPosition = .camera(
                                        MapCamera(
                                            centerCoordinate: location.coordinate,
                                            distance: 1000,
                                            heading: 0,
                                            pitch: 45
                                        )
                                    )
                                }
                            }
                    }
                    .tag(location.id)

                    MapCircle(center: location.coordinate, radius: 200)
                        .foregroundStyle(location.mainColor.opacity(0.15))
                        .stroke(location.mainColor, lineWidth: 4)
                }
                
                if locationManager.userLocation != nil {
                    UserAnnotation()
                }
            }
            .mapStyle(.standard(elevation: .realistic, emphasis: .automatic, pointsOfInterest: .excludingAll, showsTraffic: false))
            .toolbar(.hidden, for: .tabBar)
            .task {
                await locationManager.loadPlaces()
                locationManager.startTracking()
            }
            .sheet(item: $selectedLocation) { location in
                LocationDetailSheet(
                    location: location,
                    distance: locationManager.distancesToLocations[location.id] ?? 0,
                    isWithinGeofence: locationManager.isWithinGeofence(locationId: location.id),
                    showARView: $showARView
                )
                .id(sheetID)
            }
            .fullScreenCover(isPresented: $showARView) {
                NavigationStack {
                    StickerPlacementARView()
                }
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
