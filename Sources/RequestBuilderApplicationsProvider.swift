//
//  RequestBuilderApplicationsProvider.swift
//  
//
//  Created by Черепянко Валентин Александрович on 04/04/2020.
//

import Foundation

public protocol IRequestBuilderApplicationsProvider {
    var applications: [RequestBuilderApplication] { get }
}
