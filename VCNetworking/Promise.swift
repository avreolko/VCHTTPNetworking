//
//  Promise.swift
//  VCNetworking
//
//  Created by Valentin Cherepyanko on 06.01.2020.
//  Copyright © 2020 Valentin Cherepyanko. All rights reserved.
//

public class Promise<Value> {

    public var result: Result<Value, RequestError>? {
        didSet { self.result.map(report) }
    }

    private lazy var callbacks = [(Result<Value, RequestError>) -> Void]()

    public func observe(with callback: @escaping (Result<Value, RequestError>) -> Void) {
        self.callbacks.append(callback)
        self.result.map(callback)
    }

    private func report(result: Result<Value, RequestError>) {
        for callback in callbacks {
            callback(result)
        }
    }
}
