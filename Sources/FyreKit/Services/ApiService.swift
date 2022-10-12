//
//  ApiService.swift
//  FyreKit
//
//  Created by Dane Wilson on 9/21/21.
//

import Foundation
import Turbo
import WebKit

struct ApiError: Codable, Error, Identifiable {
  var id: String { String(self.code) }
  var error: String = ""
  var code: Int = 0
  
  func message() -> String { self.error }
}


extension URLSession {
  func request(url: URL, type: String = "GET") -> URLRequest {
    var request = URLRequest(url: url)
    request.httpMethod = type
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue(FyreKit.userAgent, forHTTPHeaderField: "User-Agent")

    if let token = FyreKit.authToken {
      var request = URLRequest(url: url)
      request.setValue("Bearer: \(token)", forHTTPHeaderField: "Authorization")
    }
    
    return request
  }
  
  func get<T: Codable>(
    url: URL?,
    expecting: T.Type,
    completion: @escaping (Result<T, Error>) -> Void
  ) {
    guard let url = url else {
      completion(.failure(ApiError(error: "Invalid url", code: 1)))
      return
    }
    
    let request = request(url: url)
    
    let task = dataTask(with: request) { data, _, error in
      guard let data = data else {
        if let error = error {
          completion(.failure(error))
        } else {
          completion(.failure(ApiError(error: "Invalid data", code: 2)))
        }
        return
      }
      
      do {
        let result = try JSONDecoder().decode(expecting, from: data)
        completion(.success(result))
      }
      catch {
        completion(.failure(error))
      }
    }
    
    task.resume()
  }
  
  func post<T: Codable>(
    url: URL?,
    body: [String: Any],
    expecting: T.Type,
    completion: @escaping (Result<T, Error>) -> Void
  ) {
    guard let url = url else {
      completion(.failure(ApiError(error: "Invalid url", code: 1)))
      return
    }
    
    var request = request(url: url, type: "POST")
    
    let json: Data = try! JSONSerialization.data(withJSONObject: body, options: [])
    
    request.httpBody = json
    
    let task = dataTask(with: request) { data, response, error in
      guard
        error == nil,
        let response = response as? HTTPURLResponse,
        // Ensure the response was successful
        (200 ..< 300).contains(response.statusCode),
        let data = data
      else {
        if let error = error {
          completion(.failure(error))
        } else {
          let apiError = try! JSONDecoder().decode(ApiError.self, from: data!)
          completion(.failure(apiError))
        }
        return
      }
      
      do {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let result = try decoder.decode(expecting, from: data)
        completion(.success(result))
      }
      catch {
        completion(.failure(error))
      }
    }
    
    task.resume()
  }
  
  func login(credentials: Credentials, completion: @escaping (Result<Bool, Error>) -> Void) {
    var request = request(url: FyreKit.fullUrl("api/login"), type: "POST")

    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    request.httpBody = try? encoder.encode(credentials)
    
    let task = dataTask(with: request) { data, response, error in
      guard
        error == nil,
        let response = response as? HTTPURLResponse,
        (200 ..< 300).contains(response.statusCode),
        let headers = response.allHeaderFields as? [String: String],
        let data = data,
        let token = try? JSONDecoder().decode(AccessToken.self, from: data)
      else {
        if error != nil {
          FyreKit.setKeychainValue(nil, key: "access-token")
          let apiError = try! JSONDecoder().decode(ApiError.self, from: data!)
          completion(.failure(apiError))
        } else {
          completion(.failure(ApiError(error: "Unexpected server error", code: 400)))
        }
        return
      }

      DispatchQueue.main.async {
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: headers, for: FyreKit.rootURL)
        HTTPCookieStorage.shared.setCookies(cookies, for: FyreKit.rootURL, mainDocumentURL: nil)
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        cookies.forEach { cookie in
          cookieStore.setCookie(cookie, completionHandler: nil)
        }
        FyreKit.setKeychainValue(token.token, key: "access-token")
        Session().reload()
        FyreKit.setPref(true, key: "LoggedIn")
        completion(.success(true))
      }
    }
    
    task.resume()
  }
  
  func register(registration: Registration, completion: @escaping (Result<Bool, Error>) -> Void) {
    var request = request(url: FyreKit.fullUrl("api/register"), type: "POST")

    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    request.httpBody = try? encoder.encode(registration)
    
    let task = dataTask(with: request) { data, response, error in
      guard
        error == nil,
        let response = response as? HTTPURLResponse,
        (200 ..< 300).contains(response.statusCode),
        let headers = response.allHeaderFields as? [String: String],
        let data = data,
        let token = try? JSONDecoder().decode(AccessToken.self, from: data)
      else {
        if let error = error {
          completion(.failure(error))
        } else {
          if let apiError = try? JSONDecoder().decode(ApiError.self, from: data!) {
            completion(.failure(apiError))
          } else {
            completion(.failure(ApiError(error: "Unexpected server error", code: 400)))
          }
        }

        return
      }
      
      DispatchQueue.main.async {
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: headers, for: FyreKit.rootURL)
        HTTPCookieStorage.shared.setCookies(cookies, for: FyreKit.rootURL, mainDocumentURL: nil)
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        cookies.forEach { cookie in
          cookieStore.setCookie(cookie, completionHandler: nil)
        }
        FyreKit.setKeychainValue(token.token, key: "access-token")
        Session().reload()
        FyreKit.setPref(true, key: "LoggedIn")
        completion(.success(true))
      }
    }
    
    task.resume()
  }
  
  private struct AccessToken: Decodable {
    let token: String
  }
}
