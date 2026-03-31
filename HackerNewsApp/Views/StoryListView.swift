import SwiftUI

struct StoryListView: View {
    @StateObject private var service = HackerNewsService()
    
    var body: some View {
        Group {
            if service.isLoading && service.stories.isEmpty {
                loadingView
            } else if let error = service.error {
                errorView(error: error)
            } else {
                storyList
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .task {
            await service.fetchTopStories()
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
            .padding()
        }
        .refreshable {
            await service.fetchTopStories()
        }
    }
}

#Preview {
    StoryListView()
}
