import Foundation

@MainActor
final class StoryListViewModel: ObservableObject {
    @Published private(set) var stories: [Story] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var error: HackerNewsErrorEnum?
    @Published private(set) var searchText = ""

    private let service: HackerNewsServing
    private let storyLimit: Int
    private var topStoriesCache: [Story] = []
    private var searchTask: Task<Void, Never>?
    private var hasLoadedInitialStories = false
    private var currentTopStoriesPage = 0
    private var currentSearchPage = 0
    private var hasMoreTopStories = true
    private var hasMoreSearchStories = false

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
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedQuery.isEmpty {
            await loadTopStories(reset: true)
        } else {
            await performSearch(query: trimmedQuery, reset: true)
        }
    }

    func loadMoreStoriesIfNeeded(currentStory: Story) async {
        guard currentStory.id == stories.last?.id else { return }
        guard !isLoading, !isLoadingMore else { return }

        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedQuery.isEmpty {
            guard hasMoreTopStories else { return }
            await loadTopStories(reset: false)
        } else {
            guard hasMoreSearchStories else { return }
            await performSearch(query: trimmedQuery, reset: false)
        }
    }

    func updateSearchText(_ newValue: String) {
        searchText = newValue
        searchTask?.cancel()

        let trimmedQuery = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            error = nil
            stories = topStoriesCache
            hasMoreSearchStories = false
            currentSearchPage = 0
            return
        }

        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await self?.performSearch(query: trimmedQuery, reset: true)
        }
    }

    func makeCommentsViewModel() -> CommentsViewModel {
        CommentsViewModel(service: service)
    }

    private func loadTopStories(reset: Bool) async {
        beginLoading(reset: reset)
        let page = reset ? 0 : currentTopStoriesPage + 1

        do {
            let fetchedStories = try await service.fetchTopStories(page: page, limit: storyLimit)
            currentTopStoriesPage = page
            hasMoreTopStories = fetchedStories.count == storyLimit

            if reset {
                stories = fetchedStories
                topStoriesCache = fetchedStories
            } else {
                stories.append(contentsOf: fetchedStories)
                topStoriesCache = stories
            }
        } catch let hnError as HackerNewsErrorEnum {
            error = hnError
        } catch let fetchError {
            error = .networkError(fetchError)
        }

        endLoading(reset: reset)
    }

    private func performSearch(query: String, reset: Bool) async {
        beginLoading(reset: reset)
        let page = reset ? 0 : currentSearchPage + 1

        do {
            let fetchedStories = try await service.searchStories(query: query, page: page, limit: storyLimit)
            currentSearchPage = page
            hasMoreSearchStories = fetchedStories.count == storyLimit

            if reset {
                stories = fetchedStories
            } else {
                stories.append(contentsOf: fetchedStories)
            }
        } catch let hnError as HackerNewsErrorEnum {
            error = hnError
        } catch let searchError {
            error = .networkError(searchError)
        }

        endLoading(reset: reset)
    }

    private func beginLoading(reset: Bool) {
        if reset {
            isLoading = true
        } else {
            isLoadingMore = true
        }
        error = nil
    }

    private func endLoading(reset: Bool) {
        if reset {
            isLoading = false
        } else {
            isLoadingMore = false
        }
    }
}
