//
//  DebugBoundingBox.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 28/10/25.
//


import SwiftUI

struct DebugBoundingBox: ViewModifier {
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .strokeBorder(color)
            )
    }
}

extension View {
    @ViewBuilder
    func debugOutline(
        _ color: Color = .red,
        enabled: Bool = true
    ) -> some View {
        if enabled {
            self.modifier(DebugBoundingBox(color: color))
        } else {
            self
        }
    }
}
