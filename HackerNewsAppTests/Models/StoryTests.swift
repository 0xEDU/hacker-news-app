@testable import HackerNewsApp
import XCTest

final class StoryTests: XCTestCase {
    
    // MARK: - Domain Extraction
    
    func test_domain_whenURLHasStandardHost_shouldReturnHost() {
        let story = Story(
            id: 1,
            title: "Test",
            url: "https://github.com/foo/bar",
            score: 1,
            by: "user",
            time: 0,
            descendants: nil,
            kids: nil,
            type: "story"
        )
        
        XCTAssertEqual(story.domain, "github.com")
    }
    
    func test_domain_whenURLHasWWWPrefix_shouldStripWWW() {
        let story = TestFixtures.storyWithWWW
        
        XCTAssertEqual(story.domain, "example.com")
    }
    
    func test_domain_whenURLIsNil_shouldReturnNil() {
        let story = TestFixtures.askHNStory
        
        XCTAssertNil(story.domain)
    }
    
    func test_domain_whenURLIsInvalid_shouldReturnNil() {
        let story = TestFixtures.storyWithInvalidURL
        
        XCTAssertNil(story.domain)
    }
    
    // MARK: - Story URL Fallback
    
    func test_storyURL_whenURLExists_shouldReturnURL() {
        let story = TestFixtures.sampleStory
        
        XCTAssertEqual(story.storyURL?.absoluteString, "http://www.getdropbox.com/u/2/screencast.html")
    }
    
    func test_storyURL_whenURLIsNil_shouldReturnHNItemURL() {
        let story = TestFixtures.askHNStory
        
        XCTAssertEqual(story.storyURL?.absoluteString, "https://news.ycombinator.com/item?id=121003")
    }
    
    // MARK: - Comment Count
    
    func test_commentCount_whenDescendantsExists_shouldReturnValue() {
        let story = TestFixtures.sampleStory
        
        XCTAssertEqual(story.commentCount, 71)
    }
    
    func test_commentCount_whenDescendantsIsNil_shouldReturnZero() {
        let story = TestFixtures.storyWithInvalidURL
        
        XCTAssertEqual(story.commentCount, 0)
    }
    
    // MARK: - Comment IDs
    
    func test_commentIDs_whenKidsExist_shouldReturnKids() {
        let story = TestFixtures.sampleStory
        
        XCTAssertEqual(story.commentIDs, [8952, 9224])
    }
    
    func test_commentIDs_whenKidsIsNil_shouldReturnEmptyArray() {
        let story = TestFixtures.storyWithInvalidURL
        
        XCTAssertEqual(story.commentIDs, [])
    }
    
    // MARK: - Time Ago
    
    func test_timeAgo_whenTimestampIsRecent_shouldReturnRelativeString() {
        let story = TestFixtures.storyWithWWW
        
        XCTAssertFalse(story.timeAgo.isEmpty)
    }
    
    // MARK: - JSON Decoding
    
    func test_decoding_whenJSONIsValid_shouldDecodeCorrectly() throws {
        let json = """
        {
            "id": 8863,
            "title": "Test Story",
            "url": "https://example.com",
            "score": 100,
            "by": "user",
            "time": 1175714200,
            "descendants": 50,
            "kids": [1, 2, 3],
            "type": "story"
        }
        """.data(using: .utf8) ?? Data()
        
        let story = try JSONDecoder().decode(Story.self, from: json)
        
        XCTAssertEqual(story.id, 8863)
        XCTAssertEqual(story.title, "Test Story")
        XCTAssertEqual(story.score, 100)
        XCTAssertEqual(story.by, "user")
        XCTAssertEqual(story.commentIDs, [1, 2, 3])
        XCTAssertEqual(story.commentCount, 50)
    }
    
    func test_decoding_whenOptionalFieldsMissing_shouldDecodeWithNils() throws {
        let json = """
        {
            "id": 1,
            "title": "Minimal Story",
            "score": 1,
            "by": "user",
            "time": 0,
            "type": "story"
        }
        """.data(using: .utf8) ?? Data()
        
        let story = try JSONDecoder().decode(Story.self, from: json)
        
        XCTAssertEqual(story.id, 1)
        XCTAssertNil(story.url)
        XCTAssertNil(story.descendants)
        XCTAssertNil(story.kids)
    }
}
