//
//  Request.swift
//  VCNetworking
//
//  Created by Valentin Cherepyanko on 03.01.2020.
//  Copyright © 2020 Valentin Cherepyanko. All rights reserved.
//

import Foundation

public enum RequestError<APIError>: Error {
    case serviceError(Error)
    case httpError(Int)
    case decodingError(Error, Data)
    case apiError(APIError)
    case unexpectedEmptyDataError
}

public struct Success: Decodable { public init() { } }

public struct Request<Response: Decodable, APIError: Decodable> {

    let dataTask: IDataTask

    private let responseCodeActions: [ResponseCode: [Action]]

    init(dataTask: IDataTask,
         responseCodeActions: [ResponseCode: [Action]]) {

        self.dataTask = dataTask
        self.responseCodeActions = responseCodeActions
    }

    public func start(_ completion: @escaping (Result<Response, RequestError<APIError>>) -> Void) {
        self.dataTask.start { (data, response, error) in

            let completeInMainThread: (Result<Response, RequestError>) -> Void = { result in
                DispatchQueue.main.async { completion(result) }
            }

            // service error handling
            if let error = error {
                let serviceError = RequestError<APIError>.serviceError(error)
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
    func decode(_ data: Data) -> Result<Response, RequestError<APIError>> {

        let data = (Response.self == Success.self)
            ? "{}".data(using: .utf8)!
            : data

        let decoder = JSONDecoder()

        do {
            let response = try decoder.decode(Response.self, from: data)
            return .success(response)
        } catch {
            do {
                let apiError = try decoder.decode(APIError.self, from: data)
                return .failure(.apiError(apiError))
            } catch {
                return .failure(.decodingError(error, data))
            }
        }
    }
}
