import SwiftUI

struct StoryListView: View {
    @StateObject private var service = HackerNewsService()
    @State private var searchText = ""
    @State private var searchTask: Task<Void, Never>?
    
    var body: some View {
        NavigationStack {
            Group {
                if service.isLoading && service.stories.isEmpty {
                    loadingView
                } else if let error = service.error {
                    errorView(error: error)
                } else if service.stories.isEmpty {
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
                            await service.fetchTopStories()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(service.isLoading ? 360 : 0))
                            .animation(
                                service.isLoading 
                                    ? .linear(duration: 1).repeatForever(autoreverses: false)
                                    : .default,
                                value: service.isLoading
                            )
                    }
                    .disabled(service.isLoading)
                    .help("Refresh stories")
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .task {
            await service.fetchTopStories()
        }
        .onChange(of: searchText) {
            searchTask?.cancel()
            searchTask = Task {
                try? await Task.sleep(nanoseconds: 350_000_000)
                guard !Task.isCancelled else { return }
                await service.searchStories(query: searchText)
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
    
    private func errorView(error: HackerNewsError) -> some View {
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
                    await service.fetchTopStories()
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
                ForEach(service.stories) { story in
                    StoryCardView(story: story)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom)
        }
        .refreshable {
            await service.fetchTopStories()
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

#Preview {
    StoryListView()
}
