//
//  ProfileView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 04/11/25.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query(FetchDescriptor<Squad>()) private var squads: [Squad]
    
    var currentSquad: Squad? {
        squads.first
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.mainBg)
                    .ignoresSafeArea()
                
                ScrollView {
                    ZStack(alignment: .top) {
                        GeometryReader { geometry in
                            let minY = geometry.frame(in: .global).minY
                            let scale = max(1.0, 1.0 + (minY / 500))
                            
                            Image("Vector")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width)
                                .scaleEffect(scale)
                                .offset(y: -minY - 1)
                        }
                        .frame(height: 180)
                        
                        GeometryReader { geometry in
                            VStack(spacing: 0) {
                                LinearGradient(
                                    stops: [
                                        Gradient.Stop(color: .mainBg.opacity(0), location: 0.00),
                                        Gradient.Stop(color: .mainBg, location: 1.00),
                                    ],
                                    startPoint: UnitPoint(x: 0.5, y: 0),
                                    endPoint: UnitPoint(x: 0.5, y: 1)
                                )
                                .frame(height: 180)
                                
                                Color.mainBg
                            }
                        }
                        .allowsHitTesting(false)
                        
                        // Content
                        VStack(spacing: 32) {
                            Color.clear.frame(height: 40)
                            
                            profileHeader
                            
                            badgesSection
                            
                            achievementsSection
                        }
                        .padding(.horizontal, 21)
                    }
                }
                .edgesIgnoringSafeArea(.top)
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                if let squad = currentSquad {
                    HStack(spacing: 3) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.white)
                        
                        Text(squad.displayBudgetNoDecimals)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(.horizontal, 21)
            .offset(y: 20)
            
            // Profile picture
            Image("Ellipse 23")
                .resizable()
                .frame(width: 125, height: 125)
                .background(Color(red: 0.85, green: 0.9, blue: 0.35))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 3)
                )
            
            // User info
            VStack(spacing: 4) {
                Text("Deebie Thestta")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text("Rising Star")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
    
    private var badgesSection: some View {
        // A list of your badge images
        let badgeImages = ["Throphy", "LaCabra", "PinPoint", "VectorArtQuestion"]
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Badges")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                // Changed to NavigationLink
                NavigationLink(destination: BadgeGalleryView()) {
                    Text("See all")
                        .font(.system(size: 14))
                        .foregroundStyle(.wpMint)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Looping over the actual images
                    ForEach(badgeImages, id: \.self) { imageName in
                        Image(imageName)
                            .resizable()
                            .padding()
                            .scaledToFit()
                            .frame(width: 116, height: 155)
                            .background(.wpAqua.opacity(0.2))
                            .cornerRadius(12)
                            .clipped()
                    }
                }
            }
        }
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Achievements")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
            
            VStack(spacing: 14) {
                AchievementBadge(
                    icon: "party.popper.fill",
                    title: "Celebration expert",
                    description: "Complete 20 celebration pose challenges",
                    progress: 0.7,
                    backgroundColor: .wpPurpleDeep,
                    accentColor: .wpGreenYellow
                )
                
                AchievementBadge(
                    icon: "questionmark.square.fill",
                    title: "Quiz Master",
                    description: "Answer 50 trivia questions correctly",
                    progress: 0.34,
                    backgroundColor: .wpMagenta,
                    accentColor: .wpGreenLime
                )
                
                AchievementBadge(
                    icon: "medal.fill",
                    title: "Point Champion",
                    description: "Earn 10,000 points in a season",
                    progress: 0.88,
                    backgroundColor: .wpBlueOcean,
                    accentColor: .wpMint
                )
            }
        }
        .padding(.bottom, 32)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Squad.self, Player.self,
        configurations: config
    )
    
    let context = container.mainContext
    
    let squad = Squad(teamName: "Preview Team", ownerName: "Preview")
    context.insert(squad)
    
    try? context.save()
    
    return ProfileView()
        .modelContainer(container)
}


#Preview{
    AchievementBadge(
                icon: "party.popper.fill",
                title: "Celebration expert",
                description: "Complete 20 celebration pose challenges",
                progress: 0.7,
                backgroundColor: .wpPurpleDeep,
                accentColor: .wpGreenYellow
            )
}

struct AchievementBadge: View {
    // Parameters
    let icon: String
    let title: String
    let description: String
    let progress: Double
    let backgroundColor: Color
    let accentColor: Color
    var progressPercentage: String {
        "\(Int(progress * 100))%"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Header
            
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(accentColor)
            
            // Body
            VStack(alignment: .leading, spacing: 6) {
                
                VStack(alignment: .leading){
                    Text(title)
                        .font(.system(size: 15, weight: .black))
                        .textCase(.uppercase)
                        .fontWidth(.condensed)
                        .kerning(1)
                        .foregroundStyle(accentColor)
                    
                    Text(description)
                        .font(.system(size: 14, weight:.medium ))
                        .fontWidth(.compressed)
                        .kerning(1)
                        .foregroundStyle(.white)
                }
                
                
                HStack(spacing: 2) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 4)
                            
                            Capsule()
                                .fill(accentColor)
                                .frame(width: geometry.size.width * progress, height: 4)
                        }
                    }
                    .frame(height: 4)
                    
                    Text(progressPercentage)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, alignment: .trailing)
                }
            }
           
           
        }
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .background(backgroundColor)
        .cornerRadius(20)
        
    }
}
