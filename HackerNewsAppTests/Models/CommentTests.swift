@testable import HackerNewsApp
import XCTest

final class CommentTests: XCTestCase {
    
    // MARK: - Plain Text HTML Stripping
    
    func test_plainText_whenTextHasParagraphTags_shouldConvertToNewlines() {
        let comment = TestFixtures.commentWithParagraphs
        
        XCTAssertTrue(comment.plainText.contains("\n\n"))
        XCTAssertFalse(comment.plainText.contains("<p>"))
    }
    
    func test_plainText_whenTextHasFormattingTags_shouldConvertToMarkdown() {
        let comment = TestFixtures.commentWithFormatting
        
        XCTAssertTrue(comment.plainText.contains("**bold**"))
        XCTAssertTrue(comment.plainText.contains("_italic_"))
        XCTAssertTrue(comment.plainText.contains("`code`"))
        XCTAssertFalse(comment.plainText.contains("<b>"))
        XCTAssertFalse(comment.plainText.contains("<i>"))
        XCTAssertFalse(comment.plainText.contains("<code>"))
    }
    
    // MARK: - Plain Text Entity Decoding
    
    func test_plainText_whenTextHasHTMLEntities_shouldDecode() {
        let comment = TestFixtures.commentWithHTMLEntities
        
        XCTAssertTrue(comment.plainText.contains("A & B"))
        XCTAssertTrue(comment.plainText.contains("> C"))
        XCTAssertTrue(comment.plainText.contains("< D"))
        XCTAssertFalse(comment.plainText.contains("&amp;"))
        XCTAssertFalse(comment.plainText.contains("&gt;"))
        XCTAssertFalse(comment.plainText.contains("&lt;"))
    }
    
    func test_plainText_whenTextHasApostropheEntity_shouldDecode() {
        let comment = TestFixtures.commentWithHTMLEntities
        
        XCTAssertTrue(comment.plainText.contains("'quoted'"))
        XCTAssertFalse(comment.plainText.contains("&#x27;"))
    }
    
    func test_plainText_whenTextHasQuoteEntity_shouldDecode() {
        let comment = TestFixtures.commentWithHTMLEntities
        
        XCTAssertTrue(comment.plainText.contains("\"test\""))
        XCTAssertFalse(comment.plainText.contains("&quot;"))
    }
    
    func test_plainText_whenTextIsNil_shouldReturnDeleted() {
        let comment = TestFixtures.deletedComment
        
        XCTAssertEqual(comment.plainText, "[deleted]")
    }
    
    // MARK: - isValid
    
    func test_isValid_whenCommentIsNormal_shouldReturnTrue() {
        let comment = TestFixtures.sampleComment
        
        XCTAssertTrue(comment.isValid)
    }
    
    func test_isValid_whenCommentIsDeleted_shouldReturnFalse() {
        let comment = TestFixtures.deletedComment
        
        XCTAssertFalse(comment.isValid)
    }
    
    func test_isValid_whenCommentIsDead_shouldReturnFalse() {
        let comment = TestFixtures.deadComment
        
        XCTAssertFalse(comment.isValid)
    }
    
    func test_isValid_whenAuthorIsNil_shouldReturnFalse() {
        let comment = Comment(
            id: 1,
            by: nil,
            text: "Some text",
            time: 0,
            kids: nil,
            parent: 0,
            type: "comment",
            deleted: nil,
            dead: nil
        )
        
        XCTAssertFalse(comment.isValid)
    }
    
    func test_isValid_whenTextIsNil_shouldReturnFalse() {
        let comment = Comment(
            id: 1,
            by: "user",
            text: nil,
            time: 0,
            kids: nil,
            parent: 0,
            type: "comment",
            deleted: nil,
            dead: nil
        )
        
        XCTAssertFalse(comment.isValid)
    }
    
    // MARK: - Child Count
    
    func test_childCount_whenKidsExist_shouldReturnCount() {
        let comment = TestFixtures.sampleComment
        
        XCTAssertEqual(comment.childCount, 1)
    }
    
    func test_childCount_whenKidsIsNil_shouldReturnZero() {
        let comment = TestFixtures.deletedComment
        
        XCTAssertEqual(comment.childCount, 0)
    }
    
    // MARK: - Time Ago
    
    func test_timeAgo_shouldReturnNonEmptyString() {
        let comment = TestFixtures.sampleComment
        
        XCTAssertFalse(comment.timeAgo.isEmpty)
    }
    
    // MARK: - JSON Decoding
    
    func test_decoding_whenJSONIsValid_shouldDecodeCorrectly() throws {
        let json = """
        {
            "id": 8952,
            "by": "user",
            "text": "Hello world",
            "time": 1175714300,
            "kids": [8953, 8954],
            "parent": 8863,
            "type": "comment"
        }
        """.data(using: .utf8) ?? Data()
        
        let comment = try JSONDecoder().decode(Comment.self, from: json)
        
        XCTAssertEqual(comment.id, 8952)
        XCTAssertEqual(comment.by, "user")
        XCTAssertEqual(comment.text, "Hello world")
        XCTAssertEqual(comment.childCount, 2)
        XCTAssertEqual(comment.parent, 8863)
    }
    
    func test_decoding_whenDeletedFlagPresent_shouldDecode() throws {
        let json = """
        {
            "id": 1,
            "time": 0,
            "parent": 0,
            "type": "comment",
            "deleted": true
        }
        """.data(using: .utf8) ?? Data()
        
        let comment = try JSONDecoder().decode(Comment.self, from: json)
        
        XCTAssertEqual(comment.deleted, true)
        XCTAssertFalse(comment.isValid)
    }
    
    func test_decoding_whenDeadFlagPresent_shouldDecode() throws {
        let json = """
        {
            "id": 1,
            "by": "user",
            "text": "text",
            "time": 0,
            "parent": 0,
            "type": "comment",
            "dead": true
        }
        """.data(using: .utf8) ?? Data()
        
        let comment = try JSONDecoder().decode(Comment.self, from: json)
        
        XCTAssertEqual(comment.dead, true)
        XCTAssertFalse(comment.isValid)
    }
}
