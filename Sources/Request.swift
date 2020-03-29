//
//  Request.swift
//  VCNetworking
//
//  Created by Valentin Cherepyanko on 03.01.2020.
//  Copyright © 2020 Valentin Cherepyanko. All rights reserved.
//

import Foundation

public enum RequestError: Error {
    case serviceError(Error)
    case httpError(Int)
    case decodingError(Error)
    case unexpectedEmptyDataError
}

public struct Success: Decodable { public init() { } }

public struct Request<T: Decodable> {

    let dataTask: IDataTask
    private let responseCodeActions: [ResponseCode: [Action]]

    init(dataTask: IDataTask,
         responseCodeActions: [ResponseCode: [Action]]) {

        self.dataTask = dataTask
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
                return assertionFailure("Data is nil")
            }

            completeInMainThread(self.decode(data))
        }
    }
}

private extension Request {
    func decode<T: Decodable>(_ data: Data) -> Result<T, RequestError> {

        let data = (T.self == Success.self)
            ? "{}".data(using: .utf8)!
            : data

        let decoder = JSONDecoder()
        do {
            return .success(try decoder.decode(T.self, from: data))
        } catch {
            return .failure(.decodingError(error))
        }
    }
}
