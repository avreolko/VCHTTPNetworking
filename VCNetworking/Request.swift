//
//  Request.swift
//  VCNetworking
//
//  Created by Valentin Cherepyanko on 03.01.2020.
//  Copyright © 2020 Valentin Cherepyanko. All rights reserved.
//

import Foundation

enum RequestError: Error {
    case serviceError(Error)
    case httpError(Int)
    case decodingError(Error)
    case unexpectedEmptyDataError
}

struct Success: Decodable { }

struct Request<T: Decodable> {

    let request: URLRequest
    let session: URLSession

    func start(_ completion: @escaping (Result<T, RequestError>) -> Void) {
        self.session.dataTask(with: request) { (data, response, error) in

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
            if let httpResponse = response as? HTTPURLResponse,
                (300 ... 599) ~= httpResponse.statusCode {
                completeInMainThread(.failure(.httpError(httpResponse.statusCode)))
                return
            }

            guard var data = data else {
                completeInMainThread(.failure(.unexpectedEmptyDataError))
                return assertionFailure("Data is nil")
            }

            // data handling
            if data.isEmpty, T.self == Success.self { data = "{}".data(using: .utf8)! }
            completeInMainThread(self.decode(data))
        }.resume()
    }
}

private extension Request {
    func decode<T: Decodable>(_ data: Data) -> Result<T, RequestError> {
        let decoder = JSONDecoder()
        do {
            return .success(try decoder.decode(T.self, from: data))
        } catch {
            return .failure(.decodingError(error))
        }
    }
}
