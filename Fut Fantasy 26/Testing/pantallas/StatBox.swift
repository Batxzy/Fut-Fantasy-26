//
//  StatBox.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 13/10/25.
//


import SwiftUI

struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
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
        StatBox(title: "Total Points", value: "125")
        StatBox(title: "Price", value: "£12.0m")
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
