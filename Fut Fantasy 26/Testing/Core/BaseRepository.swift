//
//  BaseRepository.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import Foundation
import SwiftData

/// Generic repository pattern for SwiftData models
@MainActor
class BaseRepository<T: PersistentModel> {
    let contextProvider: ModelContextProvider
    let mainContext: ModelContext
    
    init(contextProvider: ModelContextProvider) {
        self.contextProvider = contextProvider
        self.mainContext = contextProvider.createMainContext()
    }
    
    // MARK: - Basic Operations
    
    func fetchAll(sortBy sortDescriptors: [SortDescriptor<T>] = []) async throws -> [T] {
        var descriptor = FetchDescriptor<T>()
        descriptor.sortBy = sortDescriptors
        
        do {
            let results = try mainContext.fetch(descriptor)
            return results
        } catch {
            throw RepositoryError.fetchFailed(underlyingError: error)
        }
    }
    
    func fetch(with predicate: Predicate<T>, sortBy sortDescriptors: [SortDescriptor<T>] = []) async throws -> [T] {
        let descriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortDescriptors)
        
        do {
            let results = try mainContext.fetch(descriptor)
            return results
        } catch {
            throw RepositoryError.fetchFailed(underlyingError: error)
        }
    }

    func fetchOne(with predicate: Predicate<T>) async throws -> T? {
        var descriptor = FetchDescriptor<T>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        do {
            let results = try mainContext.fetch(descriptor)
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
            let results = try mainContext.fetch(descriptor)
            return results
        } catch {
            throw RepositoryError.fetchFailed(underlyingError: error)
        }
    }
    
    func insert(_ item: T) async throws {
        mainContext.insert(item)
        
        do {
            try mainContext.save()
        } catch {
            throw RepositoryError.saveFailed(underlyingError: error)
        }
    }
    
    func delete(_ item: T) async throws {
        mainContext.delete(item)
        
        do {
            try mainContext.save()
        } catch {
            throw RepositoryError.deleteFailed(underlyingError: error)
        }
    }
    
    func update(_ item: T) async throws {
        do {
            try mainContext.save()
        } catch {
            throw RepositoryError.updateFailed(underlyingError: error)
        }
    }
    
    func batchDelete(_ items: [T]) async throws {
        contextProvider.performTransaction(in: mainContext) { context in
            for item in items {
                context.delete(item)
            }
        }
    }
    
    func batchInsert(_ items: [T]) async throws {
        contextProvider.performBackgroundTask { context in
            for item in items {
                context.insert(item)
            }
        }
    }
}
