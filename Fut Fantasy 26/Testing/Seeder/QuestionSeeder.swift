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
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 1. Check if a question for TODAY is present
        let todayPredicate = #Predicate<Question> { $0.availableDate == today }
        let todayDescriptor = FetchDescriptor<Question>(predicate: todayPredicate)
        let isTodayQuestionMissing = (try? context.fetch(todayDescriptor))?.isEmpty ?? true
        
        if isTodayQuestionMissing {
            print("   ⚠️ Question for today is missing/expired. Seeding today's single question...")
            
            let todayQuestion = Question(
                text: "How many World Cups have been held in Mexico?",
                correctAnswer: "2",
                basePoints: 1000,
                category: .history,
                difficulty: .easy,
                questionType: .multipleChoice,
                options: ["1", "2", "3", "4"],
                availableDate: today
            )
            context.insert(todayQuestion)
            
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)
            let tomorrowQuestion = Question(
                text: "Who won the 2022 FIFA World Cup?",
                correctAnswer: "Argentina",
                basePoints: 500,
                category: .trivia,
                difficulty: .easy,
                questionType: .multipleChoice,
                options: ["Argentina", "France", "Brazil", "Germany"],
                availableDate: tomorrow
            )
            context.insert(tomorrowQuestion)

            do {
                try context.save()
                print("   ✅ Successfully seeded today's and tomorrow's questions.")
            } catch {
                print("   ❌ Failed to seed today's question: \(error)")
            }
        } else {
            print("   ℹ️  Today's question is already seeded.")
        }
        
        // 2. Check if the full set of 7 questions has ever been seeded
        let descriptor = FetchDescriptor<Question>()
        if (try? context.fetch(descriptor))?.count ?? 0 < 7 {
            print("   🌱 Seeding remaining future questions...")
            seedRemainingFutureQuestions(context: context, today: today)
        }
    }
    
    // Helper to seed the full 7 questions only once, if needed
    private static func seedRemainingFutureQuestions(context: ModelContext, today: Date) {
        let calendar = Calendar.current
        let questions: [Question] = [
            Question(
                text: "Brazil has won the World Cup 5 times.",
                correctAnswer: "True",
                basePoints: 800,
                category: .trivia,
                difficulty: .easy,
                questionType: .trueFalse,
                availableDate: calendar.date(byAdding: .day, value: 2, to: today)
            ),
            Question(
                text: "Who scored the most goals in a single World Cup tournament?",
                correctAnswer: "Just Fontaine",
                basePoints: 1500,
                category: .stats,
                difficulty: .hard,
                questionType: .textInput,
                availableDate: calendar.date(byAdding: .day, value: 3, to: today)
            ),
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
            Question(
                text: "The World Cup trophy is made of solid gold.",
                correctAnswer: "False",
                basePoints: 800,
                category: .trivia,
                difficulty: .medium,
                questionType: .trueFalse,
                availableDate: calendar.date(byAdding: .day, value: 5, to: today)
            ),
            Question(
                text: "How many teams participated in the 2022 World Cup?",
                correctAnswer: "32",
                basePoints: 1000,
                category: .general,
                difficulty: .easy,
                questionType: .multipleChoice,
                options: ["24", "32", "48", "64"],
                availableDate: calendar.date(byAdding: .day, value: 6, to: today)
            )
        ]
        
        for question in questions {
            context.insert(question)
        }
        
        do {
            try context.save()
            print("   ✅ Successfully seeded remaining future questions.")
        } catch {
            print("   ❌ Failed to seed remaining questions: \(error)")
        }
    }
}

