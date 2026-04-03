import Foundation

@MainActor
class CommentsViewModel: ObservableObject {
    @Published var comments: [CommentTree] = []
    @Published var isLoading = false
    @Published var error: HackerNewsErrorEnum?
    
    private let service: HackerNewsService
    
    init(service: HackerNewsService = HackerNewsService()) {
        self.service = service
    }
    
    func loadComments(for story: Story) async {
        isLoading = true
        error = nil
        
        do {
            comments = try await service.fetchCommentTrees(for: story, maxDepth: 5)
        } catch let hnError as HackerNewsErrorEnum {
            error = hnError
        } catch {
            error = .networkError(error)
        }
        
        isLoading = false
    }
}
