//
//  CollectibleManager.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 06/11/25.
//

import Foundation
import SwiftData
import SwiftUI
import Observation

@Observable
@MainActor
class CollectibleManager {
    private let modelContext: ModelContext
    
    var selectedCollectibleForDetail: Collectible?
    
    private let predefinedBadges = [
            (name: "World Cup Winner", imageName: "Group 200"),
            (name: "The G.O.A.T.", imageName: "Group 190"),
            (name: "On The Spot", imageName: "Group 196"),
            (name: "Quiz Master", imageName: "Group 184"),
            (name: "Clean Sheet King", imageName: "Group 197"),
            (name: "Hat-Trick Hero", imageName: "Group 205"),
            (name: "Assist Machine", imageName: "Group 188"),
            (name: "The Wall", imageName: "Group 157"),
            (name: "Midfield General", imageName: "Group 156"),
            (name: "Forward Finisher", imageName: "Group 155"),
            (name: "Defender's Will", imageName: "Group 154"),
            (name: "The Captain", imageName: "Group 152"),
            (name: "The Vice", imageName: "Group 151"),
            (name: "Golden Boot", imageName: "Group 147"),
            (name: "Golden Glove", imageName: "Group 146"),
            (name: "Group Master", imageName: "Group 145"),
            (name: "Matchday Winner", imageName: "Group 149"),
            (name: "Budget Master", imageName: "Group 148"),
            (name: "Transfer Genius", imageName: "Group 144"),
            (name: "First Blood", imageName: "Group 115"),
            (name: "Unbreakable", imageName: "Group 143"),
            (name: "Rising Star", imageName: "Group 114")
        ]
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func saveSticker(image: UIImage, squad: Squad) throws {
        guard let data = image.pngData() else {
            throw NSError(domain: "ImageConversionError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to PNG data."])
        }
        
        let newSticker = Collectible(
            type: .sticker,
            name: "User Sticker \(Date().timeIntervalSince1970)",
            stickerData: data
        )
        
        newSticker.squad = squad
        modelContext.insert(newSticker)
        
        try modelContext.save()
        print("✅ Sticker saved successfully!")
    }
    
    func seedInitialBadges(for squad: Squad) throws {
        // Fetch all collectibles for this squad
        let descriptor = FetchDescriptor<Collectible>()
        let allCollectibles = try modelContext.fetch(descriptor)
        
        // Filter in-memory for badges belonging to this squad
        let existingBadges = allCollectibles.filter {
            $0.type == .badge && $0.squad?.id == squad.id
        }
        
        guard existingBadges.isEmpty else {
            print("ℹ️ Badges already seeded.")
            return
        }
        
        print("🌱 Seeding initial badges...")
        
        for badgeInfo in predefinedBadges {
            let badge = Collectible(
                type: .badge,
                name: badgeInfo.name,
                imageName: badgeInfo.imageName
            )
            badge.squad = squad
            modelContext.insert(badge)
        }
        
        try modelContext.save()
        print("✅ Initial badges seeded successfully.")
    }
    
    
    private static func badges(for squadID: UUID) -> Predicate<Collectible> {
        return #Predicate<Collectible> {
            $0.type.rawValue == "badge" && $0.squad?.id == squadID
        }
    }
}
