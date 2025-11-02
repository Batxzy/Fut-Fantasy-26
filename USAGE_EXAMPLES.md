# Question of the Day - Usage Examples

## Basic Usage in Views

### Using QuestionViewModel in a View

```swift
import SwiftUI
import SwiftData

struct MyQuestionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var squads: [Squad]
    @State private var viewModel: QuestionViewModel?
    
    var body: some View {
        VStack {
            if let viewModel = viewModel {
                if let question = viewModel.currentQuestion {
                    Text(question.text)
                    Text("Points: \(question.totalPoints)")
                    
                    if viewModel.isQuestionLocked {
                        Text("Available in: \(viewModel.formattedTimeRemaining)")
                    }
                }
            }
        }
        .task {
            if let squad = squads.first {
                viewModel = QuestionViewModel.create(
                    modelContext: modelContext,
                    squadId: squad.id
                )
                await viewModel?.onAppear()
            }
        }
    }
}
```

## Creating Questions Programmatically

### Adding a New Question

```swift
@MainActor
func addCustomQuestion(context: ModelContext) {
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    
    let question = Question(
        text: "What year did Pelé retire?",
        correctAnswer: "1977",
        basePoints: 1200,
        category: .history,
        difficulty: .medium,
        questionType: .textInput,
        availableDate: tomorrow
    )
    
    context.insert(question)
    try? context.save()
}
```

### Creating a Multiple Choice Question

```swift
let question = Question(
    text: "Which country won the first World Cup?",
    correctAnswer: "Uruguay",
    basePoints: 1000,
    category: .history,
    difficulty: .easy,
    questionType: .multipleChoice,
    options: ["Uruguay", "Brazil", "Argentina", "Italy"],
    availableDate: Date()
)
```

### Creating a True/False Question

```swift
let question = Question(
    text: "The World Cup is held every 4 years.",
    correctAnswer: "True",
    basePoints: 500,
    category: .trivia,
    difficulty: .easy,
    questionType: .trueFalse,
    availableDate: Date()
)
```

## Working with GameManager

### Checking Question State

```swift
@MainActor
func checkQuestionAvailability(
    gameManager: GameManager,
    question: Question
) async {
    let state = try? await gameManager.getQuestionState(for: question)
    
    switch state {
    case .available:
        print("Question is ready to answer!")
    case .answered:
        print("Already answered today")
    case .locked(let time):
        print("Available in \(time) seconds")
    case .none:
        print("Error checking state")
    }
}
```

### Submitting an Answer

```swift
@MainActor
func submitUserAnswer(
    gameManager: GameManager,
    question: Question,
    squadId: UUID,
    answer: String
) async {
    do {
        let result = try await gameManager.submitAnswer(
            question: question,
            userAnswer: answer,
            squadId: squadId
        )
        
        if result.isCorrect {
            print("Correct! Earned \(result.pointsEarned) points")
        } else {
            print("Incorrect answer")
        }
    } catch {
        print("Error: \(error)")
    }
}
```

## Using Repositories Directly

### Fetching Today's Question

```swift
@MainActor
func getTodaysQuestion(
    repository: QuestionRepository
) async -> Question? {
    return try? await repository.getTodaysQuestion()
}
```

### Checking if Question Answered

```swift
@MainActor
func checkIfAnswered(
    repository: QuestionRepository,
    questionId: UUID
) async -> Bool {
    return (try? await repository.hasAnsweredToday(questionId: questionId)) ?? false
}
```

### Getting Total Points Earned

```swift
@MainActor
func getTotalPoints(
    repository: QuestionRepository
) async -> Int {
    return (try? await repository.getTotalPointsEarned()) ?? 0
}
```

## Custom EarnCard Usage

### Basic Card

```swift
EarnCard(
    question: "How many teams participate?",
    points: 1000,
    foregroundIcon: AnyView(IconQuestionmark())
)
```

### Card with Countdown Timer

```swift
EarnCard(
    question: "Next question available soon",
    points: 1500,
    isEnabled: false,
    countdownText: "02:30:45",
    foregroundIcon: AnyView(IconQuestionmark())
)
```

### Answered Card

```swift
EarnCard(
    question: "You've answered this question!",
    points: 2000,
    isEnabled: false,
    isAnswered: true,
    foregroundIcon: AnyView(IconQuestionmark())
)
```

### Custom Styled Card

```swift
EarnCard(
    title: "TRIVIA CHALLENGE",
    question: "Test your World Cup knowledge",
    points: 5000,
    action: { print("Card tapped") },
    backgroundColor: .wpPurpleDeep,
    accentColor: .wpGreenLime,
    backgroundIconColor: .wpPurpleLilac,
    foregroundIcon: AnyView(Icon26()),
    foregroundIconScale: 0.8
)
```

## Advanced: Custom Repository Implementation

If you need a different storage backend:

