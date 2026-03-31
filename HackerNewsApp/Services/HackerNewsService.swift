import Foundation

enum HackerNewsError: Error, LocalizedError {
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

@MainActor
class HackerNewsService: ObservableObject {
    @Published var stories: [Story] = []
    @Published var isLoading = false
    @Published var error: HackerNewsError?
    
    private let baseURL = "https://hacker-news.firebaseio.com/v0"
    private let storyCount = 30
    
    func fetchTopStories() async {
        isLoading = true
        error = nil
        
        do {
            // Fetch top story IDs
            let storyIDs = try await fetchStoryIDs()
            
            // Fetch first N stories concurrently
            let limitedIDs = Array(storyIDs.prefix(storyCount))
            let fetchedStories = try await fetchStories(ids: limitedIDs)
            
            // Sort by the original top stories order
            let idOrder = Dictionary(uniqueKeysWithValues: limitedIDs.enumerated().map { ($1, $0) })
            stories = fetchedStories.sorted { (idOrder[$0.id] ?? 0) < (idOrder[$1.id] ?? 0) }
            
        } catch let hnError as HackerNewsError {
            error = hnError
        } catch {
            self.error = .networkError(error)
        }
        
        isLoading = false
    }
    
    private func fetchStoryIDs() async throws -> [Int] {
        guard let url = URL(string: "\(baseURL)/topstories.json") else {
            throw HackerNewsError.invalidURL
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let ids = try JSONDecoder().decode([Int].self, from: data)
            return ids
        } catch let error as DecodingError {
            throw HackerNewsError.decodingError(error)
        } catch {
            throw HackerNewsError.networkError(error)
        }
    }
    
    private func fetchStories(ids: [Int]) async throws -> [Story] {
        try await withThrowingTaskGroup(of: Story?.self) { group in
            for id in ids {
                group.addTask {
                    try? await self.fetchStory(id: id)
                }
            }
            
            var stories: [Story] = []
            for try await story in group {
                if let story = story {
                    stories.append(story)
                }
            }
            return stories
        }
    }
    
    private func fetchStory(id: Int) async throws -> Story {
        guard let url = URL(string: "\(baseURL)/item/\(id).json") else {
            throw HackerNewsError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(Story.self, from: data)
    }
    
    // MARK: - Comments
    
    /// Fetches a single comment by ID
    func fetchComment(id: Int) async throws -> Comment? {
        guard let url = URL(string: "\(baseURL)/item/\(id).json") else {
            throw HackerNewsError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // Handle null response (deleted comments)
        if let jsonString = String(data: data, encoding: .utf8), jsonString == "null" {
            return nil
        }
        
        return try JSONDecoder().decode(Comment.self, from: data)
    }
    
    /// Fetches comments for a story and builds a tree structure
    func fetchCommentTrees(for story: Story, maxDepth: Int = 3) async throws -> [CommentTree] {
        guard !story.commentIDs.isEmpty else { return [] }
        
        return try await fetchCommentTrees(ids: story.commentIDs, depth: 0, maxDepth: maxDepth)
    }
    
    /// Recursively fetches comments and their children
    private func fetchCommentTrees(ids: [Int], depth: Int, maxDepth: Int) async throws -> [CommentTree] {
        // Fetch all comments at this level concurrently
        let comments = try await withThrowingTaskGroup(of: (Int, Comment?).self) { group in
            for id in ids {
                group.addTask {
                    let comment = try? await self.fetchComment(id: id)
                    return (id, comment)
                }
            }
            
            var results: [(Int, Comment?)] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
        
        // Build trees, maintaining original order
        var trees: [CommentTree] = []
        let commentDict = Dictionary(uniqueKeysWithValues: comments)
        
        for id in ids {
            guard let comment = commentDict[id] ?? nil, comment.isValid else { continue }
            
            var children: [CommentTree] = []
            if depth < maxDepth, let kidIDs = comment.kids, !kidIDs.isEmpty {
                children = (try? await fetchCommentTrees(ids: kidIDs, depth: depth + 1, maxDepth: maxDepth)) ?? []
            }
            
            trees.append(CommentTree(comment: comment, children: children, depth: depth))
        }
        
        return trees
    }
}
