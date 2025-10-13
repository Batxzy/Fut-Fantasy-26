//
//  BaseRepository.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//

/*
import Foundation
import SwiftData

/// Generic repository pattern for SwiftData models
@MainActor
class BaseRepository<T: PersistentModel> {
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Basic Operations
    
    func fetchAll(sortBy sortDescriptors: [SortDescriptor<T>] = []) async throws -> [T] {
        var descriptor = FetchDescriptor<T>()
        descriptor.sortBy = sortDescriptors
        
        do {
            let results = try modelContext.fetch(descriptor)
            return results
        } catch {
            throw RepositoryError.fetchFailed(underlyingError: error)
        }
    }
    
    func fetch(with predicate: Predicate<T>, sortBy sortDescriptors: [SortDescriptor<T>] = []) async throws -> [T] {
        let descriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortDescriptors)
        
        do {
            let results = try modelContext.fetch(descriptor)
            return results
        } catch {
            throw RepositoryError.fetchFailed(underlyingError: error)
        }
    }

    func fetchOne(with predicate: Predicate<T>) async throws -> T? {
        var descriptor = FetchDescriptor<T>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        do {
            let results = try modelContext.fetch(descriptor)
            return results.first
        } catch {
            throw RepositoryError.fetchFailed(underlyingError: error)
        }
    }

    func fetchWithPagination(
        predicate: Predicate<T>? = nil,
        sortBy sortDescriptors: [SortDescriptor<T>] = [],
        limit: Int,
        offset: Int
    ) async throws -> [T] {
        var descriptor = FetchDescriptor<T>()
        descriptor.predicate = predicate
        descriptor.sortBy = sortDescriptors
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        
        do {
            let results = try modelContext.fetch(descriptor)
            return results
        } catch {
            throw RepositoryError.fetchFailed(underlyingError: error)
        }
    }
    
    func insert(_ item: T) async throws {
        modelContext.insert(item)
        
        do {
            try modelContext.save()
        } catch {
            throw RepositoryError.saveFailed(underlyingError: error)
        }
    }
    
    func delete(_ item: T) async throws {
        modelContext.delete(item)
        
        do {
            try modelContext.save()
        } catch {
            throw RepositoryError.deleteFailed(underlyingError: error)
        }
    }
    
    func update(_ item: T) async throws {
        // The model is already being tracked by the context, just save.
        do {
            try modelContext.save()
        } catch {
            throw RepositoryError.updateFailed(underlyingError: error)
        }
    }
    
    func batchDelete(_ items: [T]) async throws {
        // This functionality is complex with multiple contexts.
        // For a single main context, a simple loop is often sufficient.
        for item in items {
            modelContext.delete(item)
        }
        try modelContext.save()
    }
    
    func batchInsert(_ items: [T]) async throws {
        // For a single main context, a simple loop is fine.
        // For large datasets, use the background task pattern.
        for item in items {
            modelContext.insert(item)
        }
        try modelContext.save()
    }
}

*/
