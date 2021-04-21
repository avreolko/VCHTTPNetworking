//
//  Request.swift
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

public enum RequestError: Error {
    case serviceError(Error)
    case httpError(Int)
    case decodingError(Error, Data)
    case unexpectedEmptyDataError
}

public struct Success: Decodable { public init() { } }

public struct Request<T: Decodable> {

    let dataTask: IDataTask

    private let decoder: IDataDecoder
    private let responseCodeActions: [ResponseCode: [Action]]

    init(dataTask: IDataTask,
         decoder: IDataDecoder,
         responseCodeActions: [ResponseCode: [Action]]) {

        self.dataTask = dataTask
        self.decoder = decoder
        self.responseCodeActions = responseCodeActions
    }

    public func start(_ completion: @escaping (Result<T, RequestError>) -> Void) {
        self.dataTask.start { (data, response, error) in

            let completeInMainThread: (Result<T, RequestError>) -> Void = { result in
                DispatchQueue.main.async { completion(result) }
            }

            // service error handling
            if let error = error {
                let serviceError = RequestError.serviceError(error)
                completeInMainThread(.failure(serviceError))
                return
            }

            // http error
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200

            self.responseCodeActions[statusCode]?.forEach { action in DispatchQueue.main.async { action() } }

            if (300 ... 599) ~= statusCode {
                completeInMainThread(.failure(.httpError(statusCode)))
                return
            }

            // data handling
            guard let data = data else {
                completeInMainThread(.failure(.unexpectedEmptyDataError))
                return
            }

            completeInMainThread(self.decode(data))
        }
    }
}

private extension Request {
    func decode<T: Decodable>(_ data: Data) -> Result<T, RequestError> {

        do {
            return .success(try self.decoder.decode(T.self, from: data))
        } catch {
            return .failure(.decodingError(error, data))
        }
    }
}
