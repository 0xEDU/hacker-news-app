import Foundation

@MainActor
final class CommentsViewModel: ObservableObject {
    @Published private(set) var comments: [CommentTree] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: HackerNewsErrorEnum?

    private let service: HackerNewsServing

    init(service: HackerNewsServing = HackerNewsService()) {
        self.service = service
    }

    func loadComments(for story: Story) async {
        isLoading = true
        error = nil

        do {
            comments = try await service.fetchCommentTrees(for: story, maxDepth: 5)
        } catch let hnError as HackerNewsErrorEnum {
            error = hnError
        } catch let loadError {
            error = .networkError(loadError)
        }

        isLoading = false
    }
}
