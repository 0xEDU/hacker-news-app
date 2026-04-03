import Foundation

@MainActor
final class StoryListViewModel: ObservableObject {
    @Published private(set) var stories: [Story] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: HackerNewsErrorEnum?
    @Published private(set) var searchText = ""

    private let service: HackerNewsServing
    private let storyLimit: Int
    private var topStoriesCache: [Story] = []
    private var searchTask: Task<Void, Never>?
    private var hasLoadedInitialStories = false

    init(service: HackerNewsServing = HackerNewsService(), storyLimit: Int = 30) {
        self.service = service
        self.storyLimit = storyLimit
    }

    deinit {
        searchTask?.cancel()
    }

    func loadStoriesIfNeeded() async {
        guard !hasLoadedInitialStories else { return }
        hasLoadedInitialStories = true
        await refreshStories()
    }

    func refreshStories() async {
        searchTask?.cancel()
        await loadTopStories()
    }

    func updateSearchText(_ newValue: String) {
        searchText = newValue
        searchTask?.cancel()

        let trimmedQuery = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            error = nil
            stories = topStoriesCache
            return
        }

        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await self?.performSearch(query: trimmedQuery)
        }
    }

    func makeCommentsViewModel() -> CommentsViewModel {
        CommentsViewModel(service: service)
    }

    private func loadTopStories() async {
        isLoading = true
        error = nil

        do {
            let fetchedStories = try await service.fetchTopStories(limit: storyLimit)
            stories = fetchedStories
            topStoriesCache = fetchedStories
        } catch let hnError as HackerNewsErrorEnum {
            error = hnError
        } catch let fetchError {
            error = .networkError(fetchError)
        }

        isLoading = false
    }

    private func performSearch(query: String) async {
        isLoading = true
        error = nil

        do {
            stories = try await service.searchStories(query: query, limit: storyLimit)
        } catch let hnError as HackerNewsErrorEnum {
            error = hnError
        } catch let searchError {
            error = .networkError(searchError)
        }

        isLoading = false
    }
}
