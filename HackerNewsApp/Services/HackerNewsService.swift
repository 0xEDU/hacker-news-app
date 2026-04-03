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
    private let searchBaseURL = "https://hn.algolia.com/api/v1/search"
    private let storyCount = 30
    private let session: URLSession
    private var topStoriesCache: [Story] = []
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
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
            let sortedStories = fetchedStories.sorted { (idOrder[$0.id] ?? 0) < (idOrder[$1.id] ?? 0) }
            stories = sortedStories
            topStoriesCache = sortedStories
            
        } catch let hnError as HackerNewsError {
            error = hnError
        } catch {
            self.error = .networkError(error)
        }
        
        isLoading = false
    }

    func searchStories(query: String) async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            restoreTopStories()
            return
        }

        isLoading = true
        error = nil

        do {
            stories = try await fetchSearchStories(query: trimmedQuery)
        } catch let hnError as HackerNewsError {
            error = hnError
        } catch {
            self.error = .networkError(error)
        }

        isLoading = false
    }

    func restoreTopStories() {
        error = nil
        if !topStoriesCache.isEmpty {
            stories = topStoriesCache
        }
    }
    
    private func fetchStoryIDs() async throws -> [Int] {
        guard let url = URL(string: "\(baseURL)/topstories.json") else {
            throw HackerNewsError.invalidURL
        }
        
        do {
            let (data, _) = try await session.data(from: url)
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

    private func fetchSearchStories(query: String) async throws -> [Story] {
        var components = URLComponents(string: searchBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "tags", value: "story")
        ]

        guard let url = components?.url else {
            throw HackerNewsError.invalidURL
        }

        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(SearchResponse.self, from: data)
            return response.hits.compactMap { $0.asStory }
        } catch let error as DecodingError {
            throw HackerNewsError.decodingError(error)
        } catch {
            throw HackerNewsError.networkError(error)
        }
    }
    
    private func fetchStory(id: Int) async throws -> Story {
        guard let url = URL(string: "\(baseURL)/item/\(id).json") else {
            throw HackerNewsError.invalidURL
        }
        
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(Story.self, from: data)
    }
    
    // MARK: - Comments
    
    /// Fetches a single comment by ID
    func fetchComment(id: Int) async throws -> Comment? {
        guard let url = URL(string: "\(baseURL)/item/\(id).json") else {
            throw HackerNewsError.invalidURL
        }
        
        let (data, _) = try await session.data(from: url)
        
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

private struct SearchResponse: Decodable {
    let hits: [SearchHit]
}

private struct SearchHit: Decodable {
    let objectID: String
    let title: String?
    let storyTitle: String?
    let url: String?
    let storyURL: String?
    let points: Int?
    let author: String?
    let createdAtI: Int?
    let numComments: Int?

    var asStory: Story? {
        guard let id = Int(objectID) else {
            return nil
        }

        return Story(
            id: id,
            title: title ?? storyTitle ?? "Untitled",
            url: url ?? storyURL,
            score: points ?? 0,
            by: author ?? "unknown",
            time: createdAtI ?? 0,
            descendants: numComments,
            kids: nil,
            type: "story"
        )
    }

    enum CodingKeys: String, CodingKey {
        case objectID
        case title
        case storyTitle = "story_title"
        case url
        case storyURL = "story_url"
        case points
        case author
        case createdAtI = "created_at_i"
        case numComments = "num_comments"
    }
}
