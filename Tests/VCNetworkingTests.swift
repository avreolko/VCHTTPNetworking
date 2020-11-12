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
    let boolValue: Bool

    static let `default` = TestQuery(intValue: 8,
                                     stringValue: "hi",
                                     boolValue: true)
}

struct TestResponse: Decodable {

    struct NestedResponse: Decodable {
        let hi: String
        let hello: Int
    }

    let intValue: Int
    let nested: NestedResponse
}

final class VCNetworkingTests: XCTestCase {

    private var requestBuilder: RequestBuilder!

    override func setUp() {
        self.requestBuilder = RequestBuilder(baseURL: URL(string: "https://httpstat.us")!)
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
        let request: Request<Success> = self.requestBuilder.jsonEncode(TestQuery.default).build()
        let urlRequest = (request.dataTask as! DataTask).request

        let data = try XCTUnwrap(urlRequest.httpBody)
        let jsonString = String(data: data, encoding: .utf8)

        XCTAssertEqual(
            jsonString,
            "{\"intValue\":8,\"boolValue\":true,\"stringValue\":\"hi\"}"
        )
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

        waitForExpectations(timeout: 1)
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

        waitForExpectations(timeout: 1)
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

    func test_common_applications() {

        let headers = ["Omae Wa Mou Shindeiru": "Nani?!"]

        let application: RequestBuilderApplication = { builder in
            builder.headers(headers)
        }

        let requestBuilder = RequestBuilder(baseURL: URL(string: "http://www.mocky.io/")!,
                                            applicationsProvider: RequestBuilderApplicationsProviderMock([application]))

        let request1: Request<TestResponse> = requestBuilder.build()
        requestBuilder.reset()
        let request2: Request<TestResponse> = requestBuilder.build()

        let headerFrom: (Request<TestResponse>) -> String? = {
            return ($0.dataTask as! DataTask).request.allHTTPHeaderFields?[headers.keys.first!]
        }

        XCTAssertEqual(headerFrom(request1), headers.values.first!)
        XCTAssertEqual(headerFrom(request2), headers.values.first!)
    }

    func test_response_code_actions() {

        let expectation = self.expectation(description: "getting response")

        let actions = [401: [{ expectation.fulfill() }]]

        let requestBuilder = RequestBuilder(baseURL: URL(string: "http://www.mocky.io/v2/5e8077463000002d006f94b1")!,
                                            responseActionsProvider: ResponseActionsProviderMock(actions))

        let request: Request<TestResponse> = requestBuilder.method(.get).build()
        request.start { _ in }

        waitForExpectations(timeout: 1)
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
}

private class RequestBuilderApplicationsProviderMock: IRequestBuilderApplicationsProvider {

    let applications: [RequestBuilderApplication]

    init(_ applications: [RequestBuilderApplication]) {
        self.applications = applications
    }
}

private class ResponseActionsProviderMock: IResponseActionsProvider {

    let actions: [ResponseCode: [Action]]

    init(_ actions: [ResponseCode: [Action]]) {
        self.actions = actions
    }
}
