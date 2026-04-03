import SwiftUI

@MainActor
struct StoryListView: View {
    @StateObject private var viewModel: StoryListViewModel

    init() {
        _viewModel = StateObject(wrappedValue: StoryListViewModel())
    }

    init(viewModel: StoryListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.stories.isEmpty {
                    loadingView
                } else if let error = viewModel.error {
                    errorView(error: error)
                } else if viewModel.stories.isEmpty {
                    emptyView
                } else {
                    storyList
                }
            }
            .navigationTitle("Hacker News")
            .searchable(
                text: Binding(
                    get: { viewModel.searchText },
                    set: { viewModel.updateSearchText($0) }
                ),
                prompt: "Search stories"
            )
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task {
                            await viewModel.refreshStories()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                            .animation(
                                viewModel.isLoading
                                    ? .linear(duration: 1).repeatForever(autoreverses: false)
                                    : .default,
                                value: viewModel.isLoading
                            )
                    }
                    .disabled(viewModel.isLoading)
                    .help("Refresh stories")
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .task {
            await viewModel.loadStoriesIfNeeded()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading stories...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(error: HackerNewsErrorEnum) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Failed to load stories")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task {
                    await viewModel.refreshStories()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var storyList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.stories) { story in
                    StoryCardView(
                        story: story,
                        commentsViewModel: viewModel.makeCommentsViewModel()
                    )
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom)
        }
        .refreshable {
            await viewModel.refreshStories()
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28))
                .foregroundColor(.secondary)
            Text(viewModel.searchText.isEmpty ? "No stories available" : "No stories found")
                .font(.headline)
            Text(viewModel.searchText.isEmpty
                ? "Try refreshing to fetch the latest stories."
                : "Try a different search term.")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
struct StoryListView_Previews: PreviewProvider {
    static var previews: some View {
        StoryListView()
    }
}
#endif
