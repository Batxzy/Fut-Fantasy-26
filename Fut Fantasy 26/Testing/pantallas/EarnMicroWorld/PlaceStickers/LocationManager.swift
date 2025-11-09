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
    
    let placeConfigs: [String: (mainColor: Color, accentColor: Color, imageName: String, rewardMillions: Double, cooldownHours: Int)] = [
        "IBB7581ED75F54DD0": (.wpMint, .wpBlueOcean, "soccerball", 8.0, 24),
        "I7D6783FDABFDF92": (.wpRedBright, .wpGreenLime, "soccerball", 12.0, 48)
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
        var loaded: [CuratedLocation] = []
        for (placeID, cfg) in placeConfigs {
            guard let identifier = MKMapItem.Identifier(rawValue: placeID) else { continue }
            let request = MKMapItemRequest(mapItemIdentifier: identifier)
            if let mapItem = try? await request.mapItem {
                loaded.append(
                    CuratedLocation(
                        id: placeID,
                        mapItem: mapItem,
                        mainColor: cfg.mainColor,
                        accentColor: cfg.accentColor,
                        imageName: cfg.imageName,
                        rewardAmountMillions: cfg.rewardMillions,
                        cooldownHours: cfg.cooldownHours
                    )
                )
            }
        }
        locations = loaded
        if let loc = userLocation { calculateDistances(from: loc) }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations new: [CLLocation]) {
        guard let last = new.last else { return }
        userLocation = last
        calculateDistances(from: last)
    }
    
    func calculateDistances(from userLocation: CLLocation) {
        for location in locations {
            let locCL = CLLocation(latitude: location.coordinate.latitude,
                                   longitude: location.coordinate.longitude)
            distancesToLocations[location.id] = userLocation.distance(from: locCL)
        }
    }
    
    func isWithinGeofence(locationId: String) -> Bool {
        guard let distance = distancesToLocations[locationId] else { return false }
        return distance <= 200
    }
}
