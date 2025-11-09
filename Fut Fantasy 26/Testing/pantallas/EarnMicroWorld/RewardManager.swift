//
//  RewardManager.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 09/11/25.
//


import Foundation
import SwiftData

@Observable
@MainActor
class RewardManager {
    private let modelContext: ModelContext
    
    static let poseRewardMillions: Double = 1.0
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func awardPoseIfEligible(score: Double, to squad: Squad) {
        
        guard score >= 0.8 else { return }
        
        squad.addCurrencyMillions(Self.poseRewardMillions)
        
        persist("Pose reward +\(Int(Self.poseRewardMillions * 1000)) points")
        
    }
    
    func tryAwardLocation(location: CuratedLocation, squad: Squad) {
        
        if squad.canClaimLocationReward(locationId: location.id, cooldownHours: location.cooldownHours) {
            
            squad.claimLocationReward(locationId: location.id,
                                      amountMillions: location.rewardAmountMillions,
                                      cooldownHours: location.cooldownHours)
            
            persist("Location \(location.id) reward +\(Int(location.rewardAmountMillions * 1000)) points")
            
        } else {
            print("⏱️ Reward on cooldown for \(location.id)")
        }
    }
    
    private func persist(_ logMessage: String) {
        do {
            try modelContext.save()
            print("✅ Saved reward change: \(logMessage)")
        } catch {
            print("❌ Failed saving reward: \(error)")
        }
    }
}
