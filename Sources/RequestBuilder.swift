//
//  RequestBuilder.swift
//  VCHTTPNetworking
//
//  Created by Valentin Cherepyanko on 03.01.2020.
//  Copyright © 2020 Valentin Cherepyanko. All rights reserved.
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

import Foundation

public enum HTTPMethod: String
{
    case get = "GET"
    case post = "POST"
    case delete = "DELETE"
    case put = "PUT"
}

public final class RequestBuilder {

    public struct Configuration {

        let baseURL: URL
        let encoder: IDataEncoder
        let decoder: IDataDecoder

        public init(
            baseURL: URL,
            encoder: IDataEncoder = JSONEncoder(),
            decoder: IDataDecoder = JSONDecoder()
        ) {
            self.baseURL = baseURL
            self.encoder = encoder
            self.decoder = decoder
        }
    }

    private struct BuildInfo {

        enum Mocking {
            case none
            case some(Data?, Error?)
        }

        var url: URL
        var method: HTTPMethod = .get
        var headers: [String: String] = [:]
        var encodedBody: Data?
        var encodedPath: String = ""
        var mocking: Mocking = .none
        var encodeAction: (() -> Data?)?
        var identityProvider: IIdentityProvider?
        var pinnedCertificatesProvider: ICertificatesProvider?
    }

    private let configuration: Configuration
    private var buildInfo: BuildInfo

    public init(configuration: Configuration) {

        self.configuration = configuration
        self.buildInfo = BuildInfo(url: configuration.baseURL)
    }

    @discardableResult
    public func basicAuth(login: String, pass: String) -> Self {

        let data = "\(login):\(pass)".data(using: .utf8)?.base64EncodedData()
        let base64String: String? = data.map { String(data: $0, encoding: .utf8) } ?? nil
        base64String.map { self.buildInfo.headers["Authorization"] = "Basic \($0)" }

        return self
    }

    @discardableResult
    public func bearerAuth(with token: String) -> Self {
        self.buildInfo.headers["Authorization"] = "Bearer \(token)"
        return self
    }

    @discardableResult
    public func oAuth(with token: String) -> Self {
        self.buildInfo.headers["Authorization"] = "OAuth \(token)"
        return self
    }

    @discardableResult
    public func auth(with identityProvider: IIdentityProvider) -> Self {
        buildInfo.identityProvider = identityProvider
        return self
    }

    @discardableResult
    public func sslPin(with certificatesProvider: ICertificatesProvider) -> Self {
        buildInfo.pinnedCertificatesProvider = certificatesProvider
        return self
    }

    @discardableResult
    public func method(_ method: HTTPMethod) -> Self {
        self.buildInfo.method = method
        return self
    }

    @discardableResult
    public func path(_ path: String) -> Self {
        self.buildInfo.url.appendPathComponent(path)
        return self
    }

    @discardableResult
    public func headers(_ headers: [String: String]) -> Self {
        self.buildInfo.headers.merge(headers) { (_, new) in new }
        return self
    }

    @discardableResult
    public func formEncode<T: Encodable>(_ query: T) -> Self {
        self.buildInfo.headers["Content-Type"] = "application/x-www-form-urlencoded forHTTPHeaderField"
        self.buildInfo.encodedBody = query.urlEncoded?.data(using: .utf8)
        return self
    }

    @discardableResult
    public func encode<T: Encodable>(_ query: T) -> Self {
        let encoder = configuration.encoder
        buildInfo.encodeAction = { try? encoder.encode(query) }
        return self
    }

    @discardableResult
    public func urlEncode<T: Encodable>(_ query: T) -> Self {
        guard let dict = query.dictionary else {
            return self
        }

        var urlComponents = URLComponents(url: self.buildInfo.url, resolvingAgainstBaseURL: false)

        let queryItems = dict.map {
            return URLQueryItem(name: "\($0)", value: "\($1)")
        }

        urlComponents?.queryItems = queryItems

        urlComponents?.url.map { self.buildInfo.url = $0 }

        return self
    }

    @discardableResult
    public func mockResponse(data: Data? = nil, error: Error? = nil) -> Self {
        self.buildInfo.mocking = .some(data, error)
        return self
    }

    public func build<T: Decodable>() -> Request<T> {

        defer { self.reset() }

        let fullURL = self.buildInfo.url.appendingPathComponent(self.buildInfo.encodedPath)
        var request = URLRequest(url: fullURL)

        request.httpMethod = self.buildInfo.method.rawValue
        request.httpBody = self.buildInfo.encodedBody

        self.buildInfo.headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }

        let makeDataTask: () -> IDataTask = {
            switch self.buildInfo.mocking {
            case .none:
                return DataTask(
                    request: request,
                    encodeAction: self.buildInfo.encodeAction,
                    pinnedCertificatesProvider: self.buildInfo.pinnedCertificatesProvider,
                    identityProvider: self.buildInfo.identityProvider
                )
            case .some(let data, let error):
                return MockedDataTask(data: data, error: error)
            }
        }

        return Request(
            dataTask: makeDataTask(),
            decoder: configuration.decoder
        )
    }

    @discardableResult
    internal func reset() -> Self {
        self.buildInfo = BuildInfo(url: self.configuration.baseURL)
        return self
    }
}

private extension Encodable
{
    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap {
            $0 as? [String: Any]
        }
    }

    var urlEncoded: String? {
        guard let dict = self.dictionary else {
            return nil
        }

        var encodedString = ""

        for (key, optionalValue) in dict {
            if let value = optionalValue as? String {
                encodedString.append(encodedString.count > 0 ? "&" : "")
                encodedString.append("\(key)=\(value)")
            }

            if let value = optionalValue as? Bool {
                encodedString.append(encodedString.count > 0 ? "&" : "")
                encodedString.append("\(key)=\(value)")
            }

            if let value = optionalValue as? Int {
                encodedString.append(encodedString.count > 0 ? "&" : "")
                encodedString.append("\(key)=\(value)")
            }
        }

        return encodedString
    }
}
