//
//  RequestBuilderApplicationsProvider.swift
//  
//
//  Created by Черепянко Валентин Александрович on 04/04/2020.
//

public typealias RequestBuilderApplication = (RequestBuilder) -> Void

public protocol IRequestBuilderApplicationsProvider {
    var applications: [RequestBuilderApplication] { get }
}
