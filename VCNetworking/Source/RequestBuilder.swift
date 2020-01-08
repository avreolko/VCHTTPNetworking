//
//  RequestBuilder.swift
//  VCNetworking
//
//  Created by Valentin Cherepyanko on 03.01.2020.
//  Copyright © 2020 Valentin Cherepyanko. All rights reserved.
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

    private struct BuildInfo {

        enum Mocking {
            case none
            case some(filename: String)
        }

        var url: URL
        var method: HTTPMethod = .get
        var headers: [String: String] = [:]
        var encodedBody: Data?
        var encodedPath: String = ""
        var mocking: Mocking = .none
    }

    private let baseURL: URL
    private let session = URLSession(configuration: .default)
    private let stubs: Bundle?
    private let resetAfterBuilding: Bool

    private var buildInfo: BuildInfo

    public init(baseURL: URL, stubs: Bundle? = nil, resetAfterBuilding: Bool = true) {
        self.baseURL = baseURL
        self.stubs = stubs
        self.buildInfo = BuildInfo(url: self.baseURL)
        self.resetAfterBuilding = resetAfterBuilding
    }

    @discardableResult
    public func reset() -> Self {
        self.buildInfo = BuildInfo(url: self.baseURL)
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
    public func jsonEncode<T: Encodable>(_ query: T) -> Self {
        self.buildInfo.headers["Content-Type"] = "application/json"
        self.buildInfo.encodedBody = try? JSONEncoder().encode(query)
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
    public func mockResponse(with jsonFilename: String) -> Self {
        self.buildInfo.mocking = .some(filename: jsonFilename)
        return self
    }

    public func build<T: Decodable>() -> Request<T> {
        defer {
            if self.resetAfterBuilding { self.reset() }
        }

        let fullURL = self.buildInfo.url.appendingPathComponent(self.buildInfo.encodedPath)
        var request = URLRequest(url: fullURL)

        request.httpMethod = self.buildInfo.method.rawValue
        request.httpBody = self.buildInfo.encodedBody

        self.buildInfo.headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }

        let makeDataTask: () -> IDataTask = {
            switch self.buildInfo.mocking {
            case .none: return DataTask(request: request, session: self.session)
            case .some(let filename): return MockedDataTask(filename: filename, stubs: self.stubs)
            }
        }

        return Request(dataTask: makeDataTask())
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
            print("Cannot parse.")
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