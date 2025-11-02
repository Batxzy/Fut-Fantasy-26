//
//  UserQuestionProgress.swift
//  Fut Fantasy 26
//
//  Created by GitHub Copilot on 02/11/25.
//

import Foundation
import SwiftData

// MARK: - User Question Progress Model

@Model
final class UserQuestionProgress {
    @Attribute(.unique) var id: UUID
    var questionId: UUID
    var lastAnswerDate: Date
    var isCorrect: Bool
    var pointsEarned: Int
    var userAnswer: String?
    
    init(
        questionId: UUID,
        lastAnswerDate: Date,
        isCorrect: Bool,
        pointsEarned: Int,
        userAnswer: String? = nil
    ) {
        self.id = UUID()
        self.questionId = questionId
        self.lastAnswerDate = lastAnswerDate
        self.isCorrect = isCorrect
        self.pointsEarned = pointsEarned
        self.userAnswer = userAnswer
    }
}

// MARK: - Question Statistics

extension UserQuestionProgress {
    var wasAnsweredToday: Bool {
        Calendar.current.isDateInToday(lastAnswerDate)
    }
    
    var daysSinceAnswer: Int {
        Calendar.current.dateComponents([.day], from: lastAnswerDate, to: Date()).day ?? 0
    }
}
