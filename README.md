# VCNetworking
A simple declarative builder for your network requests

## Installation
Install with SPM 📦

## Usage
```swift
let requestBuilder = RequestBuilder(baseURL: URL(string: "<some url>")!)

let request: Request<ResponseType> =
    requestBuilder
        .method(.get)
        .basicAuth(login: "login", pass: "pass")
        .headers(["key": "value"])
        .path("endpoint")
        .build()

request.start { result in
    switch result {
    case .success(let response): ()
    case .failure(let error): ()
    }
}
```

The request holds a strong reference to itself until a response.
If you need lifecycle management for your async operations, you can use promises.

## License ##
This project is released under the [MIT license](https://en.wikipedia.org/wiki/MIT_License).
