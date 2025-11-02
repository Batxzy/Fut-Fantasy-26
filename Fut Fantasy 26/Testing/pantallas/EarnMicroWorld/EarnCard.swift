//
//  EarnCard.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 02/11/25.
//

import SwiftUI

struct EarnCard: View {
    // Content
    let title: String
    let question: String
    let points: Int
    let action: () -> Void
    
    // State
    let isEnabled: Bool
    let countdownText: String?
    let isAnswered: Bool
    
    // Colors
    let backgroundColor: Color
    let accentColor: Color
    let backgroundIconColor: Color?
    let foregroundIconMaskColor: Color?
    let earnButtonBackgroundColor: Color?
    let earnButtonTextColor: Color?
    let earnButtonIconColors: (Color, Color)?
    
    // Icons
    let backgroundIcon: AnyView
    let foregroundIcon: AnyView
    let foregroundIconScale: CGFloat
    let foregroundIconRenderingMode: IconRenderingMode
    
    enum IconRenderingMode {
        case masked
        case original
    }
    
    init(
        title: String = "Question of the day",
        question: String,
        points: Int,
        action: @escaping () -> Void = { print("Card tapped") },
        isEnabled: Bool = true,
        countdownText: String? = nil,
        isAnswered: Bool = false,
        backgroundColor: Color = .wpBlueOcean,
        accentColor: Color = .wpMint,
        
        backgroundIconColor: Color? = nil,
        foregroundIconMaskColor: Color? = nil,
        
        earnButtonBackgroundColor: Color? = nil,
        earnButtonTextColor: Color? = nil,
        earnButtonIconColors: (Color, Color)? = nil,
        
        backgroundIcon: AnyView? = nil,
        foregroundIcon: AnyView,
        foregroundIconScale: CGFloat = 0.69,
        foregroundIconRenderingMode: IconRenderingMode = .masked
    ) {
        self.title = title
        self.question = question
        self.points = points
        self.action = action
        self.isEnabled = isEnabled
        self.countdownText = countdownText
        self.isAnswered = isAnswered
        self.backgroundColor = backgroundColor
        self.accentColor = accentColor
        self.backgroundIconColor = backgroundIconColor
        self.foregroundIconMaskColor = foregroundIconMaskColor
        self.earnButtonBackgroundColor = earnButtonBackgroundColor
        self.earnButtonTextColor = earnButtonTextColor
        self.earnButtonIconColors = earnButtonIconColors
        self.backgroundIcon = backgroundIcon ?? AnyView(Icon26())
        self.foregroundIcon = foregroundIcon
        self.foregroundIconScale = foregroundIconScale
        self.foregroundIconRenderingMode = foregroundIconRenderingMode
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack(spacing: 24) {
                ZStack {
                    backgroundIcon
                        .foregroundStyle(backgroundIconColor ?? .wpGreenYellow)
                    
                    Group {
                        switch foregroundIconRenderingMode {
                        case .masked:
                            Rectangle()
                                .fill(foregroundIconMaskColor ?? backgroundColor)
                                .mask(foregroundIcon)
                        case .original:
                            foregroundIcon
                        }
                    }
                    .scaleEffect(foregroundIconScale)
                }
                .frame(width: 77, height: 117)
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .textCase(.uppercase)
                            .font(.system(size: 18))
                            .fontWidth(.compressed)
                            .fontWeight(.heavy)
                            .kerning(1)
                            .foregroundStyle(accentColor)
                        
                        Text(question)
                            .font(.system(size: 16))
                            .fontWidth(.condensed)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .lineLimit(2, reservesSpace: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack() {
                        if let countdown = countdownText {
                            // Show countdown timer
                            Text(countdown)
                                .font(.system(size: 13, weight: .heavy, design: .monospaced))
                                .foregroundColor(accentColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(backgroundColor.opacity(0.3))
                                )
                        } else if isAnswered {
                            // Show completed state
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 13))
                                Text("Completed")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(backgroundColor.opacity(0.3))
                            )
                        } else {
                            EarnButton(
                                points: points,
                                backgroundColor: earnButtonBackgroundColor ?? accentColor,
                                textColor: earnButtonTextColor ?? backgroundColor,
                                iconColors: earnButtonIconColors ?? (accentColor, backgroundColor)
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .padding(13)
        .frame(width: 344, height: 144, alignment: .center)
        .background(backgroundColor)
        .cornerRadius(16)
        .opacity(isEnabled ? 1.0 : 0.6)
        .onTapGesture {
            if isEnabled {
                action()
            }
        }
    }
    
    struct EarnButton: View {
        let points: Int
        let backgroundColor: Color
        let textColor: Color
        let iconColors: (Color, Color)
        
        var body: some View {
            HStack(spacing: 5) {
                Text("+\(points)")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(textColor)
                
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 15))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(iconColors.0, iconColors.1)
            }
            .frame(height: 24)
            .padding(.horizontal, 6)
            .background(
                Capsule()
                    .fill(backgroundColor)
            )
        }
    }
}

// MARK: - Usage Examples

#Preview("Default") {
    EarnCard(
        question: "How many World Cups have been held in Mexico?",
        points: 1000,
        foregroundIcon: AnyView(IconQuestionmark())
    )
}

#Preview("Custom Colors") {
    EarnCard(
        question: "Who won the 2022 World Cup?",
        points: 500,
        backgroundColor: .wpPurpleDeep,
        accentColor: .wpGreenLime,
        foregroundIcon: AnyView(IconQuestionmark())
    )
}

#Preview("Fully Customized") {
    EarnCard(
        title: "Daily Challenge",
        question: "Name the top scorer of the tournament?",
        points: 2000,
        action: { print("Challenge accepted!") },
        backgroundColor: .wpRedBright,
        accentColor: .white,
        backgroundIconColor: .wpMint,
        foregroundIconMaskColor: .white,
        earnButtonBackgroundColor: .white,
        earnButtonTextColor: .wpRedBright,
        earnButtonIconColors: (.wpMint, .wpRedBright),
        backgroundIcon: AnyView(Icon26()),
        foregroundIcon: AnyView(IconQuestionmark()),
        foregroundIconScale: 0.8
    )
}

#Preview("Image with Custom Mask") {
    EarnCard(
        question: "World Cup history!",
        points: 1200,
        backgroundColor: .wpRedBright,
        accentColor: .white,
        foregroundIcon: AnyView(
            Image("Throphy")
                .resizable()
                .aspectRatio(contentMode: .fit)
        ),
        foregroundIconScale: 0.7,
        foregroundIconRenderingMode: .masked
    )
}
