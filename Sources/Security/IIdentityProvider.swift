//
//  IIdentityProvider.swift
//  
//
//  Created by Valentin Cherepyanko on 20.04.2021.
//

import Foundation

public protocol IIdentityProvider {
    var identity: SecIdentity? { get }
}
