//
//  ApiService.swift
//  FyreKit
//
//  Created by Dane Wilson on 9/21/21.
//

import Foundation
import Turbo
import WebKit

public struct ApiError: Codable, Error, Identifiable {
  public var id: String { String(self.code) }
  public var error: String = ""
  public var code: Int = 0
  
  public func message() -> String { self.error }
}

public class ApiService {
  static func request(url: URL, type: String = "GET") -> URLRequest {
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
  
  public static func get(_ path: String) -> String {
    var text: String = ""
    let semaphore = DispatchSemaphore(value: 0)
    let task = URLSession.shared.dataTask(with: FyreKit.fullUrl(path)) {(data, response, error) in
      if (data != nil) {
        text = String(data: data!, encoding: String.Encoding.utf8)!
      }
      semaphore.signal()
    }
    task.resume()
    semaphore.wait()
    return text
  }

  public static func get<T: Codable>(
    url: URL?,
    expecting: T.Type,
    completion: @escaping (Result<T, Error>) -> Void
  ) {
    guard let url = url else {
      completion(.failure(ApiError(error: "Invalid url", code: 1)))
      return
    }

    let request = request(url: url)

    let task = URLSession.shared.dataTask(with: request) { data, _, error in
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

  public static func post<T: Codable>(
    path: String,
    body: [String: Any],
    expecting: T.Type,
    completion: @escaping (Result<T, Error>) -> Void
  ) {
    var request = request(url: FyreKit.fullUrl(path), type: "POST")
    let json: Data = try! JSONSerialization.data(withJSONObject: body, options: [])

    request.httpBody = json

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
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

  public static func login(credentials: Authenticatable, completion: @escaping (Result<Bool, Error>) -> Void) {
    var request = request(url: FyreKit.fullUrl("api/login"), type: "POST")

    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    request.httpBody = try? encoder.encode(credentials)

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      guard
        error == nil,
        let response = response as? HTTPURLResponse,
        (200 ..< 300).contains(response.statusCode),
        let headers = response.allHeaderFields as? [String: String],
        let data = data,
        let login = try? JSONDecoder().decode(LoginResponse.self, from: data)
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

        FyreKit.setKeychainValue(login.token, key: "access-token")
        Session().reload()
        FyreKit.setPref(true, key: "LoggedIn")
        FyreKit.setPref(login.user.id!, key: "UserId")
        completion(.success(true))
      }
    }

    task.resume()
  }

  public static func register(registration: Registerable, completion: @escaping (Result<Bool, Error>) -> Void) {
    var request = request(url: FyreKit.fullUrl("api/register"), type: "POST")

    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    request.httpBody = try? encoder.encode(registration)

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      guard
        error == nil,
        let response = response as? HTTPURLResponse,
        (200 ..< 300).contains(response.statusCode),
        let headers = response.allHeaderFields as? [String: String],
        let data = data,
        let login = try? JSONDecoder().decode(LoginResponse.self, from: data)
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
        FyreKit.setKeychainValue(login.token, key: "access-token")
        Session().reload()
        FyreKit.setPref(true, key: "LoggedIn")
        FyreKit.setPref(login.user.id!, key: "UserId")
        completion(.success(true))
      }
    }

    task.resume()
  }

  private struct LoginResponse: Decodable {
    let token: String
    let user : TMSUser
  }
}
