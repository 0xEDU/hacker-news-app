import SwiftUI

// MARK: - View

struct StoryListView: View {
    @StateObject private var viewModel = StoryListViewModel()
    @State private var searchText = ""
    @State private var searchTask: Task<Void, Never>?
    
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
            .searchable(text: $searchText, prompt: "Search stories")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task {
                            await viewModel.fetchTopStories()
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
            await viewModel.fetchTopStories()
        }
        .onChange(of: searchText) {
            searchTask?.cancel()
            searchTask = Task {
                try? await Task.sleep(nanoseconds: 350_000_000)
                guard !Task.isCancelled else { return }
                await viewModel.searchStories(query: searchText)
            }
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
                    await viewModel.fetchTopStories()
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
                    StoryCardView(story: story)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom)
        }
        .refreshable {
            await viewModel.fetchTopStories()
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28))
                .foregroundColor(.secondary)
            Text(searchText.isEmpty ? "No stories available" : "No stories found")
                .font(.headline)
            Text(searchText.isEmpty
                ? "Try refreshing to fetch the latest stories."
                : "Try a different search term.")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - ViewModel

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
        } catch let err {
            error = .networkError(err)
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
        } catch let err {
            error = .networkError(err)
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

// MARK: - Preview

#Preview {
    StoryListView()
}
