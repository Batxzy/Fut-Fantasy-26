//
//  QuestionRepository.swift
//  Fut Fantasy 26
//
//  Created by GitHub Copilot on 02/11/25.
//

import Foundation

protocol QuestionRepository {
    // Question Management
    func deleteAllUsersProgress() async throws
    func createQuestion(_ question: Question) async throws
    func updateQuestion(_ question: Question) async throws
    func deleteQuestion(_ question: Question) async throws
    func getQuestionById(_ id: UUID) async throws -> Question?
    func getAllQuestions() async throws -> [Question]
    func getQuestionsByCategory(_ category: QuestionCategory) async throws -> [Question]
    func getTodaysQuestion() async throws -> Question?
    
    // User Progress Management
    func recordAnswer(
        questionId: UUID,
        userAnswer: String,
        isCorrect: Bool,
        pointsEarned: Int
    ) async throws
    func getUserProgress(for questionId: UUID) async throws -> UserQuestionProgress?
    func hasAnsweredToday(questionId: UUID) async throws -> Bool
    func getTotalPointsEarned() async throws -> Int
    func getAllUserProgress() async throws -> [UserQuestionProgress]
}
