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
        
        // Pregunta de hoy
        let todayPredicate = #Predicate<Question> { $0.availableDate == today }
        let todayDescriptor = FetchDescriptor<Question>(predicate: todayPredicate)
        let isTodayQuestionMissing = (try? context.fetch(todayDescriptor))?.isEmpty ?? true
        
        if isTodayQuestionMissing {
            print("   ⚠️ Seeding today's question...")
            
            let todayQuestion = Question(
                text: "How many World Cups have been held in Mexico?",
                correctAnswer: "2",
                category: .history,
                difficulty: .easy,
                questionType: .multipleChoice,
                rewardMillions: 10.0,
                options: ["1","2","3","4"],
                availableDate: today
            )
            context.insert(todayQuestion)
            
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)
            let tomorrowQuestion = Question(
                text: "Who won the 2022 FIFA World Cup?",
                correctAnswer: "Argentina",
                category: .trivia,
                difficulty: .easy,
                questionType: .multipleChoice,
                rewardMillions: 1.5,
                options: ["Argentina", "France", "Brazil", "Germany"],
                availableDate: tomorrow
            )
            context.insert(tomorrowQuestion)
            
            do {
                try context.save()
                print("   ✅ Seeded today & tomorrow.")
            } catch {
                print("   ❌ Error seeding: \(error)")
            }
        } else {
            print("   ℹ️ Today's question already exists.")
        }
        
        // Sembrar las futuras hasta tener >= 7
        let allDescriptor = FetchDescriptor<Question>()
        let count = (try? context.fetch(allDescriptor).count) ?? 0
        
        if count < 7 {
            print("   🌱 Seeding additional future questions...")
            seedRemaining(context: context, today: today)
        }
    }
    
    private static func seedRemaining(context: ModelContext, today: Date) {
        let calendar = Calendar.current
        
        let future: [Question] = [
            Question(
                text: "Brazil has won the World Cup 5 times.",
                correctAnswer: "True",
                category: .trivia,
                difficulty: .easy,
                questionType: .trueFalse,
                rewardMillions: 0.8,
                availableDate: calendar.date(byAdding: .day, value: 2, to: today)
            ),
            Question(
                text: "Who scored the most goals in a single World Cup tournament?",
                correctAnswer: "Just Fontaine",
                category: .stats,
                difficulty: .hard,
                questionType: .textInput,
                rewardMillions: 1.5,
                availableDate: calendar.date(byAdding: .day, value: 3, to: today)
            ),
            Question(
                text: "Which country hosted the first World Cup in 1930?",
                correctAnswer: "Uruguay",
                category: .history,
                difficulty: .medium,
                questionType: .multipleChoice,
                rewardMillions: 1.2,
                options: ["Uruguay","Brazil","Argentina","Italy"],
                availableDate: calendar.date(byAdding: .day, value: 4, to: today)
            ),
            Question(
                text: "The World Cup trophy is made of solid gold.",
                correctAnswer: "False",
                category: .trivia,
                difficulty: .medium,
                questionType: .trueFalse,
                rewardMillions: 0.8,
                availableDate: calendar.date(byAdding: .day, value: 5, to: today)
            ),
            Question(
                text: "How many teams participated in the 2022 World Cup?",
                correctAnswer: "32",
                category: .general,
                difficulty: .easy,
                questionType: .multipleChoice,
                rewardMillions: 1.0,
                options: ["24","32","48","64"],
                availableDate: calendar.date(byAdding: .day, value: 6, to: today)
            )
        ]
        
        future.forEach { context.insert($0) }
        
        do {
            try context.save()
            print("   ✅ Future questions seeded.")
        } catch {
            print("   ❌ Failed seeding future: \(error)")
        }
    }
}

