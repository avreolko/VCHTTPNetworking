//
//  VCNetworkingTests.swift
//  VCNetworkingTests
//
//  Created by Valentin Cherepyanko on 03.01.2020.
//  Copyright © 2020 Valentin Cherepyanko. All rights reserved.
//

import XCTest
@testable import VCNetworking

struct TestQuery: Encodable {
    let intValue: Int
    let stringValue: String

    static let `default` = TestQuery(intValue: 8,
                                     stringValue: "hi")
}

struct TestResponse: Decodable {

    struct NestedResponse: Decodable {
        let hi: String
        let hello: Int
    }

    let intValue: Int
    let nested: NestedResponse
}

class VCNetworkingTests: XCTestCase {

    var requestBuilder: RequestBuilder!

    override func setUp() {
        let bundlePath = Bundle(for: VCNetworkingTests.self).path(forResource: "Stubs", ofType: ".bundle")!
        let bundle = Bundle(path: bundlePath)

        self.requestBuilder = RequestBuilder(baseURL: URL(string: "https://httpstat.us")!,
                                               stubs: bundle)
    }

    func test_http_methods() {
        let mapToUrlRequest: (Request<Success>) -> URLRequest = { request in
            return (request.dataTask as! DataTask).request
        }

        let getRequest: Request<Success> = self.requestBuilder.method(.get).build()
        XCTAssertEqual(mapToUrlRequest(getRequest).httpMethod, "GET")
        let postRequest: Request<Success> = self.requestBuilder.method(.post).build()
        XCTAssertEqual(mapToUrlRequest(postRequest).httpMethod, "POST")
        let deleteRequest: Request<Success> = self.requestBuilder.method(.delete).build()
        XCTAssertEqual(mapToUrlRequest(deleteRequest).httpMethod, "DELETE")
    }

    func test_url_encoding() {
        let request: Request<Success> = self.requestBuilder.urlEncode(TestQuery.default).build()
        let urlRequest = (request.dataTask as! DataTask).request

        // because dictionary is unordered
        XCTAssertTrue(urlRequest.url!.absoluteString.contains("https://httpstat.us/?"))
        XCTAssertTrue(urlRequest.url!.absoluteString.contains("intValue=8"))
        XCTAssertTrue(urlRequest.url!.absoluteString.contains("stringValue=hi"))
        XCTAssertTrue(urlRequest.url!.absoluteString.contains("&"))
    }

    func test_json_encoding() {
        let request: Request<Success> = self.requestBuilder.jsonEncode(TestQuery.default).build()
        let urlRequest = (request.dataTask as! DataTask).request
        XCTAssertEqual(String(data: urlRequest.httpBody!, encoding: .utf8)!, "{\"intValue\":8,\"stringValue\":\"hi\"}")
    }

    func test_form_encoding() {
        let request: Request<Success> = self.requestBuilder.formEncode(TestQuery.default).build()
        let urlRequest = (request.dataTask as! DataTask).request
        let bodyString = String(data: urlRequest.httpBody!, encoding: .utf8)!

        // because dictionary is unordered
        XCTAssertTrue(bodyString.contains("intValue=8"))
        XCTAssertTrue(bodyString.contains("stringValue=hi"))
        XCTAssertTrue(bodyString.contains("&"))
    }

    func test_response_with_real_service() {
        let requestBuilder = RequestBuilder(baseURL: URL(string: "http://www.mocky.io/v2/5e1004623500006c001e687b")!)
        let request: Request<TestResponse> = requestBuilder.method(.get).build()

        let exp = expectation(description: "getting response")

        request.start { result in
            switch result {
            case .success: exp.fulfill()
            case .failure: ()
            }
        }

        waitForExpectations(timeout: 3)
    }

    func test_empty_response() {
        let requestBuilder = RequestBuilder(baseURL: URL(string: "http://www.mocky.io/v2/5e1007c835000068001e687f")!)
        let request: Request<Success> = requestBuilder.method(.get).build()

        let exp = expectation(description: "getting another response")

        request.start { result in
            switch result {
            case .success: exp.fulfill()
            case .failure: ()
            }
        }

        waitForExpectations(timeout: 3)
    }

    func test_promises() {
        let requestBuilder = RequestBuilder(baseURL: URL(string: "http://www.mocky.io/v2/5e1004623500006c001e687b")!)
        let request: Request<TestResponse> = requestBuilder.method(.get).build()

        let exp = expectation(description: "waiting for response")

        let promise = Promise<TestResponse>()
        request.start(with: promise)

        promise.then { _ in
            exp.fulfill()
        }

        waitForExpectations(timeout: 3)
    }

    func test_mocking() {

        struct MockedResponse: Decodable {
            let some: Int
        }

        let request: Request<MockedResponse> =
            self.requestBuilder
                .mockResponse(with: "mock")
                .build()

        let exp = expectation(description: "getting mocked response")

        request.start { result in
            switch result {
            case .success: exp.fulfill()
            case .failure: ()
            }
        }

        waitForExpectations(timeout: 1)
    }
}
