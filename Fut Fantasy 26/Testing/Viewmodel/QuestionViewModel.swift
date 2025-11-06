//
//  QuestionViewModel.swift
//  Fut Fantasy 26
//
//  Created by GitHub Copilot on 02/11/25.
//

import Foundation
import SwiftData
import Observation
import Combine

@Observable
@MainActor
final class QuestionViewModel {
    // State
    var currentQuestion: Question?
    var questionState: QuestionState = .locked(timeRemaining: 0)
    var userAnswer: String = ""
    var showResult: Bool = false
    var lastResult: (isCorrect: Bool, pointsEarned: Int)?
    
    var errorMessage: String?
    var isLoading = false
    
    // Timer for countdown
    var timeRemaining: TimeInterval = 0
    private var timer: Timer?
    
    // Dependencies
    private let gameManager: GameManager
    private let squadId: UUID
    
    init(gameManager: GameManager, squadId: UUID) {
        self.gameManager = gameManager
        self.squadId = squadId
    }
    
    static func create(
        modelContext: ModelContext,
        squadId: UUID,
        resetHour: Int = 0
    ) -> QuestionViewModel {
        let questionRepo = SwiftDataQuestionRepository(modelContext: modelContext)
        let squadRepo = SwiftDataSquadRepository(
            modelContext: modelContext,
            playerRepository: SwiftDataPlayerRepository(modelContext: modelContext)
        )
        let gameManager = GameManager(
            questionRepository: questionRepo,
            squadRepository: squadRepo,
            modelContext: modelContext,
            resetHour: resetHour
        ) 
        return QuestionViewModel(gameManager: gameManager, squadId: squadId)
    }
    
    // MARK: - Lifecycle
    
    func onAppear() async {
        if currentQuestion == nil {
            await loadTodaysQuestion()
        }
        // Always start the timer
        startTimer()
    }
    
    func onDisappear() {
        stopTimer()
    }
    
    // MARK: - Data Loading
    
    
    
    func resetProgressForDemo() async {
            print("📱 [QuestionVM] Resetting all question progress for demo")
            isLoading = true
            errorMessage = nil
            do {
                try await gameManager.resetAllQuestionProgress()
                resetAnswer() // This is an existing function in your ViewModel
                showResult = false
                lastResult = nil
                await loadTodaysQuestion() // Reloads the question
            } catch {
                errorMessage = error.localizedDescription
                print("❌ [QuestionVM] Failed to reset progress: \(error)")
            }
            isLoading = false
        }
    
    func loadTodaysQuestion() async {
        print("📱 [QuestionVM] Loading today's question")
        
        try? await gameManager.debugQuestionDates()
        
        isLoading = true
        errorMessage = nil
        
        do {
            if let result = try await gameManager.getTodaysQuestion() {
                currentQuestion = result.question
                questionState = result.state
                
                if case .locked(let time) = result.state {
                    timeRemaining = time
                } else if result.state.isAnswered {
                    timeRemaining = gameManager.getTimeUntilNextReset()
                }
                
                print("✅ [QuestionVM] Question loaded: \(result.question.text)")
            } else {
                currentQuestion = nil
                questionState = .locked(timeRemaining: gameManager.getTimeUntilNextReset())
                timeRemaining = gameManager.getTimeUntilNextReset()
                print("ℹ️  [QuestionVM] No question available")
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [QuestionVM] Failed to load question: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Answer Submission
    
    func submitAnswer() async {
        guard let question = currentQuestion else {
            errorMessage = "No question available"
            return
        }
        
        guard !userAnswer.isEmpty else {
            errorMessage = "Please enter an answer"
            return
        }
        
        print("📱 [QuestionVM] Submitting answer")
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await gameManager.submitAnswer(
                question: question,
                userAnswer: userAnswer,
                squadId: squadId
            )
            
            lastResult = result
            showResult = true
            
           
            questionState = .answered
            timeRemaining = gameManager.getTimeUntilNextReset()
            
            if result.isCorrect {
                print("✅ [QuestionVM] Correct answer! Earned \(result.pointsEarned) points")
            } else {
                print("❌ [QuestionVM] Incorrect answer")
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [QuestionVM] Failed to submit answer: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        stopTimer()
        
        let newTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateTimer()
            }
        }
        
        RunLoop.current.add(newTimer, forMode: .common)
        self.timer = newTimer
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateTimer() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else if timeRemaining == 0 {
            // Time's up - reload the question once
            timeRemaining = -1 // Prevent multiple reloads
            Task {
                await loadTodaysQuestion()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var isQuestionAvailable: Bool {
        questionState.isAvailable
    }
    
    var isQuestionAnswered: Bool {
        questionState.isAnswered
    }
    
    var isQuestionLocked: Bool {
        questionState.isLocked
    }
    
    var formattedTimeRemaining: String {
        gameManager.formatTimeRemaining(timeRemaining)
    }
    
    var canSubmitAnswer: Bool {
        !userAnswer.isEmpty && isQuestionAvailable && !isLoading
    }
    
    // MARK: - Helper Methods
    
    func resetAnswer() {
        userAnswer = ""
        showResult = false
        lastResult = nil
    }
    
    func dismissResult() {
        showResult = false
    }
}
