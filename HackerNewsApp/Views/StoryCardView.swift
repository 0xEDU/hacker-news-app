import SwiftUI

struct StoryCardView: View {
    let story: Story
    
    @State private var isHovered = false
    @State private var showComments = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(story.title)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            // Metadata row
            HStack(spacing: 12) {
                // Score
                Label("\(story.score)", systemImage: "arrow.up")
                    .foregroundColor(.orange)
                
                // Author
                Label(story.by, systemImage: "person")
                    .foregroundColor(.secondary)
                
                // Time
                Label(story.timeAgo, systemImage: "clock")
                    .foregroundColor(.secondary)
                
                // Comments button
                Button {
                    showComments = true
                } label: {
                    Label("\(story.commentCount)", systemImage: "bubble.right")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("View comments")
                
                Spacer()
                
                // Domain
                if let domain = story.domain {
                    Text(domain)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(isHovered ? 0.15 : 0.05), radius: isHovered ? 8 : 4, y: 2)
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            openStoryInBrowser()
        }
        .cursor(.pointingHand)
        .sheet(isPresented: $showComments) {
            CommentsView(story: story)
        }
    }
    
    private func openStoryInBrowser() {
        if let url = story.storyURL {
            NSWorkspace.shared.open(url)
        }
    }
}

// Custom cursor modifier for macOS
extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in
            if inside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

#Preview {
    StoryCardView(story: Story(
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
    .padding()
    .frame(width: 500)
}
