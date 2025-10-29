//
//  PitchComponents.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 28/10/25.
//

import SwiftUI
    
     var pitchBackground: some View {
        ZStack {
            
            hardStripes
            pitchLines
            cornerCircles
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        
    }
    
     var pitchLines: some View {
        VStack(spacing: 0) {
            Rectangle()
                .stroke(.white.opacity(0.8), lineWidth: 2)
                .frame(height: 50)
                .padding(.horizontal, 60)
                .padding(.top, 10)
            
            Spacer()
            
            Circle()
                .stroke(.white.opacity(0.8), lineWidth: 2)
                .frame(width: 80, height: 80)
            
            Rectangle()
                .fill(.white.opacity(0.8))
                .frame(height: 2)
                .offset(y: -40)
            
            Spacer()
            
            Rectangle()
                .stroke(.white.opacity(0.8), lineWidth: 2)
                .frame(height: 50)
                .padding(.horizontal, 60)
                .padding(.bottom, 10)
        }
    }
    
     var cornerCircles: some View {
        VStack {
            HStack {
                cornerArc
                Spacer()
                cornerArc.rotation3DEffect(.degrees(90), axis: (x: 0, y: 1, z: 0))
            }
            Spacer()
            HStack {
                cornerArc.rotation3DEffect(.degrees(-90), axis: (x: 1, y: 0, z: 0))
                Spacer()
                cornerArc.rotation3DEffect(.degrees(180), axis: (x: 1, y: 1, z: 0))
            }
        }
    }
    
     var cornerArc: some View {
        Circle()
            .trim(from: 0, to: 0.25)
            .stroke(.white.opacity(0.8 ), lineWidth: 2)
            .frame(width: 30, height: 30)
    }
    
     var emptyPitchState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sportscourt")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.3))
            
            Text("No Starting XI Selected")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))
            
            Text("Add 11 players to your squad and set your starting lineup")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
     var hardStripes: some View {
        VStack(spacing: 0) {
            ForEach(0..<24) { i in
                Rectangle()
                    .fill(i % 2 == 0 ? Color.pitchGreenDark : Color.pitchGreen)
            }
        }
    }
