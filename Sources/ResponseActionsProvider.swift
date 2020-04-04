//
//  ResponseActionsProvider.swift
//  
//
//  Created by Черепянко Валентин Александрович on 04/04/2020.
//

public typealias ResponseCode = Int
public typealias Action = () -> Void

public protocol IResponseActionsProvider {
    var actions: [ResponseCode: [Action]] { get }
}
