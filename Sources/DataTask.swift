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

final class DataTask: NSObject, IDataTask {

    private lazy var session = URLSession(configuration: self.sessionConfiguration, delegate: self, delegateQueue: nil)

    private(set) var request: URLRequest
    private let encodeAction: (() -> Data?)?
    private let sessionConfiguration: URLSessionConfiguration
    private let pinnedCertificatesProvider: ICertificatesProvider?
    private let identityProvider: IIdentityProvider?

    init(request: URLRequest,
         encodeAction: (() -> Data?)? = nil,
         sessionConfiguration: URLSessionConfiguration,
         pinnedCertificatesProvider: ICertificatesProvider? = nil,
         identityProvider: IIdentityProvider? = nil) {

        self.request = request
        self.encodeAction = encodeAction
        self.sessionConfiguration = sessionConfiguration
        self.pinnedCertificatesProvider = pinnedCertificatesProvider
        self.identityProvider = identityProvider
    }

    func start(_ completion: @escaping (Data?, URLResponse?, Error?) -> Void) {

        DispatchQueue.global(qos: .userInitiated).async {

            self.encodeAction.map { self.request.httpBody = $0() }

            self.session.dataTask(with: self.request) { (data, response, error) in
                completion(data, response, error)
                self.session.finishTasksAndInvalidate()
            }.resume()
        }
    }
}

// MARK: - URLSessionDelegate
extension DataTask: URLSessionDelegate {

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        let authenticationMethod = challenge.protectionSpace.authenticationMethod

        if authenticationMethod == NSURLAuthenticationMethodServerTrust {
            didReceive(serverTrustChallenge: challenge, completionHandler: completionHandler)
        } else if authenticationMethod == NSURLAuthenticationMethodClientCertificate {
            didReceive(clientIdentityChallenge: challenge, completionHandler: completionHandler)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// MARK: - DataTask challenge handle methods
private extension DataTask {

    func didReceive(serverTrustChallenge challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        guard let pinnedCertificates = pinnedCertificatesProvider?.certificates,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        if serverTrust.evaluateAllowing(rootCertificates: []) && serverTrust.pin(with: pinnedCertificates) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    func didReceive(clientIdentityChallenge challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        guard let identityProvider = identityProvider else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        guard let clientIdentity = identityProvider.identity else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let credential = URLCredential(identity: clientIdentity, certificates: nil, persistence: .forSession)
        completionHandler(.useCredential, credential)
    }
}

// MARK: - SecTrust convenience methods
private extension SecTrust {

    var allowedTrustTypes: [SecTrustResultType] {
        [.proceed, .unspecified]
    }

    func evaluateAllowing(rootCertificates: [SecCertificate]) -> Bool {

        if rootCertificates.count > 0 {
            var err = SecTrustSetAnchorCertificates(self, rootCertificates as CFArray)
            guard err == errSecSuccess else { return false }

            err = SecTrustSetAnchorCertificatesOnly(self, false)
            guard err == errSecSuccess else { return false }
        }

        return evaluate()
    }

    func evaluate() -> Bool {
        var trustResult: SecTrustResultType = .invalid
        let err = SecTrustEvaluate(self, &trustResult)
        guard err == errSecSuccess else { return false }
        return allowedTrustTypes.contains(trustResult)
    }

    func pin(with localCertificates: [SecCertificate]) -> Bool {
        guard let remoteCertificate = SecTrustGetCertificateAtIndex(self, 0) else { return true }
        let remoteCertificateData = SecCertificateCopyData(remoteCertificate) as Data
        let localCertificatesData = localCertificates.map { SecCertificateCopyData($0) as Data }
        return localCertificatesData.contains(remoteCertificateData)
    }
}
