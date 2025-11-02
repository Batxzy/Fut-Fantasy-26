//
//  EarnViwe.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 02/11/25.
//

import SwiftUI
import SwiftData

struct EarnView: View {
    
    @Query private var squads: [Squad]
    @Environment(\.modelContext) private var modelContext
    @State private var questionViewModel: QuestionViewModel?
    @State private var showQuestionSheet = false
    
    var squad: Squad? {
        squads.first
    }
    
    var body: some View {
        ZStack {
            Color(.mainBg)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                  
                    if let squad = squad {
                        Earnheader(squad: squad)
                    }
                    // Question Cards
                    VStack(spacing: 18) {
                        // Card 1 - Question of the Day
                        if let viewModel = questionViewModel {
                            questionOfTheDayCard(viewModel: viewModel)
                        } else {
                            // Placeholder while loading
                            EarnCard(
                                question: "Loading question...",
                                points: 0,
                                isEnabled: false,
                                backgroundColor: .wpBlueOcean,
                                accentColor: .wpMint,
                                foregroundIcon: AnyView(IconQuestionmark())
                            )
                        }
                        
                        // Card 2 - Purple
                        EarnCard(
                            title:"Predictions",
                            question: "Who will win the next match?",
                            points: 8000,
                            backgroundColor: .wpPurpleDeep,
                            accentColor: .wpGreenLime,
                            backgroundIconColor: .wpPurpleLilac,
                            foregroundIcon:   AnyView(
                                Image("Throphy")
                                    .resizable()
                                    .scaledToFit()
                            ),
                            foregroundIconScale: 0.8,
                            foregroundIconRenderingMode: .masked
                            
                        )
                        
                        // Card 3 - Green
                        EarnCard(
                            
                            title:"RECREATE THE POSE",
                            question: "Recreate Mbappé’s crossed-arms pose",
                            points: 1000,
                            backgroundColor: .wpRedBright,
                            accentColor: .wpGreenLime,
                            foregroundIcon: AnyView(
                                Image("LaCabra")
                                    .resizable()
                                    .scaledToFit()
                            ),
                            foregroundIconScale: 1.5,
                            foregroundIconRenderingMode: .masked
                        )
                        
                        // Card 4 - Red/Orange
                        EarnCard(
                            title:"location",
                            question: "Go paste some stickers on the Estadio Arkon",
                            points: 1500,
                            backgroundColor: .wpGreenMalachite,
                            accentColor: .wpBlueOcean,
                            backgroundIconColor: .wpGreenYellow,
                            foregroundIcon: AnyView(
                                Image("PinPoint")
                                    .resizable()
                                    .scaledToFit()
                                
                            ),
                            foregroundIconScale: 0.76,
                            foregroundIconRenderingMode: .masked
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .task {
            if let squad = squad, questionViewModel == nil {
                questionViewModel = QuestionViewModel.create(
                    modelContext: modelContext,
                    squadId: squad.id
                )
                await questionViewModel?.onAppear()
            }
        }
        .onDisappear {
            questionViewModel?.onDisappear()
        }
        .sheet(isPresented: $showQuestionSheet) {
            if let viewModel = questionViewModel, let question = viewModel.currentQuestion {
                VStack {
                    if viewModel.showResult, let result = viewModel.lastResult {
                        QuestionResultView(
                            isCorrect: result.isCorrect,
                            pointsEarned: result.pointsEarned,
                            onDismiss: {
                                showQuestionSheet = false
                                viewModel.dismissResult()
                            }
                        )
                    } else {
                        QuestionAnswerView(
                            question: question,
                            userAnswer: $questionViewModel!.userAnswer,
                            onSubmit: {
                                Task {
                                    await viewModel.submitAnswer()
                                }
                            },
                            isLoading: viewModel.isLoading
                        )
                    }
                }
                .presentationDetents([.medium, .large])
            }
        }
    }
    
    // MARK: - Question of the Day Card
    
    @ViewBuilder
    private func questionOfTheDayCard(viewModel: QuestionViewModel) -> some View {
        EarnCard(
            question: viewModel.currentQuestion?.text ?? "Check back tomorrow!",
            points: viewModel.currentQuestion?.totalPoints ?? 0,
            action: {
                if viewModel.isQuestionAvailable {
                    showQuestionSheet = true
                }
            },
            isEnabled: viewModel.isQuestionAvailable,
            countdownText: viewModel.isQuestionLocked ? viewModel.formattedTimeRemaining : nil,
            isAnswered: viewModel.isQuestionAnswered,
            backgroundColor: .wpBlueOcean,
            accentColor: .wpMint,
            foregroundIcon: AnyView(IconQuestionmark())
        )
    }
}

private func Earnheader(squad: Squad) -> some View {
    HStack {
        VStack(alignment: .leading, spacing: 4) {
            Text("Earn more Coins")
                .font(.system(size: 28, weight: .regular))
                .fontWidth(.condensed)
                .foregroundStyle(.white)
            Text("Complete challenges!")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.white)
                .fontWidth(.condensed)
            
        }
        
        Spacer()
        
        VStack(alignment: .trailing, spacing: 4) {
            Text("Budget")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.white)
            
            HStack(spacing: 3) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.white)
                
                Text(squad.displayBudgetNoDecimals)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
    }
    .padding(.horizontal, 26)
    .padding(.top,12)
}



#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container: ModelContainer
    
    do {
        container = try ModelContainer(
            for: Player.self, Squad.self,
            configurations: config
        )
    } catch {
        fatalError("Failed to create preview container")
    }
    
    let context = container.mainContext
    WorldCupDataSeeder.seedDataIfNeeded(context: context)
    
    let squad = Squad(teamName: "Preview Team", ownerName: "Preview")
    context.insert(squad)
    
    let fetchDescriptor = FetchDescriptor<Player>(
        sortBy: [SortDescriptor(\.totalPoints, order: .reverse)]
    )
    
    if let allPlayers = try? context.fetch(fetchDescriptor) {
        squad.players = Array(allPlayers.prefix(15))
    }
    
    try? context.save()
    
    return EarnView()
        .modelContainer(container)
}
