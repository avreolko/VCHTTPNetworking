//
//  Promise.swift
//  VCNetworking
//
//  Created by Valentin Cherepyanko on 06.01.2020.
//  Copyright © 2020 Valentin Cherepyanko. All rights reserved.
//

struct Callback<Value> {
    let fulfill: (Value) -> Void
    let reject: (Error) -> Void
}

public class Promise<Value> {

    enum State<Value> {
        case pending([Callback<Value>])
        case fulfilled(Value)
        case rejected(Error)
    }

    private var state: State<Value>

    public init() {
        self.state = .pending([])
    }

    public init(value: Value) {
        self.state = .fulfilled(value)
    }

    public init(error: Error) {
        self.state = .rejected(error)
    }

    public convenience init(work: @escaping (_ fulfill: @escaping (Value) -> Void, _ reject: @escaping (Error) -> Void) throws -> Void) {
        self.init()

        do {
            try work(self.fulfill, self.reject)
        } catch let error {
            self.reject(error)
        }
    }

    public func reject(_ error: Error) {
        self.updateState(.rejected(error))
    }

    public func fulfill(_ value: Value) {
        self.updateState(.fulfilled(value))
    }

    @discardableResult
    public func `catch`(_ reject: @escaping (Error) -> Void) -> Promise<Value> {
        return self.then ({ _ in }, reject)
    }

    internal func addCallbacks(_ fulfill: @escaping (Value) -> Void,
                      _ reject: @escaping (Error) -> Void) {

        let callback = Callback(fulfill: fulfill, reject: reject)

        switch self.state {
        case .pending(let callbacks):
            self.state = .pending(callbacks + [callback])
        case .fulfilled(let value):
            callback.fulfill(value)
        case .rejected(let error):
            callback.reject(error)
        }
    }
}

private extension Promise {

    func updateState(_ newState: State<Value>) {
        guard case .pending(let callbacks) = self.state else { return }
        self.state = newState
        self.fireIfCompleted(callbacks: callbacks)
    }

    func fireIfCompleted(callbacks: [Callback<Value>]) {

        guard let callback = callbacks.first else {
            return
        }

        switch self.state {
        case .pending: break
        case .fulfilled(let value): callback.fulfill(value)
        case .rejected(let error): callback.reject(error)
        }
    }
}
