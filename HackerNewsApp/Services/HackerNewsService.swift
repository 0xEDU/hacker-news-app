import Foundation

class HackerNewsService {
    private let baseURL = "https://hacker-news.firebaseio.com/v0"
    private let searchBaseURL = "https://hn.algolia.com/api/v1/search"
    private let storyCount = 30
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetchTopStories() async throws -> [Story] {
        // Fetch top story IDs
        let storyIDs = try await fetchStoryIDs()
        
        // Fetch first N stories concurrently
        let limitedIDs = Array(storyIDs.prefix(storyCount))
        let fetchedStories = try await fetchStories(ids: limitedIDs)
        
        // Sort by the original top stories order
        let idOrder = Dictionary(uniqueKeysWithValues: limitedIDs.enumerated().map { ($1, $0) })
        return fetchedStories.sorted { (idOrder[$0.id] ?? 0) < (idOrder[$1.id] ?? 0) }
    }

    func searchStories(query: String) async throws -> [Story] {
        let searchIDs = try await fetchSearchStoryIDs(query: query)
        let fetchedStories = try await fetchStories(ids: searchIDs)
        let idOrder = Dictionary(uniqueKeysWithValues: searchIDs.enumerated().map { ($1, $0) })
        return fetchedStories.sorted { (idOrder[$0.id] ?? 0) < (idOrder[$1.id] ?? 0) }
    }
    
    private func fetchStoryIDs() async throws -> [Int] {
        guard let url = URL(string: "\(baseURL)/topstories.json") else {
            throw HackerNewsErrorEnum.invalidURL
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            let ids = try JSONDecoder().decode([Int].self, from: data)
            return ids
        } catch let error as DecodingError {
            throw HackerNewsErrorEnum.decodingError(error)
        } catch {
            throw HackerNewsErrorEnum.networkError(error)
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

    private func fetchSearchStoryIDs(query: String) async throws -> [Int] {
        var components = URLComponents(string: searchBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "tags", value: "story")
        ]

        guard let url = components?.url else {
            throw HackerNewsErrorEnum.invalidURL
        }

        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(SearchResponse.self, from: data)
            return response.hits.compactMap(\.storyID)
        } catch let error as DecodingError {
            throw HackerNewsErrorEnum.decodingError(error)
        } catch {
            throw HackerNewsErrorEnum.networkError(error)
        }
    }
    
    private func fetchStory(id: Int) async throws -> Story {
        guard let url = URL(string: "\(baseURL)/item/\(id).json") else {
            throw HackerNewsErrorEnum.invalidURL
        }
        
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(Story.self, from: data)
    }
    
    // MARK: - Comments
    
    /// Fetches a single comment by ID
    func fetchComment(id: Int) async throws -> Comment? {
        guard let url = URL(string: "\(baseURL)/item/\(id).json") else {
            throw HackerNewsErrorEnum.invalidURL
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
        let commentDict = Dictionary(uniqueKeysWithValues: comments)

        // Build trees in parallel while preserving original order.
        let indexedTrees = try await withThrowingTaskGroup(of: (Int, CommentTree?).self) { group in
            for (index, id) in ids.enumerated() {
                group.addTask {
                    guard let comment = commentDict[id] ?? nil, comment.isValid else {
                        return (index, nil)
                    }

                    var children: [CommentTree] = []
                    if depth < maxDepth, let kidIDs = comment.kids, !kidIDs.isEmpty {
                        children = (try? await self.fetchCommentTrees(
                            ids: kidIDs,
                            depth: depth + 1,
                            maxDepth: maxDepth
                        )) ?? []
                    }

                    return (index, CommentTree(comment: comment, children: children, depth: depth))
                }
            }

            var results: [(Int, CommentTree?)] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }

        return indexedTrees
            .sorted { $0.0 < $1.0 }
            .compactMap { $0.1 }
    }
}

private struct SearchResponse: Decodable {
    let hits: [SearchHit]
}

private struct SearchHit: Decodable {
    let objectID: String
    var storyID: Int? { Int(objectID) }

    enum CodingKeys: String, CodingKey {
        case objectID
    }
}
