//
//  IRequestBuilder.swift
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

public protocol IRequestBuilder {

    @discardableResult
    func basicAuth(login: String, pass: String) -> Self

    @discardableResult
    func bearerAuth(with token: String) -> Self

    @discardableResult
    func oAuth(with token: String) -> Self

    @discardableResult
    func auth(with identityProvider: IIdentityProvider) -> Self

    @discardableResult
    func sslPin(with certificatesProvider: ICertificatesProvider) -> Self

    @discardableResult
    func method(_ method: HTTPMethod) -> Self

    @discardableResult
    func path(_ path: String) -> Self

    @discardableResult
    func headers(_ headers: [String: String]) -> Self

    @discardableResult
    func contentType(_ contentType: ContentType) -> Self

    @discardableResult
    func formEncode<T: Encodable>(_ query: T) -> Self

    @discardableResult
    func encode<T: Encodable>(_ query: T) -> Self

    @discardableResult
    func session(is configuredAs: URLSessionConfiguration) -> Self

    @discardableResult
    func timeout(_ value: TimeInterval) -> Self

    @discardableResult
    func urlEncode<T: Encodable>(_ query: T) -> Self

    @discardableResult
    func mockResponse(data: Data?, error: Error?) -> Self

    func build<T: Decodable>() -> Request<T>
}
