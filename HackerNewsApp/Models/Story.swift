import Foundation

struct Story: Identifiable, Codable {
    let id: Int
    let title: String
    let url: String?
    let score: Int
    let by: String
    let time: Int
    let descendants: Int?
    let type: String
    
    /// Returns the domain from the URL (e.g., "github.com")
    var domain: String? {
        guard let urlString = url,
              let url = URL(string: urlString),
              let host = url.host else {
            return nil
        }
        // Remove "www." prefix if present
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
    
    /// Returns the story URL or a fallback to the HN item page
    var storyURL: URL? {
        if let urlString = url, let url = URL(string: urlString) {
            return url
        }
        // Fallback to HN discussion page for Ask HN, etc.
        return URL(string: "https://news.ycombinator.com/item?id=\(id)")
    }
    
    /// Returns a relative time string (e.g., "2 hours ago")
    var timeAgo: String {
        let date = Date(timeIntervalSince1970: TimeInterval(time))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// Comment count, defaulting to 0 if not available
    var commentCount: Int {
        descendants ?? 0
    }
}
