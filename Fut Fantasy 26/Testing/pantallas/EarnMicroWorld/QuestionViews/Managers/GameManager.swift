//
//  GameManager.swift
//  Fut Fantasy 26
//
//  Created by GitHub Copilot on 02/11/25.
//

import Foundation
import SwiftData
import Observation

// MARK: - Question State

enum QuestionState {
    case available
    case answered
    case locked(timeRemaining: TimeInterval)
    
    var isAvailable: Bool {
        if case .available = self {
            return true
        }
        return false
    }
    
    var isAnswered: Bool {
        if case .answered = self {
            return true
        }
        return false
    }
    
    var isLocked: Bool {
        if case .locked = self {
            return true
        }
        return false
    }
}

// MARK: - Game Manager

@Observable
@MainActor
final class GameManager {
    private let questionRepository: QuestionRepository
    private let squadRepository: SquadRepository
    private let modelContext: ModelContext
    
    // Configuration
    private let resetHour: Int // Hour of day to reset (0-23, UTC)
    
    init(
        questionRepository: QuestionRepository,
        squadRepository: SquadRepository,
        modelContext: ModelContext,
        resetHour: Int = 0 // Midnight UTC by default
    ) {
        self.questionRepository = questionRepository
        self.squadRepository = squadRepository
        self.modelContext = modelContext
        self.resetHour = resetHour
    }
    
    // MARK: - Question State Management
    
    func getRandomQuestion() async throws -> Question? {
        print("🎮 [GameManager] Getting random question")
        
        let questions = try await questionRepository.getAllQuestions()
        let activeQuestions = questions.filter { $0.isActive }
        
        guard !activeQuestions.isEmpty else {
            print("   ❌ No active questions available")
            return nil
        }
        
        let randomQuestion = activeQuestions.randomElement()
        print("   ✅ Found random question")
        return randomQuestion
    }
    
    func debugQuestionDates() async throws {
           print("🔍 Starting debug...")
           
           let questions = try await questionRepository.getAllQuestions()
           
           let now = Date()
           let calendar = Calendar.current
           let startOfToday = calendar.startOfDay(for: now)
           
           guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfToday) else {
               print("❌ Could not calculate end of day")
               return
           }
           
           print("🔍 Debug Info:")
           print("  Current time: \(now)")
           print("  Start of today (local): \(startOfToday)")
           print("  End of today (local): \(endOfDay)")
           print("  Timezone: \(calendar.timeZone.identifier)")
           print("  Questions in DB: \(questions.count)")
           print("")
           
