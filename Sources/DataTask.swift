//
//  DataTask.swift
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

    func start(_ completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        // to do mocking
        completion(nil, nil , nil)
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
