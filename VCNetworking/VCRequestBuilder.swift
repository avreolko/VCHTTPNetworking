//
//  VCRequestBuilder.swift
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
}

final class VCRequestBuilder {

    struct BuildInfo {
        var url: URL
        var method: HTTPMethod = .get
        var headers: [String: String] = [:]
        var encodedBody: Data?
        var encodedPath: String = ""
    }

    private let baseURL: URL
    private let session = URLSession(configuration: .default)
    private var buildInfo: BuildInfo

    init(baseURL: URL) {
        self.baseURL = baseURL
        self.buildInfo = BuildInfo(url: self.baseURL)
    }

    func reset() {
        self.buildInfo = BuildInfo(url: self.baseURL)
    }

    func method(_ method: HTTPMethod) -> Self {
        self.buildInfo.method = method
        return self
    }

    func path(_ path: String) -> Self {
        self.buildInfo.url.appendPathComponent(path)
        return self
    }

    func headers(_ headers: [String: String]) -> Self {
        self.buildInfo.headers.merge(headers) { (_, new) in new }
        return self
    }

    func formEncode<T: Encodable>(_ query: T) -> Self {
        self.buildInfo.headers["Content-Type"] = "application/x-www-form-urlencoded forHTTPHeaderField"
        self.buildInfo.encodedBody = query.urlEncoded?.data(using: .utf8)
        return self
    }

    func jsonEncode<T: Encodable>(_ query: T) -> Self {
        self.buildInfo.headers["Content-Type"] = "application/json"
        self.buildInfo.encodedBody = try? JSONEncoder().encode(query)
        return self
    }

    func urlEncode<T: Encodable>(_ query: T) -> Self {
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

    //    func emulationMode() -> Self { return self } // TODO

    func build() -> Request {

        let fullURL = self.buildInfo.url.appendingPathComponent(self.buildInfo.encodedPath)
        var request = URLRequest(url: fullURL)

        request.httpMethod = self.buildInfo.method.rawValue
        request.httpBody = self.buildInfo.encodedBody

        self.buildInfo.headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }

        return Request(request: request, session: self.session)
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
