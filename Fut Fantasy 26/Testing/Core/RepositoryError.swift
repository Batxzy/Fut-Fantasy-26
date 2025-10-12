//
//  RepositoryError.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//

import Foundation

enum RepositoryError: LocalizedError {
    case saveFailed(underlyingError: Error? = nil)
    case fetchFailed(underlyingError: Error? = nil)
    case deleteFailed(underlyingError: Error? = nil)
    case updateFailed(underlyingError: Error? = nil)
    case notFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            if let error = error {
                return "Failed to save data: \(error.localizedDescription)"
            }
            return "Failed to save data"
            
        case .fetchFailed(let error):
            if let error = error {
                return "Failed to fetch data: \(error.localizedDescription)"
            }
            return "Failed to fetch data"
            
        case .deleteFailed(let error):
            if let error = error {
                return "Failed to delete data: \(error.localizedDescription)"
            }
            return "Failed to delete data"
            
        case .updateFailed(let error):
            if let error = error {
                return "Failed to update data: \(error.localizedDescription)"
            }
            return "Failed to update data"
            
        case .notFound:
            return "Item not found"
            
        case .invalidData:
            return "Invalid data provided"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .saveFailed:
            return "Please check your storage permissions and try again."
        case .fetchFailed:
            return "Please check your connection and try again."
        case .deleteFailed:
            return "The item might already be deleted. Try refreshing."
        case .updateFailed:
            return "Please try updating again."
        case .notFound:
            return "The item you're looking for doesn't exist."
        case .invalidData:
            return "Please check your input and try again."
        }
    }
}
