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

    var requestBuilder: VCRequestBuilder!

    override func setUp() {
        self.requestBuilder = VCRequestBuilder(baseURL: URL(string: "https://httpstat.us")!)
    }

    func test_http_methods() {
        let getRequest: Request<Success> = self.requestBuilder.method(.get).build()
        XCTAssertEqual(getRequest.request.httpMethod, "GET")
        let postRequest: Request<Success> = self.requestBuilder.method(.post).build()
        XCTAssertEqual(postRequest.request.httpMethod, "POST")
        let deleteRequest: Request<Success> = self.requestBuilder.method(.delete).build()
        XCTAssertEqual(deleteRequest.request.httpMethod, "DELETE")
    }

    func test_url_encoding() {
        let request: Request<Success> = self.requestBuilder.urlEncode(TestQuery.default).build()

        // because json dictionary is unordered
        XCTAssertTrue(request.request.url!.absoluteString.contains("https://httpstat.us/?"))
        XCTAssertTrue(request.request.url!.absoluteString.contains("intValue=8"))
        XCTAssertTrue(request.request.url!.absoluteString.contains("stringValue=hi"))
        XCTAssertTrue(request.request.url!.absoluteString.contains("&"))
    }

    func test_body_encoding() {
        let request: Request<Success> = self.requestBuilder.jsonEncode(TestQuery.default).build()
        XCTAssertEqual(String(data: request.request.httpBody!, encoding: .utf8), "{\"intValue\":8,\"stringValue\":\"hi\"}")
    }

    func test_response_with_real_service() {
        let requestBuilder = VCRequestBuilder(baseURL: URL(string: "http://www.mocky.io/v2/5e1004623500006c001e687b")!)
        let postRequest: Request<Success> = requestBuilder.method(.get).build()

        let exp = expectation(description: "getting response")

        postRequest.start { result in
            switch result {
            case .success: exp.fulfill()
            case .failure: ()
            }
        }

        waitForExpectations(timeout: 3)
    }
}
