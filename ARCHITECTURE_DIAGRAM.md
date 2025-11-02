# Question of the Day - Architecture Diagram

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         UI LAYER (SwiftUI)                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐    ┌──────────────────┐    ┌───────────────┐ │
│  │  EarnView    │───▶│ QuestionAnswer   │───▶│ QuestionResult│ │
│  │              │    │     View         │    │     View      │ │
│  └──────┬───────┘    └──────────────────┘    └───────────────┘ │
│         │                                                         │
│         │ uses                                                    │
│         ▼                                                         │
│  ┌──────────────┐                                               │
│  │  EarnCard    │  (displays: available/locked/answered)        │
│  └──────────────┘                                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ @State / @Environment
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    VIEWMODEL LAYER (@Observable)                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐    │
│  │          QuestionViewModel                             │    │
│  │  ┌──────────────────────────────────────────────────┐ │    │
│  │  │  State Management:                               │ │    │
│  │  │  • currentQuestion: Question?                    │ │    │
│  │  │  • questionState: QuestionState                  │ │    │
│  │  │  • userAnswer: String                            │ │    │
│  │  │  • timeRemaining: TimeInterval                   │ │    │
│  │  │  • showResult: Bool                              │ │    │
│  │  └──────────────────────────────────────────────────┘ │    │
│  │                                                         │    │
│  │  ┌──────────────────────────────────────────────────┐ │    │
│  │  │  Operations:                                     │ │    │
│  │  │  • loadTodaysQuestion()                          │ │    │
│  │  │  • submitAnswer()                                │ │    │
│  │  │  • Timer management (1s intervals)               │ │    │
│  │  └──────────────────────────────────────────────────┘ │    │
│  └────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ delegates to
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  BUSINESS LOGIC LAYER                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐    │
│  │              GameManager                               │    │
│  │  ┌──────────────────────────────────────────────────┐ │    │
│  │  │  Game Mechanics:                                 │ │    │
│  │  │  • getQuestionState(for:) → QuestionState       │ │    │
│  │  │  • getTodaysQuestion() → (Question, State)?     │ │    │
│  │  │  • submitAnswer(...) → (isCorrect, points)      │ │    │
│  │  │  • awardPointsToSquad(squadId, points)          │ │    │
│  │  └──────────────────────────────────────────────────┘ │    │
│  │                                                         │    │
│  │  ┌──────────────────────────────────────────────────┐ │    │
│  │  │  Timer Logic:                                    │ │    │
│  │  │  • 24-hour reset mechanism                       │ │    │
│  │  │  • Configurable reset hour (default: 0 UTC)     │ │    │
│  │  │  • getTimeUntilNextReset() → TimeInterval       │ │    │
│  │  │  • formatTimeRemaining() → String               │ │    │
│  │  └──────────────────────────────────────────────────┘ │    │
│  └────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                    │                        │
                    │                        │
          ┌─────────┴────────┐      ┌───────┴──────────┐
          ▼                  ▼      ▼                  ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ QuestionRepo    │  │  SquadRepo      │  │  ModelContext   │
│ (protocol)      │  │  (protocol)     │  │  (SwiftData)    │
└────────┬────────┘  └────────┬────────┘  └────────┬────────┘
         │                    │                     │
         ▼                    ▼                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                    REPOSITORY LAYER                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐    │
