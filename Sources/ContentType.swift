//
//  ContentType.swift
//  VCHTTPNetworking
//
//  Created by Valentin Cherepyanko on 26.04.2021.
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

// full list: https://www.iana.org/assignments/media-types/media-types.xhtml
public enum ContentType {
    case json, css, csv, html, gif, jpeg, png, pdf, rar, txt, xml, zip, form
    case custom(value: String)
}

extension ContentType {

    public var rawValue: String {
        switch self {
        case .json: return "application/json"
        case .css: return "text/css"
        case .csv: return "text/csv"
        case .html: return "text/html"
        case .gif: return "image/gif"
        case .jpeg: return "image/jpeg"
        case .png: return "image/png"
        case .pdf: return "application/pdf"
        case .rar: return "application/vnd.rar"
        case .txt: return "text/plain"
        case .xml: return "application/xml"
        case .zip: return "application/zip"
        case .form: return "application/x-www-form-urlencoded"
        case .custom(value: let value): return value
        }
    }
}
