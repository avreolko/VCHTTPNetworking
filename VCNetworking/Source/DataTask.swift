//
//  MockedURLSession.swift
//  VCNetworking
//
//  Created by Valentin Cherepyanko on 05.01.2020.
//  Copyright © 2020 Valentin Cherepyanko. All rights reserved.
//

import Foundation

protocol IDataTask {
    func start(_ completion: @escaping (Data?, URLResponse?, Error?) -> Void)
}

struct MockedDataTask: IDataTask {

    let filename: String
    let stubs: Bundle?

    func start(_ completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        guard
            let path = stubs?.path(forResource: self.filename, ofType: ".json", inDirectory: ""),
            let data = try? String(contentsOfFile: path).data(using: .utf8)!
        else {
            completion(nil, nil, nil)
            return
        }

        completion(data, nil , nil)
    }
}

struct DataTask: IDataTask {

    let request: URLRequest
    let session: URLSession

    func start(_ completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        self.session.dataTask(with: request) { (data, response, error) in
            completion(data, response, error)
        }.resume()
    }
}
