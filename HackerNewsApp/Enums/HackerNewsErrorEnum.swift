//
//  HackerNewsErrorEnum.swift
//  HackerNewsApp
//
//  Created by Eduardo Tachotte on 03/04/26.
//

import Foundation

enum HackerNewsErrorEnum: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}
