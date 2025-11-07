//
//  WinCard.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 07/11/25.
//


import SwiftUI


// MARK: - Win Card
struct WinCard: View {
    let score: Double
    
    var body: some View {
        VStack(alignment: .center) {
            Text("Perfect!")
                .textCase(.uppercase)
                .fontWidth(.compressed)
                .font(.system(size: 28))
                .fontDesign(.default)
                .fontWeight(.black)
                .kerning(0.6)
                .foregroundStyle(.wpGreenYellow)
            
            Text(String(format: "%.0f%% similarity", score * 100))
                .font(.system(size: 14))
                .fontWidth(.condensed)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            
            HStack {
                Text("+1000")
                    .font(.system(size: 34))
                    .fontWidth(.condensed)
                    .fontWeight(.semibold)
                    .kerning(0.4)
                    .foregroundStyle(.wpGreenYellow)
                
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.wpGreenYellow)
            }
            
            Spacer()
            Button(action: { /* Add save logic */ }) {
                Text("Claim")
                    .font(.system(size: 16))
                    .fontWeight(.medium)
                    .foregroundStyle(.wpBlueOcean)
                    .padding(.horizontal, 53)
                    .padding(.vertical, 3)
                    .background(Color.wpMint)
                    .cornerRadius(15)
            }
        }
        .padding(21)
        .frame(width: 298, height: 175)
        .background(.wpBlueOcean)
        .cornerRadius(16)
    }
}

// MARK: - Almost Card
struct AlmostCard: View {
    let score: Double
    let restartAction: () -> Void
    
    var body: some View {
        VStack(alignment: .center) {
            Text("Almost!")
                .textCase(.uppercase)
                .fontWidth(.compressed)
                .font(.system(size: 28))
                .fontDesign(.default)
                .fontWeight(.black)
                .kerning(0.6)
                .foregroundStyle(.wpGreenYellow)
            
            Text(String(format: "%.0f%% similarity, try again!", score * 100))
                .font(.system(size: 14))
                .fontWidth(.condensed)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            
            Spacer()
            
            Button(action: restartAction) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 24))
                    .foregroundStyle(.wpBlueOcean)
                    .padding(20)
                    .background(Color.wpMint)
                    .clipShape(Circle())
            }
        }
        .padding(21)
        .frame(width: 298, height: 175)
        .background(.wpBlueOcean)
        .cornerRadius(16)
    }
}
