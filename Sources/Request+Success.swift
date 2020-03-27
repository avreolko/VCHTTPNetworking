//
//  Request+Success.swift
//  
//
//  Created by Черепянко Валентин Александрович on 27/03/2020.
//

import Foundation
import VCPromises

extension Success: Decodable {
    public init(from decoder: Decoder) throws { self = Success() }
}

extension Request {
    static func emptyDataHandler() -> (Data) -> Data {
        {
            data in guard data.isEmpty, T.self == Success.self else { return data }
            return "{}".data(using: .utf8)!
        }
    }
}
