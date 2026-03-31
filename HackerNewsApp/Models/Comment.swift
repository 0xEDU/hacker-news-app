import Foundation

struct Comment: Identifiable, Codable {
    let id: Int
    let by: String?
    let text: String?
    let time: Int
    let kids: [Int]?
    let parent: Int
    let type: String
    let deleted: Bool?
    let dead: Bool?
    
    /// Returns a relative time string (e.g., "2 hours ago")
    var timeAgo: String {
        let date = Date(timeIntervalSince1970: TimeInterval(time))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// Returns the comment text with HTML tags stripped
    var plainText: String {
        guard let text = text else { return "[deleted]" }
        return text
            .replacingOccurrences(of: "<p>", with: "\n\n")
            .replacingOccurrences(of: "</p>", with: "")
            .replacingOccurrences(of: "<i>", with: "_")
            .replacingOccurrences(of: "</i>", with: "_")
            .replacingOccurrences(of: "<b>", with: "**")
            .replacingOccurrences(of: "</b>", with: "**")
            .replacingOccurrences(of: "<code>", with: "`")
            .replacingOccurrences(of: "</code>", with: "`")
            .replacingOccurrences(of: "<pre>", with: "\n```\n")
            .replacingOccurrences(of: "</pre>", with: "\n```\n")
            .replacingOccurrences(of: "&#x27;", with: "'")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "<a href=\"", with: "")
            .replacingOccurrences(of: "\" rel=\"nofollow\">", with: " ")
            .replacingOccurrences(of: "</a>", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Check if comment is valid (not deleted/dead and has content)
    var isValid: Bool {
        deleted != true && dead != true && by != nil && text != nil
    }
    
    /// Number of child comments
    var childCount: Int {
        kids?.count ?? 0
    }
}

/// A comment with its nested replies loaded
struct CommentTree: Identifiable {
    let id: Int
    let comment: Comment
    var children: [CommentTree]
    let depth: Int
    
    init(comment: Comment, children: [CommentTree] = [], depth: Int = 0) {
        self.id = comment.id
        self.comment = comment
        self.children = children
        self.depth = depth
    }
}
