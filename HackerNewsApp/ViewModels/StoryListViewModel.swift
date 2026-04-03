import Foundation

@MainActor
class StoryListViewModel: ObservableObject {
    @Published var stories: [Story] = []
    @Published var isLoading = false
    @Published var error: HackerNewsErrorEnum?
    
    private let service: HackerNewsService
    private var topStoriesCache: [Story] = []
    
    init(service: HackerNewsService = HackerNewsService()) {
        self.service = service
    }
    
    func fetchTopStories() async {
        isLoading = true
        error = nil
        
        do {
            let fetchedStories = try await service.fetchTopStories()
            stories = fetchedStories
            topStoriesCache = fetchedStories
        } catch let hnError as HackerNewsErrorEnum {
            error = hnError
        } catch {
            error = .networkError(error)
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
            stories = try await service.searchStories(query: trimmedQuery)
        } catch let hnError as HackerNewsErrorEnum {
            error = hnError
        } catch {
            error = .networkError(error)
        }
        
        isLoading = false
    }
    
    func restoreTopStories() {
        error = nil
        if !topStoriesCache.isEmpty {
            stories = topStoriesCache
        }
    }
}
