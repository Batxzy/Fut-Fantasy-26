//
//  QuestionAnswerView.swift
//  Fut Fantasy 26
//
//  Created by GitHub Copilot on 02/11/25.
//

import SwiftUI

struct QuestionAnswerView: View {
    let question: Question
    @Binding var userAnswer: String
    let onSubmit: () -> Void
    let isLoading: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Question Text
            Text(question.text)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
            
            // Answer Input based on question type
            switch question.questionType {
            case .multipleChoice:
                multipleChoiceOptions
            case .trueFalse:
                trueFalseOptions
            case .textInput:
                textInputField
            }
            
            // Submit Button
            Button(action: onSubmit) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Submit Answer")
                            .font(.system(size: 18, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(userAnswer.isEmpty ? Color.gray : Color.wpGreenLime)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(userAnswer.isEmpty || isLoading)
            .padding(.horizontal)
        }
        .padding()
        .background(Color.wpBlueOcean.opacity(0.9))
        .cornerRadius(20)
        .padding()
    }
    
    // MARK: - Question Type Views
    
    private var multipleChoiceOptions: some View {
        VStack(spacing: 12) {
            if let options = question.options {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        userAnswer = option
                    }) {
                        HStack {
                            Text(option)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                            Spacer()
                            if userAnswer == option {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.wpGreenLime)
                            }
                        }
                        .padding()
                        .background(userAnswer == option ? Color.wpGreenLime.opacity(0.3) : Color.white.opacity(0.2))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var trueFalseOptions: some View {
        HStack(spacing: 20) {
            Button(action: {
                userAnswer = "True"
            }) {
                Text("True")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(userAnswer == "True" ? Color.wpGreenLime : Color.white.opacity(0.2))
                    .cornerRadius(10)
            }
            
            Button(action: {
                userAnswer = "False"
            }) {
                Text("False")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(userAnswer == "False" ? Color.wpGreenLime : Color.white.opacity(0.2))
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }
    
    private var textInputField: some View {
        TextField("Enter your answer", text: $userAnswer)
            .textFieldStyle(PlainTextFieldStyle())
            .font(.system(size: 16))
            .foregroundColor(.white)
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(10)
            .padding(.horizontal)
    }
}

// MARK: - Result View

struct QuestionResultView: View {
    let isCorrect: Bool
    let pointsEarned: Int
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(isCorrect ? .wpGreenLime : .wpRedBright)
            
            // Result Text
            Text(isCorrect ? "Correct!" : "Incorrect")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            // Points Earned (if correct)
            if isCorrect {
                HStack(spacing: 8) {
                    Text("+\(pointsEarned)")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(.wpGreenLime)
                    
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.wpGreenLime)
                }
                
                Text("Added to your budget!")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
            } else {
                Text("Better luck tomorrow!")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Dismiss Button
            Button(action: onDismiss) {
                Text("Continue")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.wpBlueOcean)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
        .padding()
    }
}

#Preview("Multiple Choice") {
    QuestionAnswerView(
        question: Question(
            text: "How many World Cups have been held in Mexico?",
            correctAnswer: "2",
            basePoints: 1000,
            category: .history,
            difficulty: .easy,
            questionType: .multipleChoice,
            options: ["1", "2", "3", "4"]
        ),
        userAnswer: .constant(""),
        onSubmit: {},
        isLoading: false
    )
}

#Preview("True/False") {
    QuestionAnswerView(
        question: Question(
            text: "Brazil has won the World Cup 5 times.",
            correctAnswer: "True",
            basePoints: 500,
            category: .trivia,
            difficulty: .easy,
            questionType: .trueFalse
        ),
        userAnswer: .constant(""),
        onSubmit: {},
        isLoading: false
    )
}

#Preview("Result - Correct") {
    QuestionResultView(
        isCorrect: true,
        pointsEarned: 1000,
        onDismiss: {}
    )
}

#Preview("Result - Incorrect") {
    QuestionResultView(
        isCorrect: false,
        pointsEarned: 0,
        onDismiss: {}
    )
}
