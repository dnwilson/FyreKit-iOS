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
    credentials.phoneNumber.isEmpty || credentials.password.isEmpty || showProgressView == true
  }
  
  public func login(completion: @escaping (Bool) -> Void) {
    showProgressView = true
    URLSession.shared.login(credentials: credentials) {
      [unowned self](result: Result<Bool, Error>) in
      showProgressView = false
      switch result {
      case .success:
        completion(true)
      case .failure(let authError):
        credentials = Credentials()
        error = (authError as! ApiError)
        completion(false)
      }
    }
  }
}
