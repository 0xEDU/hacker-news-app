@testable import HackerNewsApp
import XCTest

@MainActor
final class StoryListViewModelTests: XCTestCase {
    func test_loadStoriesIfNeeded_loadsFirstPage() async {
        let service = MockHackerNewsService()
        service.topStoriesPages = [
            0: [makeStory(id: 1), makeStory(id: 2)]
        ]
        let sut = StoryListViewModel(service: service, storyLimit: 2)

        await sut.loadStoriesIfNeeded()

        XCTAssertEqual(sut.stories.map(\.id), [1, 2])
        XCTAssertEqual(service.fetchTopStoriesCalls, [.init(page: 0, limit: 2)])
    }

    func test_loadMoreStoriesIfNeeded_whenCurrentStoryIsLast_loadsNextPage() async {
        let service = MockHackerNewsService()
        service.topStoriesPages = [
            0: [makeStory(id: 1), makeStory(id: 2)],
            1: [makeStory(id: 3), makeStory(id: 4)]
        ]
        let sut = StoryListViewModel(service: service, storyLimit: 2)
        await sut.loadStoriesIfNeeded()

        await sut.loadMoreStoriesIfNeeded(currentStory: sut.stories[1])

        XCTAssertEqual(sut.stories.map(\.id), [1, 2, 3, 4])
        XCTAssertEqual(
            service.fetchTopStoriesCalls,
            [.init(page: 0, limit: 2), .init(page: 1, limit: 2)]
        )
    }

    func test_loadMoreStoriesIfNeeded_whenCurrentStoryIsNotLast_doesNotLoadNextPage() async {
        let service = MockHackerNewsService()
        service.topStoriesPages = [
            0: [makeStory(id: 1), makeStory(id: 2)],
            1: [makeStory(id: 3), makeStory(id: 4)]
        ]
        let sut = StoryListViewModel(service: service, storyLimit: 2)
        await sut.loadStoriesIfNeeded()

        await sut.loadMoreStoriesIfNeeded(currentStory: sut.stories[0])

        XCTAssertEqual(sut.stories.map(\.id), [1, 2])
        XCTAssertEqual(service.fetchTopStoriesCalls, [.init(page: 0, limit: 2)])
    }

    func test_loadMoreStoriesIfNeeded_whenSearchIsActive_loadsNextSearchPage() async {
        let service = MockHackerNewsService()
        service.topStoriesPages = [
            0: [makeStory(id: 1), makeStory(id: 2)]
        ]
        service.searchStoriesPages = [
            "swift": [
                0: [makeStory(id: 10), makeStory(id: 11)],
                1: [makeStory(id: 12), makeStory(id: 13)]
            ]
        ]
        let sut = StoryListViewModel(service: service, storyLimit: 2)
        await sut.loadStoriesIfNeeded()

        sut.updateSearchText("swift")
        try? await Task.sleep(nanoseconds: 400_000_000)
        await Task.yield()
        await sut.loadMoreStoriesIfNeeded(currentStory: sut.stories[1])

        XCTAssertEqual(sut.stories.map(\.id), [10, 11, 12, 13])
        XCTAssertEqual(
            service.searchStoriesCalls,
            [
                .init(query: "swift", page: 0, limit: 2),
                .init(query: "swift", page: 1, limit: 2)
            ]
        )
    }

    private func makeStory(id: Int) -> Story {
        Story(
            id: id,
            title: "Story \(id)",
            url: "https://example.com/\(id)",
            score: id,
            by: "user\(id)",
            time: id,
            descendants: 0,
            kids: nil,
            type: "story"
        )
    }
}

private final class MockHackerNewsService: HackerNewsServing {
    struct TopStoriesCall: Equatable {
        let page: Int
        let limit: Int
    }

    struct SearchStoriesCall: Equatable {
        let query: String
        let page: Int
        let limit: Int
    }

    var topStoriesPages: [Int: [Story]] = [:]
    var searchStoriesPages: [String: [Int: [Story]]] = [:]
    var fetchTopStoriesCalls: [TopStoriesCall] = []
    var searchStoriesCalls: [SearchStoriesCall] = []

    func fetchTopStories(page: Int, limit: Int) async throws -> [Story] {
        fetchTopStoriesCalls.append(TopStoriesCall(page: page, limit: limit))
        return topStoriesPages[page, default: []]
    }

    func searchStories(query: String, page: Int, limit: Int) async throws -> [Story] {
        searchStoriesCalls.append(SearchStoriesCall(query: query, page: page, limit: limit))
        return searchStoriesPages[query]?[page, default: []] ?? []
    }

    func fetchComment(id: Int) async throws -> Comment? {
        nil
    }

    func fetchCommentTrees(for story: Story, maxDepth: Int) async throws -> [CommentTree] {
        []
    }
}
