//
//  ScoresView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 01/11/25.
//

import SwiftUI

struct ScoresView: View {
    @State private var selectedTab: Tab = .matches
    
    enum Tab: String, CaseIterable {
        case matches = "Matches"
        case standings = "Standings"
    }
    
    var body: some View {
        VStack {
            
            Picker("View", selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            
            switch selectedTab {
            case .matches:
               Text("hello")
            case .standings:
                StandingsView()
            }
        }
        .frame(alignment: .top)
    }
}


#Preview {
    ScoresView()
}
