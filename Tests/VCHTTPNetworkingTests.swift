//
//  VCHTTPNetworkingTests.swift
//  VCHTTPNetworking
//
//  Created by Valentin Cherepyanko on 03.01.2020.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import XCTest
@testable import VCHTTPNetworking

private struct TestQuery: Encodable {

    let intValue: Int
    let stringValue: String
    let boolValue: Bool

    static let `default` = TestQuery(
        intValue: 8,
        stringValue: "hi",
        boolValue: true
    )
}

struct TestResponse: Decodable {

    struct NestedResponse: Decodable {
        let hi: String
        let hello: Int
    }

    let intValue: Int
    let nested: NestedResponse
}

// MARK: - main tests
final class VCHTTPNetworkingTests: XCTestCase {

    private var requestBuilder: RequestBuilder!

    override func setUp() {
        self.requestBuilder = RequestBuilder(
            configuration: .init(baseURL: URL(string: "https://httpstat.us")!)
        )
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

        let headRequest: Request<Success> = self.requestBuilder.method(.head).build()
        XCTAssertEqual(mapToUrlRequest(headRequest).httpMethod, "HEAD")

        let putRequest: Request<Success> = self.requestBuilder.method(.put).build()
        XCTAssertEqual(mapToUrlRequest(putRequest).httpMethod, "PUT")

        let connectRequest: Request<Success> = self.requestBuilder.method(.connect).build()
        XCTAssertEqual(mapToUrlRequest(connectRequest).httpMethod, "CONNECT")

        let optionsRequest: Request<Success> = self.requestBuilder.method(.options).build()
        XCTAssertEqual(mapToUrlRequest(optionsRequest).httpMethod, "OPTIONS")

        let traceRequest: Request<Success> = self.requestBuilder.method(.trace).build()
        XCTAssertEqual(mapToUrlRequest(traceRequest).httpMethod, "TRACE")

        let patchRequest: Request<Success> = self.requestBuilder.method(.patch).build()
        XCTAssertEqual(mapToUrlRequest(patchRequest).httpMethod, "PATCH")
    }

    func test_url_encoding() throws {
        let request: Request<Success> = self.requestBuilder.urlEncode(TestQuery.default).build()
        let urlRequest = (request.dataTask as! DataTask).request

        // because dictionary is unordered
        let absolutePath = try XCTUnwrap(urlRequest.url?.absoluteString)
        XCTAssertTrue(absolutePath.contains("https://httpstat.us/?"))
        XCTAssertTrue(absolutePath.contains("intValue=8"))
        XCTAssertTrue(absolutePath.contains("stringValue=hi"))
        XCTAssertTrue(absolutePath.contains("boolValue=1"))
        XCTAssertTrue(absolutePath.contains("&"))
    }

