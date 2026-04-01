import Foundation

final class MockURLProtocol: URLProtocol {
    static var mockResponses: [String: Result<Data, Error>] = [:]
    
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
    
    override func startLoading() {
        guard let url = request.url?.absoluteString else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        
        if let result = MockURLProtocol.mockResponses[url] {
            switch result {
            case .success(let data):
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
            case .failure(let error):
                client?.urlProtocol(self, didFailWithError: error)
            }
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
    
    static func reset() {
        mockResponses.removeAll()
    }
}
