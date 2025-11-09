//
//  LocationDetailSheet.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 05/11/25.
//

import SwiftUI
import MapKit
import Contacts

import SwiftUI
import MapKit
import SwiftData

struct LocationDetailSheet: View {
    let location: CuratedLocation
    let distance: Double
    let isWithinGeofence: Bool
    @Binding var showARView: Bool
    
    @Query private var squads: [Squad]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var remainingTime: TimeInterval?
    @State private var timer: Timer?
    @State private var showRewardAlert = false
    
    private var currentSquad: Squad? {
        squads.first
    }
    
    private var canClaimReward: Bool {
        guard let squad = currentSquad else { return false }
        return squad.canClaimLocationReward(locationId: location.id, cooldownHours: location.cooldownHours)
    }
    
    private var formattedTimeRemaining: String {
        guard let time = remainingTime, time > 0 else { return "" }
        
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        
        return "\(hours)h \(minutes)m remaining"
    }
    
    private var displayRewardPoints: Int {
            Int(location.rewardAmountMillions * 1000) // multiplier
        }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                VStack (spacing: -20){
                    HStack {
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
                                points: displayRewardPoints,
                                textColor: canClaimReward ? location.mainColor : .gray,
                                iconColor: canClaimReward ? location.mainColor : .gray
                            )
                            
                            if canClaimReward {
                                Text("Reward available")
                                    .fontWidth(.condensed)
                                    .font(.system(size: 11))
                                    .fontDesign(.default)
                                    .fontWeight(.medium)
                                    .kerning(0)
                                    .foregroundStyle(.white.opacity(0.65))
                            } else {
                                Text(formattedTimeRemaining)
                                    .fontWidth(.condensed)
                                    .font(.system(size: 11))
                                    .fontDesign(.default)
                                    .fontWeight(.medium)
                                    .kerning(0)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                }
               
                
                Button {
                        if isWithinGeofence, let squad = currentSquad {
                            
                            if canClaimReward {
                                
                                let rewardManager = RewardManager(modelContext: modelContext)
                                rewardManager.tryAwardLocation(location: location, squad: squad)
                                updateRemainingTime()
                            }
                        }
                        
                        dismiss()
                        showARView = true
                    } label: {
                        VStack(spacing: 8) {
                            if isWithinGeofence {
                                Text(canClaimReward ? "Claim & Paste" : "Paste Stickers")
                                    .font(.headline)
                                    .foregroundStyle(.black)
                            } else {
                                Text("Get closer to unlock")
                                    .font(.headline)
                                    .foregroundStyle(.gray)
                                Text("\(max(0, Int(distance - 200)))m away from activation")
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
        .onAppear {
            updateRemainingTime()
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func updateRemainingTime() {
        guard let squad = currentSquad else { return }
        remainingTime = squad.timeUntilNextLocationReward(locationId: location.id, cooldownHours: location.cooldownHours)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            updateRemainingTime()
        }
    }
}

struct EarnPoints: View {
     let points: Int
     let textColor: Color
     let iconColor: Color
     
     var body: some View {
         HStack(spacing: 5) {
             Text("+\(points)M")
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

/*
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
        imageName: "soccerball",
        rewardAmount: 8.0,
        cooldownHours: 24
    )
    
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Squad.self, configurations: config)
    
    return LocationDetailSheet(
        location: mockLocation,
        distance: 35.0,
        isWithinGeofence: true,
        showARView: .constant(false)
    )
    .modelContainer(container)
}
*/