    func test_json_encoding() throws {

        let exp = expectation(description: "waiting for request start")

        // Arrange
        let query = TestQuery.default

        // Act
        let request: Request<Success> = requestBuilder
            .encode(query)
            .build()

        request.start { _ in

            exp.fulfill()

            let urlRequest = (request.dataTask as? DataTask)?.request

            // Assert
            let data = urlRequest?.httpBody
            let jsonString = data.map { String(data: $0, encoding: .utf8) }

            XCTAssertEqual(
                jsonString,
                "{\"intValue\":8,\"boolValue\":true,\"stringValue\":\"hi\"}"
            )
        }

        waitForExpectations(timeout: 1)
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

    func test_basic_auth() {
        let request: Request<TestResponse> =
            self.requestBuilder
                .basicAuth(login: "v@d.ru", pass: "1")
                .build()

        let header = (request.dataTask as! DataTask).request.allHTTPHeaderFields?["Authorization"]
        XCTAssertEqual(header!, "Basic dkBkLnJ1OjE=")
    }

    func test_bearer_auth() {

        let token = "faospdfopjsdfpoaisjf"

        let request: Request<TestResponse> =
            self.requestBuilder
                .bearerAuth(with: token)
                .build()

        let header = (request.dataTask as! DataTask).request.allHTTPHeaderFields?["Authorization"]
        XCTAssertEqual(header!, "Bearer \(token)")
    }

    func test_oauth_auth() {

        let token = "faospdfopjsdfpoaisjf"

        let request: Request<TestResponse> =
            self.requestBuilder
                .oAuth(with: token)
                .build()

        let header = (request.dataTask as! DataTask).request.allHTTPHeaderFields?["Authorization"]
        XCTAssertEqual(header!, "OAuth \(token)")
    }

    func test_mocking() throws {

        let expectation = self.expectation(description: "getting response")

        let json =
        """
        {"intValue": 1, "nested": {"hi": "hi", "hello": 2}}
        """

        let data = try XCTUnwrap(json.data(using: .utf8))

        let request: Request<TestResponse> =
        self.requestBuilder
            .mockResponse(data: data)
            .build()

        request.start { result in
            _ = result.map { response in
                expectation.fulfill()
                XCTAssertEqual(response.intValue, 1)
                XCTAssertEqual(response.nested.hello, 2)
                XCTAssertEqual(response.nested.hi, "hi")
            }
        }

        waitForExpectations(timeout: 1)
    }

    func test_request_builder_path() throws {
        let request: Request<TestResponse> =
        self.requestBuilder
            .path("somePath")
            .build()

        let task = try XCTUnwrap(request.dataTask as? DataTask)

        XCTAssertEqual("https://httpstat.us/somePath/", task.request.url?.absoluteString)
    }

    func test_service_empty_data_error() {
        let expectation = self.expectation(description: "getting response")

        let request: Request<TestResponse> =
        self.requestBuilder
            .mockResponse(data: nil)
            .build()

        request.start { result in
            switch result {
            case .failure(.unexpectedEmptyDataError):
                expectation.fulfill()
            default:
                XCTFail("Should be error in this case")
            }
        }

        waitForExpectations(timeout: 1)
    }

    func test_service_error() {
        let expectation = self.expectation(description: "getting response")

        enum SomeError: Error {
            case foo
        }

        let error = SomeError.foo

        let request: Request<TestResponse> =
        self.requestBuilder
            .mockResponse(error: RequestError.serviceError(error))
            .build()

        request.start { result in
            switch result {
            case .failure(.serviceError):
                expectation.fulfill()
            default:
                XCTFail("Should be 400 error in this case")
            }
        }

        waitForExpectations(timeout: 1)
    }

    func test_content_type_header_setting() {

        let mapToUrlRequest: (Request<Success>) -> URLRequest = { request in
            return (request.dataTask as! DataTask).request
        }

        let jsonRequest: Request<Success> = self.requestBuilder.contentType(.json).build()
        XCTAssertEqual(mapToUrlRequest(jsonRequest).allHTTPHeaderFields?["Content-Type"], "application/json")

        let xmlRequest: Request<Success> = self.requestBuilder.contentType(.xml).build()
        XCTAssertEqual(mapToUrlRequest(xmlRequest).allHTTPHeaderFields?["Content-Type"], "application/xml")

        let formRequest: Request<Success> = self.requestBuilder.contentType(.form).build()
        XCTAssertEqual(mapToUrlRequest(formRequest).allHTTPHeaderFields?["Content-Type"], "application/x-www-form-urlencoded")
    }

    func test_headers_merging() {

        let request: Request<Success> = self.requestBuilder
            .headers([
                "header1": "1",
                "header2": "2",
                "header3": "false"
            ])
            .headers([
                "header3": "3",
                "header4": "4",
                "header5": "5"
            ])
            .build()

        let headers = (request.dataTask as! DataTask).request.allHTTPHeaderFields ?? [:]

        XCTAssertTrue(headers.contains(where: { $0 == "header1" && $1 == "1" }))
        XCTAssertTrue(headers.contains(where: { $0 == "header2" && $1 == "2" }))
        XCTAssertTrue(headers.contains(where: { $0 == "header3" && $1 == "3" }))
        XCTAssertTrue(headers.contains(where: { $0 == "header4" && $1 == "4" }))
        XCTAssertTrue(headers.contains(where: { $0 == "header5" && $1 == "5" }))
    }
}

// MARK: - integration tests
extension VCHTTPNetworkingTests {

    func disabled_test_response_with_real_service() {

        let requestBuilder = RequestBuilder(
            configuration: .init(baseURL: URL(string: "http://www.mocky.io/v2/5e1004623500006c001e687b")!)
        )

        let request: Request<TestResponse> = requestBuilder.method(.get).build()

        let exp = expectation(description: "getting response")

        request.start { result in
            switch result {
            case .success: exp.fulfill()
            case .failure: ()
            }
        }

        waitForExpectations(timeout: 1)
    }

    func disabled_test_empty_response() {

        let requestBuilder = RequestBuilder(
            configuration: .init(baseURL: URL(string: "http://www.mocky.io/v2/5e1007c835000068001e687f")!)
        )

        let request: Request<Success> = requestBuilder.method(.get).build()

        let exp = expectation(description: "getting another response")

        request.start { result in
            switch result {
            case .success: exp.fulfill()
            case .failure: ()
            }
        }

        waitForExpectations(timeout: 1)
    }
}
