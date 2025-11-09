//
//  LocationManager.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 05/11/25.
//


import CoreLocation
import MapKit
import SwiftUI

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var userLocation: CLLocation?
    var locations: [CuratedLocation] = []
    var distancesToLocations: [String: Double] = [:]
    
    let placeConfigs: [String: (mainColor: Color, accentColor: Color, imageName: String)] = [
        "IBB7581ED75F54DD0": (.wpMint, .wpBlueOcean, "soccerball"),
        "I7D6783FDABFDF92": (.wpRedBright, .wpGreenLime, "soccerball")
    ]
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
    }
    
    func startTracking() {
        manager.startUpdatingLocation()
    }
    
    func loadPlaces() async {
        var loadedLocations: [CuratedLocation] = []
        
        for (placeID, config) in placeConfigs {
            guard let identifier = MKMapItem.Identifier(rawValue: placeID) else {
                continue
            }
            let request = MKMapItemRequest(mapItemIdentifier: identifier)
            if let mapItem = try? await request.mapItem {
                loadedLocations.append(
                    CuratedLocation(
                        id: placeID,
                        mapItem: mapItem,
                        mainColor: config.mainColor,
                        accentColor: config.accentColor,
                        imageName: config.imageName
                )
                    )
            }
        }
        
        locations = loadedLocations
        
        if let userLocation {
            calculateDistances(from: userLocation)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location
        calculateDistances(from: location)
    }
    
    func calculateDistances(from userLocation: CLLocation) {
        for location in locations {
            let locationCL = CLLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            distancesToLocations[location.id] = userLocation.distance(from: locationCL)
        }
    }
    
    func isWithinGeofence(locationId: String) -> Bool {
        guard let distance = distancesToLocations[locationId] else { return false }
        return distance <= 200
    }
}