│  │     SwiftDataQuestionRepository                        │    │
│  │  ┌──────────────────────────────────────────────────┐ │    │
│  │  │  Question Operations:                            │ │    │
│  │  │  • createQuestion(_:)                            │ │    │
│  │  │  • getTodaysQuestion() → Question?              │ │    │
│  │  │  • getAllQuestions() → [Question]               │ │    │
│  │  │  • getQuestionsByCategory(_:) → [Question]      │ │    │
│  │  └──────────────────────────────────────────────────┘ │    │
│  │                                                         │    │
│  │  ┌──────────────────────────────────────────────────┐ │    │
│  │  │  Progress Operations:                            │ │    │
│  │  │  • recordAnswer(...)                             │ │    │
│  │  │  • getUserProgress(for:) → Progress?            │ │    │
│  │  │  • hasAnsweredToday(questionId:) → Bool         │ │    │
│  │  │  • getTotalPointsEarned() → Int                 │ │    │
│  │  └──────────────────────────────────────────────────┘ │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐    │
│  │     SwiftDataSquadRepository                           │    │
│  │  ┌──────────────────────────────────────────────────┐ │    │
│  │  │  • updateSquad(_:)  [used for earnedCoins]      │ │    │
│  │  └──────────────────────────────────────────────────┘ │    │
│  └────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ persists to
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      DATA LAYER (SwiftData)                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────┐         ┌──────────────────────────┐      │
│  │   Question      │         │  UserQuestionProgress    │      │
│  ├─────────────────┤         ├──────────────────────────┤      │
│  │ id: UUID        │         │ id: UUID                 │      │
│  │ text: String    │         │ questionId: UUID         │      │
│  │ correctAnswer   │         │ lastAnswerDate: Date     │      │
│  │ basePoints: Int │◀────────│ isCorrect: Bool          │      │
│  │ category        │         │ pointsEarned: Int        │      │
│  │ difficulty      │         │ userAnswer: String?      │      │
│  │ questionType    │         └──────────────────────────┘      │
│  │ options: [Str]? │                                            │
│  │ availableDate   │                                            │
│  │ isActive: Bool  │         ┌──────────────────────────┐      │
│  └─────────────────┘         │  Squad (Modified)        │      │
│                               ├──────────────────────────┤      │
│                               │ ...existing fields       │      │
│                               │ earnedCoins: Double ◀────┤      │
│                               │ currentBudget computed   │      │
│                               └──────────────────────────┘      │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow Diagrams

### User Answering a Question

```
┌─────────────┐
│  User Taps  │
│  EarnCard   │
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│ EarnView presents   │
│ sheet with          │
│ QuestionAnswerView  │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ User selects/types  │
│ answer              │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────────────┐
│ QuestionViewModel           │
│ .submitAnswer()             │
└──────┬──────────────────────┘
       │
       ▼
┌─────────────────────────────┐
│ GameManager                 │
│ .submitAnswer(...)          │
│   ├─ Validate state         │
│   ├─ Check answer           │
│   ├─ Record progress        │
│   └─ Award points if correct│
└──────┬──────────────────────┘
       │
       ├─────────────────────────┐
       │                         │
       ▼                         ▼
┌──────────────────┐    ┌───────────────────┐
│ QuestionRepo     │    │ SquadRepo         │
│ .recordAnswer()  │    │ .updateSquad()    │
└──────┬───────────┘    └────────┬──────────┘
       │                         │
       ▼                         ▼
┌──────────────────┐    ┌───────────────────┐
│ SwiftData saves  │    │ Squad.earnedCoins │
│ UserProgress     │    │ += points         │
└──────────────────┘    └───────────────────┘
       │
       ▼
┌─────────────────────┐
│ QuestionResultView  │
│ shows result        │
│ (correct/incorrect) │
└─────────────────────┘
```

### Question State Determination

```
┌───────────────────────┐
│ GameManager           │
│ .getQuestionState()   │
└──────────┬────────────┘
           │
           ▼
┌──────────────────────────────┐
│ Check if answered today?     │
│ (QuestionRepo)               │
└──────┬────────────────┬──────┘
       │ YES            │ NO
       ▼                ▼
┌────────────┐   ┌─────────────────────┐
│ ANSWERED   │   │ Check availableDate │
└────────────┘   └──────┬──────────────┘
                        │
           ┌────────────┼────────────┐
           │            │            │
       FUTURE       TODAY         PAST
           │            │            │
           ▼            ▼            ▼
    ┌────────────┐ ┌───────────┐ ┌────────────┐
    │ LOCKED     │ │ AVAILABLE │ │ LOCKED     │
    │ (timer)    │ │           │ │ (expired)  │
    └────────────┘ └───────────┘ └────────────┘
```

