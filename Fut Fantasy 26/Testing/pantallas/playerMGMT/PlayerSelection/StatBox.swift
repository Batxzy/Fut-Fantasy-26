//
//  StatBox.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 13/10/25.
//


import SwiftUI

struct StatRow: View {
    let label: String
    let value: String
    var color: Color = .white 
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(color)
        }
        .padding()
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding()
    }
}

// MARK: - Previews
#Preview("StatBox") {
    VStack {
        StatRow(label: "Total Points", value: "125", color: .wpred)
        StatRow(label: "Price", value: "£12.0m", color: .wpAqua)
    }
    .padding()
}

#Preview("InfoRow") {
    List {
        InfoRow(label: "Full Name", value: "Lionel Messi")
        InfoRow(label: "Shirt Number", value: "#10")
        InfoRow(label: "Group", value: "Group C")
    }
}
