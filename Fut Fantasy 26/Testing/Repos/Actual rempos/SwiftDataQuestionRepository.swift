//
//  SwiftDataQuestionRepository.swift
//  Fut Fantasy 26
//
//  Created by GitHub Copilot on 02/11/25.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataQuestionRepository: QuestionRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Question Management
    
    func createQuestion(_ question: Question) async throws {
        print("❓ [QuestionRepo] Creating new question: \(question.text)")
        
        modelContext.insert(question)
        
        do {
            try modelContext.save()
            print("✅ [QuestionRepo] Question created successfully")
        } catch {
            print("❌ [QuestionRepo] Create failed: \(error)")
            throw RepositoryError.saveFailed(underlyingError: error)
        }
    }
    
    func updateQuestion(_ question: Question) async throws {
        print("❓ [QuestionRepo] Updating question")
        
        do {
            try modelContext.save()
            print("✅ [QuestionRepo] Question updated successfully")
        } catch {
            print("❌ [QuestionRepo] Update failed: \(error)")
            throw RepositoryError.updateFailed(underlyingError: error)
        }
    }
    
    func deleteQuestion(_ question: Question) async throws {
        print("❓ [QuestionRepo] Deleting question")
        
        modelContext.delete(question)
        
        do {
            try modelContext.save()
            print("✅ [QuestionRepo] Question deleted successfully")
        } catch {
            print("❌ [QuestionRepo] Delete failed: \(error)")
            throw RepositoryError.deleteFailed(underlyingError: error)
        }
    }
    
    func getQuestionById(_ id: UUID) async throws -> Question? {
        print("❓ [QuestionRepo] Fetching question by id: \(id)")
        
        let predicate = #Predicate<Question> { $0.id == id }
        var descriptor = FetchDescriptor<Question>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        do {
            let questions = try modelContext.fetch(descriptor)
            print("✅ [QuestionRepo] Question fetched: \(questions.first != nil)")
            return questions.first
        } catch {
            print("❌ [QuestionRepo] Fetch failed: \(error)")
            throw RepositoryError.fetchFailed(underlyingError: error)
        }
    }
    
    func getAllQuestions() async throws -> [Question] {
        print("❓ [QuestionRepo] Fetching all questions")
        
        let descriptor = FetchDescriptor<Question>(
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        
        do {
            let questions = try modelContext.fetch(descriptor)
            print("✅ [QuestionRepo] Fetched \(questions.count) questions")
            return questions
        } catch {
            print("❌ [QuestionRepo] Fetch failed: \(error)")
            throw RepositoryError.fetchFailed(underlyingError: error)
        }
    }
    
    func getQuestionsByCategory(_ category: QuestionCategory) async throws -> [Question] {
        print("❓ [QuestionRepo] Fetching questions for category: \(category.rawValue)")
        
        let predicate = #Predicate<Question> { $0.category == category && $0.isActive }
        let descriptor = FetchDescriptor<Question>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        
        do {
            let questions = try modelContext.fetch(descriptor)
            print("✅ [QuestionRepo] Fetched \(questions.count) questions")
            return questions
        } catch {
            print("❌ [QuestionRepo] Fetch failed: \(error)")
            throw RepositoryError.fetchFailed(underlyingError: error)
        }
    }
    
    func getTodaysQuestion() async throws -> Question? {
        print("❓ [QuestionRepo] Fetching today's question")
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        let predicate = #Predicate<Question> { question in
            question.isActive &&
            question.availableDate != nil &&
            question.availableDate! >= startOfDay &&
            question.availableDate! < endOfDay
        }
        
        var descriptor = FetchDescriptor<Question>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        do {
            let questions = try modelContext.fetch(descriptor)
            print("✅ [QuestionRepo] Today's question fetched: \(questions.first != nil)")
            return questions.first
        } catch {
            print("❌ [QuestionRepo] Fetch failed: \(error)")
            throw RepositoryError.fetchFailed(underlyingError: error)
        }
    }
    
    
    // MARK: - User Progress Management
    
    func recordAnswer(
        questionId: UUID,
        userAnswer: String,
        isCorrect: Bool,
        pointsEarned: Int
    ) async throws {
        print("❓ [QuestionRepo] Recording answer for question: \(questionId)")
        
        // Check if progress already exists
        if let existingProgress = try await getUserProgress(for: questionId) {
            // Update existing progress
            existingProgress.lastAnswerDate = Date()
            existingProgress.isCorrect = isCorrect
            existingProgress.pointsEarned = isCorrect ? pointsEarned : 0
            existingProgress.userAnswer = userAnswer
        } else {
            // Create new progress
            let progress = UserQuestionProgress(
                questionId: questionId,
                lastAnswerDate: Date(),
                isCorrect: isCorrect,
                pointsEarned: isCorrect ? pointsEarned : 0,
                userAnswer: userAnswer
            )
            modelContext.insert(progress)
        }
        
        do {
            try modelContext.save()
            print("✅ [QuestionRepo] Answer recorded successfully")
        } catch {
            print("❌ [QuestionRepo] Record failed: \(error)")
            throw RepositoryError.saveFailed(underlyingError: error)
        }
    }
    
    func getUserProgress(for questionId: UUID) async throws -> UserQuestionProgress? {
        print("❓ [QuestionRepo] Fetching user progress for question: \(questionId)")
        
        let predicate = #Predicate<UserQuestionProgress> { $0.questionId == questionId }
        var descriptor = FetchDescriptor<UserQuestionProgress>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        do {
            let progress = try modelContext.fetch(descriptor)
            print("✅ [QuestionRepo] Progress fetched: \(progress.first != nil)")
            return progress.first
        } catch {
            print("❌ [QuestionRepo] Fetch failed: \(error)")
            throw RepositoryError.fetchFailed(underlyingError: error)
        }
    }
    
    func hasAnsweredToday(questionId: UUID) async throws -> Bool {
        print("❓ [QuestionRepo] Checking if question answered today: \(questionId)")
        
        guard let progress = try await getUserProgress(for: questionId) else {
            print("✅ [QuestionRepo] No progress found - not answered")
            return false
        }
        
        let answeredToday = Calendar.current.isDateInToday(progress.lastAnswerDate)
        print("✅ [QuestionRepo] Answered today: \(answeredToday)")
        return answeredToday
    }
    
    func getTotalPointsEarned() async throws -> Int {
        print("❓ [QuestionRepo] Calculating total points earned")
        
        let descriptor = FetchDescriptor<UserQuestionProgress>()
        
        do {
            let allProgress = try modelContext.fetch(descriptor)
            let total = allProgress.reduce(0) { $0 + $1.pointsEarned }
            print("✅ [QuestionRepo] Total points: \(total)")
            return total
        } catch {
            print("❌ [QuestionRepo] Fetch failed: \(error)")
            throw RepositoryError.fetchFailed(underlyingError: error)
        }
    }
    
    func getAllUserProgress() async throws -> [UserQuestionProgress] {
        print("❓ [QuestionRepo] Fetching all user progress")
        
        let descriptor = FetchDescriptor<UserQuestionProgress>(
            sortBy: [SortDescriptor(\.lastAnswerDate, order: .reverse)]
        )
        
        do {
            let progress = try modelContext.fetch(descriptor)
            print("✅ [QuestionRepo] Fetched \(progress.count) progress records")
            return progress
        } catch {
            print("❌ [QuestionRepo] Fetch failed: \(error)")
            throw RepositoryError.fetchFailed(underlyingError: error)
        }
    }
}
