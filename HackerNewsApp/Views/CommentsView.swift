import SwiftUI

struct CommentsView: View {
    let story: Story
    
    @StateObject private var viewModel = CommentsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            storyHeader
            
            Divider()
            
            // Comments
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.error {
                errorView(error: error)
            } else if viewModel.comments.isEmpty {
                emptyView
            } else {
                commentsList
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .task {
            await viewModel.loadComments(for: story)
        }
    }
    
    private var storyHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(story.title)
                .font(.headline)
                .lineLimit(2)
            
            HStack(spacing: 12) {
                Label("\(story.score)", systemImage: "arrow.up")
                    .foregroundColor(.orange)
                
                Label(story.by, systemImage: "person")
                    .foregroundColor(.secondary)
                
                Label(story.timeAgo, systemImage: "clock")
                    .foregroundColor(.secondary)
                
                Label("\(story.commentCount) comments", systemImage: "bubble.right")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let url = story.storyURL {
                    Button {
                        NSWorkspace.shared.open(url)
                    } label: {
                        Label("Open Article", systemImage: "safari")
                    }
                    .buttonStyle(.borderless)
                }
            }
            .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading comments...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(error: HackerNewsErrorEnum) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundColor(.orange)
            
            Text("Failed to load comments")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("Retry") {
                Task {
                    await viewModel.loadComments(for: story)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            
            Text("No comments yet")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var commentsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.comments) { tree in
                    CommentTreeView(tree: tree)
                }
            }
            .padding()
        }
    }
}

// MARK: - Comment Tree View (recursive)

struct CommentTreeView: View {
    let tree: CommentTree
    
    @State private var isCollapsed = false
    
    private let indentWidth: CGFloat = 16
    private let depthColors: [Color] = [.blue, .green, .orange, .purple, .pink, .cyan]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Comment content
            HStack(alignment: .top, spacing: 8) {
                // Depth indicator
                if tree.depth > 0 {
                    Rectangle()
                        .fill(depthColors[tree.depth % depthColors.count].opacity(0.5))
                        .frame(width: 2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Comment header
                    HStack(spacing: 8) {
                        Text(tree.comment.by ?? "unknown")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(tree.comment.timeAgo)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if !tree.children.isEmpty {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isCollapsed.toggle()
                                }
                            } label: {
                                HStack(spacing: 2) {
                                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                                    Text("\(countAllChildren(tree)) replies")
                                }
                                .font(.caption2)
                                .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Spacer()
                    }
                    
                    // Comment text
                    Text(tree.comment.plainText)
                        .font(.callout)
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.leading, CGFloat(tree.depth) * indentWidth)
            .padding(.vertical, 8)
            
            // Child comments
            if !isCollapsed {
                ForEach(tree.children) { child in
                    CommentTreeView(tree: child)
                }
            }
        }
    }
    
    private func countAllChildren(_ tree: CommentTree) -> Int {
        tree.children.reduce(0) { count, child in
            count + 1 + countAllChildren(child)
        }
    }
}

// MARK: - View Model

@MainActor
class CommentsViewModel: ObservableObject {
    @Published var comments: [CommentTree] = []
    @Published var isLoading = false
    @Published var error: HackerNewsErrorEnum?
    
    private let service = HackerNewsService()
    
    func loadComments(for story: Story) async {
        isLoading = true
        error = nil
        
        do {
            comments = try await service.fetchCommentTrees(for: story, maxDepth: 5)
        } catch let hnError as HackerNewsErrorEnum {
            error = hnError
        } catch {
            self.error = .networkError(error)
        }
        
        isLoading = false
    }
}

#Preview {
    CommentsView(story: Story(
        id: 8863,
        title: "My YC app: Dropbox - Throw away your USB drive",
        url: "http://www.getdropbox.com/u/2/screencast.html",
        score: 104,
        by: "dhouston",
        time: 1175714200,
        descendants: 71,
        kids: [8952, 9224, 8917],
        type: "story"
    ))
}
