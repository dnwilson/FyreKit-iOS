//
//  LoginViewModel.swift
//  FyreKit
//
//  Created by Dane Wilson on 9/21/21.
//

import SwiftUI

public class LoginViewModel: ObservableObject {
  @Published var credentials = Credentials()
  @Published var showProgressView = false
  @Published var error: ApiError?
  
  var loginDisabled: Bool {
    credentials.login.isEmpty || credentials.password.isEmpty || showProgressView == true
  }
  
  public func login(completion: @escaping (Bool) -> Void) {
    showProgressView = true
    ApiService.login(credentials: credentials) {
      [unowned self](result: Result<Bool, Error>) in
      showProgressView = false
      switch result {
      case .success:
        Log.i("RESULT \(result)")
        completion(true)
      case .failure(let authError):
        credentials = Credentials()
        error = (authError as! ApiError)
        completion(false)
      }
    }
  }
}