```swift
@MainActor
final class CustomQuestionRepository: QuestionRepository {
    func getTodaysQuestion() async throws -> Question? {
        // Your custom implementation
        // Could fetch from API, CoreData, etc.
    }
    
    func recordAnswer(
        questionId: UUID,
        userAnswer: String,
        isCorrect: Bool,
        pointsEarned: Int
    ) async throws {
        // Your custom implementation
    }
    
    // ... implement other protocol methods
}
```

## Timer Customization

### Custom Reset Time (6 AM UTC)

```swift
let gameManager = GameManager(
    questionRepository: questionRepo,
    squadRepository: squadRepo,
    modelContext: modelContext,
    resetHour: 6  // 6 AM UTC
)
```

### Custom Time Formatting

```swift
extension GameManager {
    func formatTimeRemainingCustom(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) minutes"
        }
    }
}
```

## Statistics and Analytics

### Get User's Answer History

```swift
@MainActor
func getAnswerHistory(
    repository: QuestionRepository
) async -> [UserQuestionProgress] {
    return (try? await repository.getAllUserProgress()) ?? []
}
```

### Calculate Success Rate

```swift
@MainActor
func calculateSuccessRate(
    repository: QuestionRepository
) async -> Double {
    guard let progress = try? await repository.getAllUserProgress() else {
        return 0.0
    }
    
    let total = progress.count
    let correct = progress.filter { $0.isCorrect }.count
    
    return total > 0 ? Double(correct) / Double(total) : 0.0
}
```

### Get Points by Category

```swift
@MainActor
func getPointsByCategory(
    repository: QuestionRepository
) async -> [QuestionCategory: Int] {
    var categoryPoints: [QuestionCategory: Int] = [:]
    
    guard let progress = try? await repository.getAllUserProgress() else {
        return categoryPoints
    }
    
    for record in progress {
        guard let question = try? await repository.getQuestionById(record.questionId) else {
            continue
        }
        
        let category = question.category
        categoryPoints[category, default: 0] += record.pointsEarned
    }
    
    return categoryPoints
}
```

## Testing Helpers

### Create Mock Question for Testing

```swift
extension Question {
    static func mock(
        text: String = "Test question?",
        correctAnswer: String = "Test answer",
        points: Int = 1000,
        type: QuestionType = .multipleChoice
    ) -> Question {
        Question(
            text: text,
            correctAnswer: correctAnswer,
            basePoints: points,
            category: .general,
            difficulty: .easy,
            questionType: type,
            options: type == .multipleChoice ? ["A", "B", "C", "D"] : nil,
            availableDate: Date()
        )
    }
}
```

### Mock ViewModel for Previews

```swift
extension QuestionViewModel {
    static func mockAvailable() -> QuestionViewModel {
        let vm = QuestionViewModel(
            gameManager: mockGameManager(),
            squadId: UUID()
        )
        vm.currentQuestion = .mock()
        vm.questionState = .available
        return vm
    }
    
    static func mockLocked() -> QuestionViewModel {
        let vm = QuestionViewModel(
            gameManager: mockGameManager(),
            squadId: UUID()
        )
        vm.currentQuestion = .mock()
        vm.questionState = .locked(timeRemaining: 3600)
        vm.timeRemaining = 3600
        return vm
    }
}
```

## Integration with Other Features

### Award Bonus Points for Streak

```swift
@MainActor
func checkAndAwardStreak(
    repository: QuestionRepository,
    squadId: UUID,
    gameManager: GameManager
) async {
    guard let progress = try? await repository.getAllUserProgress() else {
        return
    }
    
    // Sort by date
    let sorted = progress.sorted { $0.lastAnswerDate > $1.lastAnswerDate }
    
    // Check for consecutive days
    var streak = 0
    var lastDate = Date()
    
    for record in sorted {
        let daysDiff = Calendar.current.dateComponents(
            [.day],
            from: record.lastAnswerDate,
            to: lastDate
        ).day ?? 0
        
        if daysDiff <= 1 && record.isCorrect {
            streak += 1
            lastDate = record.lastAnswerDate
        } else {
            break
        }
    }
    
    // Award bonus for streaks
    if streak >= 7 {
        let bonus = 1000 * streak
        try? await gameManager.awardPointsToSquad(squadId: squadId, points: bonus)
        print("🔥 \(streak) day streak! Bonus: \(bonus) points")
    }
}
```

## Error Handling Best Practices

### Comprehensive Error Handling

```swift
@MainActor
func safeSubmitAnswer(
    gameManager: GameManager,
    question: Question,
    squadId: UUID,
    answer: String
) async -> Result<(Bool, Int), Error> {
    do {
        let result = try await gameManager.submitAnswer(
            question: question,
            userAnswer: answer,
            squadId: squadId
        )
        return .success(result)
    } catch RepositoryError.notFound {
        print("Squad not found")
        return .failure(RepositoryError.notFound)
    } catch RepositoryError.invalidData {
        print("Question not available")
        return .failure(RepositoryError.invalidData)
    } catch {
        print("Unexpected error: \(error)")
        return .failure(error)
    }
}
```

These examples demonstrate the flexibility and power of the Question of the Day system. You can easily extend and customize it to fit your specific needs!
