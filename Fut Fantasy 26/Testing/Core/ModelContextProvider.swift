//
//  ModelContextProvider.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//

/*
import Foundation
import SwiftData

class ModelContextProvider {
    private let container: ModelContainer
    
    // Create a single main context to be shared.
    lazy var mainContext: ModelContext = {
        let context = ModelContext(container)
        context.autosaveEnabled = true
        return context
    }()
    
    init(container: ModelContainer) {
        self.container = container
    }
    
    // Background context for heavy operations
    func createBackgroundContext() -> ModelContext {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }
    
    // Execute in background
    func performBackgroundTask(_ task: @escaping (ModelContext) -> Void) {
        let backgroundContext = createBackgroundContext()
        
        Task.detached {
            task(backgroundContext)
            do {
                try backgroundContext.save()
            } catch {
                print("Error saving background context: \(error)")
            }
        }
    }
    
    // Execute atomic transaction
    func performTransaction(in context: ModelContext, _ transaction: @escaping (ModelContext) -> Void) {
        do {
            try context.transaction {
                transaction(context)
            }
            // Optionally, explicitly save after transaction if autosave is disabled
            if !context.autosaveEnabled {
                try context.save()
            }
        } catch {
            print("Error performing transaction: \(error)")
        }
    }
}

*/
