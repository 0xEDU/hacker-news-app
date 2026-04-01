import Foundation
@testable import HackerNewsApp

enum TestFixtures {
    
    // MARK: - Stories
    
    static let sampleStory = Story(
        id: 8863,
        title: "My YC app: Dropbox - Throw away your USB drive",
        url: "http://www.getdropbox.com/u/2/screencast.html",
        score: 104,
        by: "dhouston",
        time: 1175714200,
        descendants: 71,
        kids: [8952, 9224],
        type: "story"
    )
    
    static let askHNStory = Story(
        id: 121003,
        title: "Ask HN: What are you working on?",
        url: nil,
        score: 250,
        by: "pg",
        time: 1175714200,
        descendants: 150,
        kids: [121004],
        type: "story"
    )
    
    static let storyWithWWW = Story(
        id: 1,
        title: "Test Story",
        url: "https://www.example.com/page",
        score: 50,
        by: "testuser",
        time: Int(Date().timeIntervalSince1970) - 3600,
        descendants: 10,
        kids: nil,
        type: "story"
    )
    
    static let storyWithInvalidURL = Story(
        id: 2,
        title: "Invalid URL Story",
        url: "not-a-valid-url",
        score: 10,
        by: "user",
        time: 0,
        descendants: nil,
        kids: nil,
        type: "story"
    )
    
    static let storyJSON = """
    {
        "id": 8863,
        "title": "My YC app: Dropbox - Throw away your USB drive",
        "url": "http://www.getdropbox.com/u/2/screencast.html",
        "score": 104,
        "by": "dhouston",
        "time": 1175714200,
        "descendants": 71,
        "kids": [8952, 9224],
        "type": "story"
    }
    """.data(using: .utf8)!
    
    static let topStoriesJSON = "[8863, 8864, 8865]".data(using: .utf8)!
    
    // MARK: - Comments
    
    static let sampleComment = Comment(
        id: 8952,
        by: "norvig",
        text: "This is a <b>great</b> comment with &amp; entities",
        time: 1175714300,
        kids: [8953],
        parent: 8863,
        type: "comment",
        deleted: nil,
        dead: nil
    )
    
    static let deletedComment = Comment(
        id: 8999,
        by: nil,
        text: nil,
        time: 1175714400,
        kids: nil,
        parent: 8863,
        type: "comment",
        deleted: true,
        dead: nil
    )
    
    static let deadComment = Comment(
        id: 9000,
        by: "user",
        text: "This comment is dead",
        time: 1175714500,
        kids: nil,
        parent: 8863,
        type: "comment",
        deleted: nil,
        dead: true
    )
    
    static let commentWithHTMLEntities = Comment(
        id: 9001,
        by: "coder",
        text: "A &amp; B &gt; C &lt; D &#x27;quoted&#x27; &quot;test&quot;",
        time: 1175714600,
        kids: nil,
        parent: 8863,
        type: "comment",
        deleted: nil,
        dead: nil
    )
    
    static let commentWithFormatting = Comment(
        id: 9002,
        by: "writer",
        text: "<b>bold</b> and <i>italic</i> with <code>code</code>",
        time: 1175714700,
        kids: nil,
        parent: 8863,
        type: "comment",
        deleted: nil,
        dead: nil
    )
    
    static let commentWithParagraphs = Comment(
        id: 9003,
        by: "author",
        text: "First paragraph<p>Second paragraph<p>Third paragraph",
        time: 1175714800,
        kids: nil,
        parent: 8863,
        type: "comment",
        deleted: nil,
        dead: nil
    )
    
    static let commentJSON = """
    {
        "id": 8952,
        "by": "norvig",
        "text": "Great project!",
        "time": 1175714300,
        "kids": [8953, 8954],
        "parent": 8863,
        "type": "comment"
    }
    """.data(using: .utf8)!
    
    static let comment2JSON = """
    {
        "id": 9224,
        "by": "pg",
        "text": "Welcome to HN!",
        "time": 1175714400,
        "parent": 8863,
        "type": "comment"
    }
    """.data(using: .utf8)!
    
    // MARK: - Mock Session
    
    static func mockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}
