@testable import HackerNewsApp
import XCTest

final class HackerNewsServiceTests: XCTestCase {
    
    var sut: HackerNewsService!
    
    override func setUp() async throws {
        MockURLProtocol.reset()
        sut = HackerNewsService(session: TestFixtures.mockSession())
    }
    
    override func tearDown() async throws {
        sut = nil
        MockURLProtocol.reset()
    }
    
    // MARK: - Fetch Top Stories
    
    func test_fetchTopStories_whenAPIReturnsValidData_shouldReturnStories() async throws {
        // Arrange
        MockURLProtocol.mockResponses["https://hacker-news.firebaseio.com/v0/topstories.json"] =
            .success("[8863]".data(using: .utf8) ?? Data())
        MockURLProtocol.mockResponses["https://hacker-news.firebaseio.com/v0/item/8863.json"] =
            .success(TestFixtures.storyJSON)
        
        // Act
        let stories = try await sut.fetchTopStories(page: 0, limit: 30)
        
        // Assert
        XCTAssertFalse(stories.isEmpty)
        XCTAssertEqual(stories.first?.id, 8863)
    }
    
    func test_fetchTopStories_whenNetworkFails_shouldThrowNetworkError() async {
        // Arrange
        MockURLProtocol.mockResponses["https://hacker-news.firebaseio.com/v0/topstories.json"] =
            .failure(URLError(.notConnectedToInternet))
        
        // Act
        do {
            _ = try await sut.fetchTopStories(page: 0, limit: 30)
            XCTFail("Expected fetchTopStories to throw")
        } catch let error as HackerNewsErrorEnum {
            guard case .networkError = error else {
                return XCTFail("Expected network error, got \(error)")
            }
        } catch {
            XCTFail("Expected HackerNewsErrorEnum, got \(error)")
        }
    }
    
    func test_fetchTopStories_whenJSONIsInvalid_shouldThrowDecodingError() async {
        // Arrange
        MockURLProtocol.mockResponses["https://hacker-news.firebaseio.com/v0/topstories.json"] =
            .success("invalid json".data(using: .utf8) ?? Data())
        
        // Act
        do {
            _ = try await sut.fetchTopStories(page: 0, limit: 30)
            XCTFail("Expected fetchTopStories to throw")
        } catch let error as HackerNewsErrorEnum {
            guard case .decodingError = error else {
                return XCTFail("Expected decoding error, got \(error)")
            }
        } catch {
            XCTFail("Expected HackerNewsErrorEnum, got \(error)")
        }
    }
    
    func test_fetchTopStories_whenAPIReturnsEmptyArray_shouldReturnEmptyStories() async throws {
        // Arrange
        MockURLProtocol.mockResponses["https://hacker-news.firebaseio.com/v0/topstories.json"] =
            .success("[]".data(using: .utf8) ?? Data())
        
        // Act
        let stories = try await sut.fetchTopStories(page: 0, limit: 30)
        
        // Assert
        XCTAssertTrue(stories.isEmpty)
    }
    
    // MARK: - Fetch Comment
    
    func test_fetchComment_whenCommentExists_shouldReturnComment() async throws {
        // Arrange
        MockURLProtocol.mockResponses["https://hacker-news.firebaseio.com/v0/item/8952.json"] =
            .success(TestFixtures.commentJSON)
        
        // Act
        let comment = try await sut.fetchComment(id: 8952)
        
        // Assert
        XCTAssertNotNil(comment)
        XCTAssertEqual(comment?.id, 8952)
    }
    
    func test_fetchComment_whenResponseIsNull_shouldReturnNil() async throws {
        // Arrange
        MockURLProtocol.mockResponses["https://hacker-news.firebaseio.com/v0/item/8999.json"] =
            .success("null".data(using: .utf8) ?? Data())
        
        // Act
        let comment = try await sut.fetchComment(id: 8999)
        
        // Assert
        XCTAssertNil(comment)
    }
    
    // MARK: - Fetch Comment Trees
    
    func test_fetchCommentTrees_whenStoryHasComments_shouldBuildTree() async throws {
        // Arrange
        let story = Story(
            id: 8863,
            title: "Test Story",
            url: nil,
            score: 10,
            by: "user",
            time: 0,
            descendants: 2,
            kids: [8952, 9224],
            type: "story"
        )
        // Use comments without children to avoid recursive fetch issues
        let comment1JSON = """
        {
            "id": 8952,
            "by": "user1",
            "text": "First comment",
            "time": 1175714300,
            "parent": 8863,
            "type": "comment"
        }
        """.data(using: .utf8) ?? Data()
        let comment2JSON = """
        {
            "id": 9224,
            "by": "user2",
            "text": "Second comment",
            "time": 1175714400,
            "parent": 8863,
            "type": "comment"
        }
        """.data(using: .utf8) ?? Data()
        MockURLProtocol.mockResponses["https://hacker-news.firebaseio.com/v0/item/8952.json"] =
            .success(comment1JSON)
        MockURLProtocol.mockResponses["https://hacker-news.firebaseio.com/v0/item/9224.json"] =
            .success(comment2JSON)
        
        // Act
        let trees = try await sut.fetchCommentTrees(for: story, maxDepth: 1)
        
        // Assert
        XCTAssertEqual(trees.count, 2)
        XCTAssertEqual(trees[0].depth, 0)
    }
    
    func test_fetchCommentTrees_whenStoryHasNoComments_shouldReturnEmptyArray() async throws {
        // Arrange
        let story = Story(
            id: 1,
            title: "No comments",
            url: nil,
            score: 1,
            by: "user",
            time: 0,
            descendants: 0,
            kids: nil,
            type: "story"
        )
        
        // Act
        let trees = try await sut.fetchCommentTrees(for: story)
        
        // Assert
        XCTAssertTrue(trees.isEmpty)
    }
    
    func test_fetchCommentTrees_whenCommentsAreDeleted_shouldFilterThem() async throws {
        // Arrange
        let story = Story(
            id: 1,
            title: "Story with deleted comments",
            url: nil,
            score: 1,
            by: "user",
            time: 0,
            descendants: 1,
            kids: [8999],
            type: "story"
        )
        MockURLProtocol.mockResponses["https://hacker-news.firebaseio.com/v0/item/8999.json"] =
            .success("null".data(using: .utf8) ?? Data())
        
        // Act
        let trees = try await sut.fetchCommentTrees(for: story)
        
        // Assert
        XCTAssertTrue(trees.isEmpty)
    }
}
