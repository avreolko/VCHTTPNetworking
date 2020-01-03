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
    case decodingError(Error) // user info?
}

struct Success: Decodable { }

struct Request {

    let request: URLRequest
    let session: URLSession

    func start<T: Decodable>(_ completion: @escaping (Result<T, RequestError>) -> Void) {
        self.session.dataTask(with: request) { (data, response, error) in

            // service error handling
            if let error = error {
                let serviceError = RequestError.serviceError(error)
                DispatchQueue.main.async { completion(.failure(serviceError)) }
                return
            }

            // http error
            if let httpResponse = response as? HTTPURLResponse,
                (300 ... 599) ~= httpResponse.statusCode {
                DispatchQueue.main.async { completion(.failure(.httpError(httpResponse.statusCode))) }
                return
            }

            // data handling
            if let data = data {
                DispatchQueue.main.async { completion(self.decode(data)) }
            } else { assertionFailure("Data is empty") }
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
