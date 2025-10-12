//
//  ModelContextProvider.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import Foundation
import SwiftData

// Class to provide controlled access to model contexts
class ModelContextProvider {
    private let container: ModelContainer
    
    init(container: ModelContainer) {
        self.container = container
    }
    
    // Main context for UI operations
    func createMainContext() -> ModelContext {
        let context = ModelContext(container)
        context.autosaveEnabled = true
        return context
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
                // FIX: Added try keyword and error handling
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
            if context.autosaveEnabled == false {
                try context.save()
            }
        } catch {
            print("Error performing transaction: \(error)")
        }
    }
}
