//
//  DataTask.swift
//  VCHTTPNetworking
//
//  Created by Valentin Cherepyanko on 05.01.2020.
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

protocol IDataTask {
    func start(_ completion: @escaping (Data?, URLResponse?, Error?) -> Void)
}

struct MockedDataTask: IDataTask {

    let data: Data?
    let error: Error?

    func start(_ completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        completion(self.data, nil , self.error)
    }
}

final class DataTask: IDataTask {

    private lazy var session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)

    private(set) var request: URLRequest
    let encodeAction: (() -> Data?)?

    init(request: URLRequest, encodeAction: (() -> Data?)? = nil) {

        self.request = request
        self.encodeAction = encodeAction
    }

    func start(_ completion: @escaping (Data?, URLResponse?, Error?) -> Void) {

        DispatchQueue.global(qos: .userInitiated).async {

            self.encodeAction.map { self.request.httpBody = $0() }

            self.session.dataTask(with: self.request) { (data, response, error) in
                completion(data, response, error)
                self.session.finishTasksAndInvalidate()
            }.resume()
        }

        self.session.dataTask(with: request) { (data, response, error) in
            completion(data, response, error)
        }.resume()
    }
}
