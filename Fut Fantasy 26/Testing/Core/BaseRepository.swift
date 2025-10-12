//
//  BaseRepository.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import Foundation
import SwiftData

/// Generic repository pattern for SwiftData models
class BaseRepository<T: PersistentModel> {
    let contextProvider: ModelContextProvider
    let mainContext: ModelContext
    
    init(contextProvider: ModelContextProvider) {
        self.contextProvider = contextProvider
        self.mainContext = contextProvider.createMainContext()
    }
    
    // MARK: - Basic Operations
    
    func fetchAll(sortBy sortDescriptors: [SortDescriptor<T>] = []) throws -> [T] {
        var descriptor = FetchDescriptor<T>()
        descriptor.sortBy = sortDescriptors
        return try mainContext.fetch(descriptor)
    }
    
    func fetch(with predicate: Predicate<T>, sortBy sortDescriptors: [SortDescriptor<T>] = []) throws -> [T] {
        let descriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortDescriptors)
        return try mainContext.fetch(descriptor)
    }
    
    // --- THE BROKEN NSPREDICATE METHOD IS GONE ---

    func fetchOne(with predicate: Predicate<T>) throws -> T? {
        var descriptor = FetchDescriptor<T>(predicate: predicate)
        descriptor.fetchLimit = 1
        let results = try mainContext.fetch(descriptor)
        return results.first
    }

    // --- THIS IS THE ONLY METHOD WE NEED FOR DYNAMIC QUERIES ---
    func fetchWithPagination(
        predicate: Predicate<T>? = nil,
        sortBy sortDescriptors: [SortDescriptor<T>] = [],
        limit: Int,
        offset: Int
    ) throws -> [T] {
        var descriptor = FetchDescriptor<T>()
        descriptor.predicate = predicate // This correctly accepts an optional Predicate<T>
        descriptor.sortBy = sortDescriptors
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        
        return try mainContext.fetch(descriptor)
    }
    
    func insert(_ item: T) {
        mainContext.insert(item)
        try? mainContext.save()
    }
    
    func delete(_ item: T) {
        mainContext.delete(item)
        try? mainContext.save()
    }
    
    func batchDelete(_ items: [T]) {
        contextProvider.performTransaction(in: mainContext) { context in
            for item in items {
                context.delete(item)
            }
        }
    }
    
    func batchInsert(_ items: [T]) {
        contextProvider.performBackgroundTask { context in
            for item in items {
                context.insert(item)
            }
        }
    }
}
