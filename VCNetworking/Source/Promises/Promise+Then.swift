//
//  Promise+Then.swift
//  VCNetworking
//
//  Created by Valentin Cherepyanko on 08.01.2020.
//  Copyright © 2020 Valentin Cherepyanko. All rights reserved.
//

import Foundation

extension Promise {
    // flatMap
    @discardableResult
    public func then<NewValue>(_ onFulfill:@escaping (Value) throws -> Promise<NewValue>) -> Promise<NewValue> {

        return Promise<NewValue>(work: { fulfill, reject in
            self.addCallbacks({ value in
                do {
                    try onFulfill(value).then(fulfill, reject)
                } catch let error {
                    reject(error)
                }
            }, reject)
        })
    }

    // map
    @discardableResult
    public func then<NewValue>(_ onFullfill: @escaping (Value) throws -> NewValue) -> Promise<NewValue> {
        return self.then { (value) -> Promise<NewValue> in
            do {
                return Promise<NewValue>(value: try onFullfill(value))
            } catch let error {
                return Promise<NewValue>(error: error)
            }
        }
    }

    @discardableResult
    public func then(_ fullfill: @escaping (Value) -> Void,
                     _ reject: @escaping (Error) -> Void = { _ in }) -> Promise<Value> {
        self.addCallbacks(fullfill, reject)
        return self
    }
}
