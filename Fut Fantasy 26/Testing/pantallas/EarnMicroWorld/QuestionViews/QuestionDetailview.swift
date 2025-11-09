//
//  QuestionDetailview.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 02/11/25.
//

import SwiftUI
import SwiftData

struct QuestionDetailview: View {
    
    @Bindable var viewModel: QuestionViewModel
    
    private var options: [String] {
        guard let question = viewModel.currentQuestion else { return [] }
        
        switch question.questionType {
        case .multipleChoice:
            return question.options ?? []
        case .trueFalse:
            return ["True", "False"]
        case .textInput:
            return []
        }
    }
    
    private var displayPointsForOverlay: Int {
            viewModel.currentQuestion?.totalPoints ?? 0
        }
    
    var body: some View {
        ZStack {
            Color.mainBg.ignoresSafeArea()
            
            VStack(spacing:28){
                
                Text("Question of the day")
                    .font(.system(size: 20))
                    .fontWeight(.heavy)
                    .textCase(.uppercase)
                    .fontWidth(.condensed)
                    .foregroundColor(.wpMint)
                    .kerning(1)
                
                if let question = viewModel.currentQuestion {
                    
                    ZStack{
                        QuestionView(text: question.text)
                        
                        if viewModel.showResult {
                            if let result = viewModel.lastResult, result.isCorrect {
                                CorrectAnswerOverlay(points: displayPointsForOverlay)
                                    .transition(.blurReplace.animation(.bouncy).combined(with: .scale.animation(.bouncy)))
                                    .offset(y:-25)
                                    .frame(height: 180, alignment: .top)
                                   
                            } else {
                                IncorrectAnswerOverlay()
                                    .transition(.scale.animation(.bouncy))
                            }
                        }
                    }
                    
                    VStack(spacing: 12) {
                        ForEach(options, id: \.self) { option in
                            QuizAnswerButton(
                                answer: option,
                                state: buttonState(for: option),
                                action: {
                                    buttonAction(for: option)
                                }
                            )
                        }
                    }
                    .padding(.horizontal,38)
                    
                    if !viewModel.showResult && viewModel.isQuestionAvailable {
                        Button(action: {
                            Task {
                                await viewModel.submitAnswer()
                            }
                        }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            } else {
                                Text("Submit")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(viewModel.userAnswer.isEmpty ? .white.opacity(0.5) : .black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(viewModel.userAnswer.isEmpty ? Color.gray.opacity(0.3) : Color.wpMint)
                        .cornerRadius(16)
                        .disabled(viewModel.userAnswer.isEmpty || viewModel.isLoading)
                        .padding(.horizontal,38)
                    }
                    
                    Spacer()
                    
                } else if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("No question available today.\nCheck back later!")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .onAppear {
            if !viewModel.showResult {
                viewModel.resetAnswer()
            }
        }
    }
    
    private func buttonState(for option: String) -> QuizButtonState {
        guard let question = viewModel.currentQuestion else { return .default }

        if viewModel.showResult {
            if option == question.correctAnswer {
                return .correct
            } else if option == viewModel.userAnswer {
                return .wrong
            } else {
                return .default
            }
        } else {
            return viewModel.userAnswer == option ? .selected : .default
        }
    }
    
    private func buttonAction(for option: String) {
        if viewModel.showResult { return }
        viewModel.userAnswer = option
    }
}

struct CorrectAnswerOverlay: View {
    let points: Int
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("+\(points)")
                .font(.system(size: 28, weight: .bold))
            Image(systemName: "star.circle.fill")
                .font(.system(size: 26))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(Color.wpBlueOcean)
        .cornerRadius(16)
    }
}

struct IncorrectAnswerOverlay: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.wpRedBright)
                .frame(width: 120, height: 100)
            
            Image(systemName: "xmark")
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(.white)
        }
    }
}


struct QuestionView : View {
    
    let text: String
    
    var body: some View {
        HStack{
            Text(text)
                .foregroundStyle(.white)
                .font(.system(size: 20))
                .fontWeight(.regular)
                .fontWidth(.compressed)
                .frame(width: 133, height: 96, alignment: .topLeading)
                .minimumScaleFactor(0.5)
            
            
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
                .frame(height: 68)
                .background(backgroundColor)
                .cornerRadius(16)
        }
        .animation(.spring(duration: 0.4), value: state)
        .disabled(state == .correct || state == .wrong || state == .selected)
    }
    
    private var backgroundColor: Color {
        switch state {
        case .default:
            return Color.gray.opacity(0.3)
        case .selected:
            return Color.wpMint
        case .correct:
            return Color.wpMint
        case .wrong:
            return Color.wpRedBright
        }
    }
    
    private var textColor: Color {
        switch state {
        case .default:
            return .white.opacity(0.5)
        case .selected, .correct, .wrong:
            return .black
        }
    }
}

/*
#Preview("Multiple Choice") {
    
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Player.self, Squad.self, Question.self, UserQuestionProgress.self,
        configurations: config
    )
    let context = container.mainContext
    
    let today = Calendar.current.startOfDay(for: Date())
    let question = Question(
        text: "How many World Cups have been held in Mexico?",
        correctAnswer: "2",
        basePoints: 1000,
        category: .history,
        difficulty: .easy,
        questionType: .multipleChoice,
        options: ["1", "2", "3", "4"],
        availableDate: today
    )
    context.insert(question)
    
    let squad = Squad(teamName: "Preview")
    context.insert(squad)
    
    let vm = QuestionViewModel.create(modelContext: context, squadId: squad.id)
    
    vm.currentQuestion = question
    vm.questionState = .available
    
    return NavigationStack {
        QuestionDetailview(viewModel: vm)
    }
    .modelContainer(container)
    .environment(\.modelContext, context)
}

#Preview("True/False - Result") {
    
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Player.self, Squad.self, Question.self, UserQuestionProgress.self,
        configurations: config
    )
    let context = container.mainContext
    
    let today = Calendar.current.startOfDay(for: Date())
    let question = Question(
        text: "Brazil has won the World Cup 5 times.",
        correctAnswer: "True",
        basePoints: 500,
        category: .trivia,
        difficulty: .easy,
        questionType: .trueFalse,
        availableDate: today
    )
    context.insert(question)
    
    let squad = Squad(teamName: "Preview")
    context.insert(squad)
    
    let vm = QuestionViewModel.create(modelContext: context, squadId: squad.id)
    
    vm.currentQuestion = question
    vm.questionState = .answered
    vm.userAnswer = "True"
    vm.showResult = true
    vm.lastResult = (isCorrect: false, pointsEarned: 0)
    
    return NavigationStack {
        QuestionDetailview(viewModel: vm)
    }
    .modelContainer(container)
    .environment(\.modelContext, context)
}

#Preview("True badge"){
    CorrectAnswerOverlay(points: 1000)
}

*/