### Timer Updates

```
┌──────────────────────┐
│ QuestionViewModel    │
│ .onAppear()          │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Start Timer          │
│ (1 second interval)  │
└──────────┬───────────┘
           │
           ▼
    ┌──────────────┐
    │ Every 1s:    │
    │ updateTimer()│
    └──────┬───────┘
           │
           ▼
┌──────────────────────┐
│ timeRemaining -= 1   │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐     NO
│ timeRemaining == 0?  ├─────────┐
└──────┬───────────────┘         │
       │ YES                     │
       ▼                         │
┌──────────────────────┐         │
│ loadTodaysQuestion() │         │
└──────────────────────┘         │
                                 │
       ┌─────────────────────────┘
       │
       ▼
┌──────────────────────┐
│ Update UI            │
│ (SwiftUI automatic)  │
└──────────────────────┘
```

## Question State Machine

```
                    ┌─────────────┐
                    │   LOCKED    │
                    │  (future)   │
                    └──────┬──────┘
                           │
                    Time passes
                           │
                           ▼
                    ┌─────────────┐
                    │  AVAILABLE  │◀─────┐
                    └──────┬──────┘      │
                           │             │
                    User answers         │
                           │             │
                           ▼             │
                    ┌─────────────┐     │
                    │  ANSWERED   │     │
                    └──────┬──────┘     │
                           │            │
                    24 hours pass       │
                           │            │
                           └────────────┘
                     (reset at midnight UTC)
```

## Component Dependencies

```
EarnView
  ├─ depends on: QuestionViewModel
  ├─ uses: EarnCard
  ├─ presents: QuestionAnswerView
  └─ presents: QuestionResultView

QuestionViewModel
  ├─ depends on: GameManager
  └─ uses: Timer

GameManager
  ├─ depends on: QuestionRepository
  ├─ depends on: SquadRepository
  └─ depends on: ModelContext

QuestionRepository (protocol)
  └─ implemented by: SwiftDataQuestionRepository

SquadRepository (protocol)
  └─ implemented by: SwiftDataSquadRepository

SwiftDataQuestionRepository
  └─ depends on: ModelContext

SwiftDataSquadRepository
  └─ depends on: ModelContext

ModelContext
  ├─ manages: Question
  ├─ manages: UserQuestionProgress
  └─ manages: Squad
```

## Integration Points with Existing System

```
Existing System                New System
───────────────                ──────────

┌────────────┐                ┌─────────────┐
│   Squad    │◀───modified────│ earnedCoins │
└────────────┘                └─────────────┘
       │
       │ used by
       ▼
┌──────────────┐              ┌──────────────┐
│ SquadRepo    │◀────used─────│ GameManager  │
└──────────────┘              └──────────────┘

┌──────────────┐              ┌──────────────┐
│ SwiftData    │◀────used─────│ QuestionRepo │
│ Manager      │              └──────────────┘
└──────────────┘

┌──────────────┐              ┌──────────────┐
│ Repository   │◀────used─────│ All repos    │
│ Error        │              │ & managers   │
└──────────────┘              └──────────────┘

┌──────────────┐              ┌──────────────┐
│ EarnView     │◀───enhanced──│ ViewModel    │
│              │              │ integration  │
└──────────────┘              └──────────────┘

┌──────────────┐              ┌──────────────┐
│ EarnCard     │◀───enhanced──│ State mgmt   │
│              │              │ & timer      │
└──────────────┘              └──────────────┘
```

This architecture provides:
- ✅ Clear separation of concerns
- ✅ Testability at each layer
- ✅ Reusable components
- ✅ Easy to extend
- ✅ Follows existing patterns