           for q in questions {
               if let date = q.availableDate {
                   let diff = startOfToday.timeIntervalSince(date)
                   let isInRange = date >= startOfToday && date < endOfDay
                   print("  📋 Question: \(q.text.prefix(40))...")
                   print("     availableDate: \(date)")
                   print("     hours from start of today: \(diff / 3600)")
                   print("     isActive: \(q.isActive)")
                   print("     ✅ Would match query: \(isInRange)")
                   print("")
               }
           }
       }
    
    func getQuestionState(for question: Question) async throws -> QuestionState {
        print("🎮 [GameManager] Checking state for question: \(question.id)")
        
        // Check if already answered today
        let hasAnswered = try await questionRepository.hasAnsweredToday(questionId: question.id)
        
        if hasAnswered {
            print("   ✅ Already answered today")
            return .answered
        }
        
        // Check if question is available today
        guard let availableDate = question.availableDate else {
            print("   ✅ Question available (no date restriction)")
            return .available
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let startOfAvailableDay = calendar.startOfDay(for: availableDate)
        
        // If available date is in the future, question is locked
        if startOfAvailableDay > startOfToday {
            let timeRemaining = availableDate.timeIntervalSince(now)
            print("   🔒 Question locked - available in \(timeRemaining) seconds")
            return .locked(timeRemaining: timeRemaining)
        }
        
        // If available date is today or in the past, check if user missed it
        if startOfAvailableDay < startOfToday {
            // Question was for a past day and wasn't answered
            print("   🔒 Question expired (was for past day)")
            return .locked(timeRemaining: 0)
        }
        
        // Question is available today
        print("   ✅ Question available today")
        return .available
    }
    
    func getTodaysQuestion() async throws -> (question: Question, state: QuestionState)? {
        print("🎮 [GameManager] Getting today's question")
        
        guard let question = try await questionRepository.getTodaysQuestion() else {
            print("   ❌ No question available for today")
            return nil
        }
        
        let state = try await getQuestionState(for: question)
        print("   ✅ Found question with state: \(state)")
        return (question, state)
    }
    
    // MARK: - Answer Processing
    
    func submitAnswer(
        question: Question,
        userAnswer: String,
        squadId: UUID
    ) async throws -> (isCorrect: Bool, pointsEarned: Int) {
        print("🎮 [GameManager] Submitting answer for question: \(question.id)")
        
        // Verify question state
        let state = try await getQuestionState(for: question)
        guard state.isAvailable else {
            print("   ❌ Question not available for answering")
            throw RepositoryError.invalidData
        }
        
        // Check answer
        let isCorrect = question.isCorrectAnswer(userAnswer)
        let pointsEarned = isCorrect ? question.totalPoints : 0
        
        print("   Answer correct: \(isCorrect), Points: \(pointsEarned)")
        
        // Record the answer
        try await questionRepository.recordAnswer(
            questionId: question.id,
            userAnswer: userAnswer,
            isCorrect: isCorrect,
            pointsEarned: pointsEarned
        )
        
        // Award points to squad budget if correct
        if isCorrect {
            try await awardPointsToSquad(squadId: squadId, points: pointsEarned)
        }
        
        print("✅ [GameManager] Answer processed successfully")
        return (isCorrect, pointsEarned)
    }
    
    // MARK: - Squad Budget Integration
    
    func awardPointsToSquad(squadId: UUID, points: Int) async throws {
           print("🎮 [GameManager] Awarding \(points) display points to squad budget \(squadId)")
           
           let predicate = #Predicate<Squad> { $0.id == squadId }
           var descriptor = FetchDescriptor<Squad>(predicate: predicate)
           descriptor.fetchLimit = 1
           
           guard let squad = try modelContext.fetch(descriptor).first else {
               print("   ❌ Squad not found")
               throw RepositoryError.notFound
           }
           
           let displayToMillionDivisor: Double = 1000.0
           let millionsToAdd = Double(points) / displayToMillionDivisor
           
           squad.initialBudget += millionsToAdd
           
           print("""
                   ✅ Budget increment:
                      Display points: \(points)
                      Converted to millions: \(String(format: "%.3f", millionsToAdd))M
                      New initialBudget: \(String(format: "%.3f", squad.initialBudget))M
                  """)
           
           try await squadRepository.updateSquad(squad)
           print("   ✅ Squad budget updated successfully")
       }
    
    
    // MARK: - Constants
    
    private static let secondsPerDay: TimeInterval = 86400
    
    // MARK: - Timer Calculations
    
    func getTimeUntilNextReset() -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = resetHour
        components.minute = 0
        components.second = 0
        
        guard let nextReset = calendar.date(from: components) else {
            return Self.secondsPerDay
        }
        
        // If next reset is in the past, add a day
        if nextReset <= now {
            guard let tomorrowReset = calendar.date(byAdding: .day, value: 1, to: nextReset) else {
                return Self.secondsPerDay
            }
            return tomorrowReset.timeIntervalSince(now)
        }
        
        return nextReset.timeIntervalSince(now)
    }
    
    func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    func resetAllQuestionProgress() async throws {
            try await questionRepository.deleteAllUsersProgress()
        }
    
    // MARK: - Statistics
    
    func getTotalPointsEarned() async throws -> Int {
        return try await questionRepository.getTotalPointsEarned()
    }
    
    func getUserProgress() async throws -> [UserQuestionProgress] {
        return try await questionRepository.getAllUserProgress()
    }
}
