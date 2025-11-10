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
    
    // Updated tuple to include geofence radius (in meters)
    let placeConfigs: [String: (mainColor: Color, accentColor: Color, imageName: String, rewardMillions: Double, cooldownHours: Int, geofenceRadius: Double)] = [
        
        //estadios
        "IBB7581ED75F54DD0": (.wpMint, .wpBlueOcean, "soccerball", 8.0, 24, 200),
        "I7D6783FDABFDF92": (.wpGreen, .wpGreenDeep, "soccerball", 12.0, 48, 300),
        
        //Parque rojo
        "I5C4F66F5C7319C30": (.wpRedBright, .wpGreenLime, "party.popper.fill", 12.0, 48, 250),
        
        //Estadio azteca
        "IC9717FB9601973": (.wpGreenLime, .wpBlueOcean, "soccerball", 12.0, 48, 400),
        
        //Estadio bbva
        "I80022CCB097B4927": (.wpBlue, .white, "soccerball", 12.0, 48, 350),
        
        // La fundidora
        "I6A3EE76AC50CEDD2": (.wpGreenMalachite, .wpGreenDeep, "party.popper.fill", 12.0, 48, 500),
        
        //Angel
        "I643021F2AD95AD53": (.wpMagenta, .wpGreenYellow, "party.popper.fill", 12.0, 48, 150),
        
        //Centro Banamex
        "I525CDD84EACEE4E1": (.wpMint, .wpGreenLime, "dollarsign.bank.building.fill", 12.0, 48, 300),
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
                        cooldownHours: cfg.cooldownHours,
                        geofenceRadius: cfg.geofenceRadius  // Added
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
        guard let distance = distancesToLocations[locationId],
              let location = locations.first(where: { $0.id == locationId }) else {
            return false
        }
        return distance <= location.geofenceRadius  // Use custom radius
    }
}
