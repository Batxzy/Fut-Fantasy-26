//
//  Question.swift
//  Fut Fantasy 26
//
//  Created by GitHub Copilot on 02/11/25.
//

import Foundation
import SwiftData

// MARK: - Question Type Enum

enum QuestionType: String, Codable, CaseIterable {
    case multipleChoice = "Multiple Choice"
    case trueFalse = "True/False"
    case textInput = "Text Input"
}

// MARK: - Question Category Enum

enum QuestionCategory: String, Codable, CaseIterable {
    case history = "History"
    case stats = "Stats"
    case players = "Players"
    case teams = "Teams"
    case general = "General"
    case trivia = "Trivia"
}

// MARK: - Question Difficulty Enum

enum QuestionDifficulty: String, Codable, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var pointsMultiplier: Double {
        switch self {
        case .easy: return 1.0
        case .medium: return 1.5
        case .hard: return 2.0
        }
    }
}

// MARK: - Question Model

@Model
final class Question {
    @Attribute(.unique) var id: UUID
    var text: String
    var correctAnswer: String
    var rewardMillions: Double
    var category: QuestionCategory
    var difficulty: QuestionDifficulty
    var questionType: QuestionType
    
    // For multiple choice questions
    var options: [String]?
    
    // Metadata
    var createdDate: Date
    var isActive: Bool
    
    // Daily question tracking
    var availableDate: Date? // The specific day this question is available
    
    init(
            text: String,
            correctAnswer: String,
            category: QuestionCategory,
            difficulty: QuestionDifficulty,
            questionType: QuestionType,
            rewardMillions: Double,
            options: [String]? = nil,
            availableDate: Date? = nil
        ) {
            self.id = UUID()
            self.text = text
            self.correctAnswer = correctAnswer
            self.category = category
            self.difficulty = difficulty
            self.questionType = questionType
            self.options = options
            self.createdDate = Date()
            self.isActive = true
            self.availableDate = availableDate
            self.rewardMillions = rewardMillions
        }
    
    // MARK: - Computed Properties
    
    var totalPoints: Int {
            Int((rewardMillions * 1000).rounded())  
        }
        
        var displayPoints: String {
            "+\(totalPoints)"
        }
    
    // MARK: - Answer Validation
    
    func isCorrectAnswer(_ answer: String) -> Bool {
        let normalizedCorrect = normalizeString(correctAnswer)
        let normalizedAnswer = normalizeString(answer)
        return normalizedCorrect == normalizedAnswer
    }
    
    private func normalizeString(_ string: String) -> String {
        // Trim whitespace and convert to lowercase
        var normalized = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Remove diacritics (accents) for more flexible matching
        normalized = normalized.folding(options: .diacriticInsensitive, locale: .current)
        
        // Remove extra spaces
        normalized = normalized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        return normalized
    }
}
