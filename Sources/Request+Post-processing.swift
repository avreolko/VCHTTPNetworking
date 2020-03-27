//
//  Request+Post-processing.swift
//  
//
//  Created by Черепянко Валентин Александрович on 27/03/2020.
//

import Foundation

extension Request {
    static func dataHandlers() -> [(Data) -> Data] {
        [
            self.emptyDataHandler()
        ]
    }
}
