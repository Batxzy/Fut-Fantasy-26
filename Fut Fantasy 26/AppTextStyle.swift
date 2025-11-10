//
//  AppTextStyle.swift
//  Test-01
//
//  Created by Erick on 09/11/25.
//

import SwiftUI

enum AppTextStyle {
    case h1
    case body
    case caption
}

extension Text {
    func textStyle(_ style: AppTextStyle, weight: Font.Weight? = nil) -> some View {
        switch style {
        case .h1:
            return self
                .fontWidth(.condensed)
                .font(.system(size: 28))
                .fontDesign(.default)
                .fontWeight(weight ?? .medium)
                .kerning(1.2)
            
        case .body:
            return self
                .font(.system(size: 20))
                .fontWidth(.condensed)
                .fontWeight(weight ?? .medium)
            
        case .caption:
            return self
                .font(.system(size: 15, weight: weight ?? .regular))
                .fontWidth(.condensed)
        }
    }
}
