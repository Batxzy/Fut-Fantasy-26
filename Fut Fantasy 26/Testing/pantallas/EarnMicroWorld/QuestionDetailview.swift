//
//  QuestionDetailview.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 02/11/25.
//

import SwiftUI

struct QuestionDetailview: View {
    var body: some View {
        VStack(spacing:32){
            
            Text("Question of the day")
                .font(.system(size: 20))
                .fontWeight(.heavy)
                .textCase(.uppercase)
                .fontWidth(.condensed)
                .foregroundColor(.wpMint)
                .kerning(1)
            
            QuestionView()
            
            
                
        }
    }
}

struct QuestionView : View {
    var body: some View {
        HStack{
         Text("How many World Cups have been held in Mexico?")
                .foregroundStyle(.white)
                .font(.system(size: 20))
                .fontWeight(.regular)
                .fontWidth(.compressed)
                .frame(width: 133, height: 96, alignment: .topLeading)
            
            
         Image("VectorArtQuestion")
                .resizable()
                .scaledToFit()
        }
        .foregroundColor(.clear)
        .frame(width: 328, height: 188)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color(.wpMint),
                            Color(.wpRedBright)
                        ],
                        startPoint: UnitPoint(x: 0.55, y: 0.84),
                        endPoint: UnitPoint(x: 0.5, y: -0.05)
                    ),
                    lineWidth: 1
                )
        )
    }
}

enum QuizButtonState {
    case `default`
    case selected
    case correct
    case wrong
}

struct QuizAnswerButton: View {
    let answer: String
    let state: QuizButtonState
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(answer)
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .background(backgroundColor)
                .cornerRadius(16)
        }
        .disabled(state == .correct || state == .wrong)
    }
    
    private var backgroundColor: Color {
        switch state {
        case .default:
            return Color.gray.opacity(0.3)
        case .selected:
            return Color.wpMint // your mint color
        case .correct:
            return Color.wpMint
        case .wrong:
            return Color.red
        }
    }
    
    private var textColor: Color {
        switch state {
        case .default:
            return .gray
        case .selected, .correct, .wrong:
            return .black
        }
    }
}

#Preview {
    QuestionDetailview()
}
