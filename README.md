# VCNetworking
Simple and declarative builder for your network requests.

## Usage example
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

Request holds a strong link to himself until response.
If you need lifecycle management for your async operations, you can use promises.

## Installation
For now VCNetworking supports installation through SPM 📦
