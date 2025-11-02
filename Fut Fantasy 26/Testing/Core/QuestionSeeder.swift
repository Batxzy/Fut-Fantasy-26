//
//  QuestionSeeder.swift
//  Fut Fantasy 26
//
//  Created by GitHub Copilot on 02/11/25.
//

import Foundation
import SwiftData

@MainActor
class QuestionSeeder {
    
    static func seedQuestionsIfNeeded(context: ModelContext) {
        print("🌱 [QuestionSeeder] Checking if questions need seeding...")
        
        // Check if questions already exist
        let descriptor = FetchDescriptor<Question>()
        if let existingQuestions = try? context.fetch(descriptor), !existingQuestions.isEmpty {
            print("   ℹ️  Questions already seeded (\(existingQuestions.count) questions)")
            return
        }
        
        print("   🌱 Seeding questions...")
        
        // Get today's date at midnight
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Seed questions for today and the next few days
        let questions: [Question] = [
            // Today's question
            Question(
                text: "How many World Cups have been held in Mexico?",
                correctAnswer: "2",
                basePoints: 1000,
                category: .history,
                difficulty: .easy,
                questionType: .multipleChoice,
                options: ["1", "2", "3", "4"],
                availableDate: today
            ),
            
            // Tomorrow's question
            Question(
                text: "Who won the 2022 FIFA World Cup?",
                correctAnswer: "Argentina",
                basePoints: 500,
                category: .trivia,
                difficulty: .easy,
                questionType: .multipleChoice,
                options: ["Argentina", "France", "Brazil", "Germany"],
                availableDate: calendar.date(byAdding: .day, value: 1, to: today)
            ),
            
            // Day after tomorrow
            Question(
                text: "Brazil has won the World Cup 5 times.",
                correctAnswer: "True",
                basePoints: 800,
                category: .trivia,
                difficulty: .easy,
                questionType: .trueFalse,
                availableDate: calendar.date(byAdding: .day, value: 2, to: today)
            ),
            
            // Day 4
            Question(
                text: "Who scored the most goals in a single World Cup tournament?",
                correctAnswer: "Just Fontaine",
                basePoints: 1500,
                category: .stats,
                difficulty: .hard,
                questionType: .textInput,
                availableDate: calendar.date(byAdding: .day, value: 3, to: today)
            ),
            
            // Day 5
            Question(
                text: "Which country hosted the first World Cup in 1930?",
                correctAnswer: "Uruguay",
                basePoints: 1200,
                category: .history,
                difficulty: .medium,
                questionType: .multipleChoice,
                options: ["Uruguay", "Brazil", "Argentina", "Italy"],
                availableDate: calendar.date(byAdding: .day, value: 4, to: today)
            ),
            
            // Day 6
            Question(
                text: "The World Cup trophy is made of solid gold.",
                correctAnswer: "False",
                basePoints: 800,
                category: .trivia,
                difficulty: .medium,
                questionType: .trueFalse,
                availableDate: calendar.date(byAdding: .day, value: 5, to: today)
            ),
            
            // Day 7
            Question(
                text: "How many teams participate in the World Cup finals?",
                correctAnswer: "32",
                basePoints: 1000,
                category: .general,
                difficulty: .easy,
                questionType: .multipleChoice,
                options: ["24", "32", "48", "64"],
                availableDate: calendar.date(byAdding: .day, value: 6, to: today)
            )
        ]
        
        // Insert all questions
        for question in questions {
            context.insert(question)
        }
        
        do {
            try context.save()
            print("   ✅ Successfully seeded \(questions.count) questions")
        } catch {
            print("   ❌ Failed to seed questions: \(error)")
        }
    }
}
