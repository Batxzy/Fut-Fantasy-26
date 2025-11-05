//
//  ProfileView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 04/11/25.
//

import SwiftUI

struct ProfileView: View {
    
    var body: some View {
        ScrollView(){
            VStack(spacing: 48){
                
                
                VStack(spacing:5){
                    VStack(spacing:0){
                        
                        HStack{
                            Spacer()
                            HStack(spacing: 3) {
                                Image(systemName: "star.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(Color.white)
                                
                                Text("2M")
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                        
                        VStack(spacing: 16){
                            Image("Ellipse 23")
                                .frame(width: 125, height: 125)
                                .background(Color(red: 0.85, green: 0.9, blue: 0.35))
                                .clipShape(Circle())
                            
                            VStack{
                                Text("Deebie Thestta")
                                Text("rising Star")
                            }
                            
                        }
                        
                    }
                    .padding(.horizontal,21)
                    
                    VStack(spacing:14){
                        
                        HStack{
                            Text("badges")
                            
                            Spacer()
                            
                            Text("see all")
                        }
                        
                        HStack(spacing: 8){
                            ForEach(1...3, id: \.self){ i in
                                Image("Ellipse 24")
                                    .resizable()
                                    .frame(width: 116, height: 155)
                                    .background(.wpAqua)
                                    .cornerRadius(4)
                                
                            }
                        }
                        
                    }
                    .padding(.horizontal,21)
                }
                
                
                VStack(alignment: .leading, spacing:14){
                    
                    
                    Text("Achievements")
                    
                    
                    VStack(spacing: 14){
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
                            progress: 0.7,
                            backgroundColor: .wpMagenta,
                            accentColor: .wpGreenLime
                        )
                        
                        AchievementBadge(
                            icon: "medal.fill",
                            title: "Quiz Master",
                            description: "Answer 50 trivia questions correctly",
                            progress: 0.7,
                            backgroundColor: .wpBlueOcean,
                            accentColor: .wpMint
                        )
                    }
                    
                }
                .padding(.horizontal,21)
                
            }
        }
        
    }
}

#Preview {
    ProfileView()
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
