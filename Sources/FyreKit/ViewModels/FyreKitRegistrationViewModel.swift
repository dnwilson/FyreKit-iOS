//
//  FyreKitRegistrationViewModel.swift
//  
//
//  Created by Dane Wilson on 10/13/22.
//

import SwiftUI

public protocol RegisterableViewModel {
  var showProgressView : Bool { get set }
  var submitDisabled: Bool { get }
  var isValid: Bool { get }
  var agreeTerms: Bool { get set }
  var termsMessage: String { get }
  var error: ApiError? { get set }

  init(number: String)

  func clearForm()
  
  func registration() -> FyreKitRegistration

  func register(completion: @escaping (Bool) -> Void)
}

open class FyreKitRegistrationViewModel : RegisterableViewModel, ObservableObject {
  @Published public var showProgressView: Bool = false
  @Published public var error: ApiError?
  @Published public var agreeTerms: Bool
  @Published public var password: String

  required public init(number: String) {
    self.password = ""
    self.agreeTerms = false
  }
  
  public var submitDisabled: Bool {
    return !isValid
  }

  open var formInputs : [FormInput] {
    return (
      [
        FormInput(value: password, label: "Password", type: "password"),
      ]
    )
  }

  open var termsMessage: String { "" }
  
  open var isValid: Bool {
    return password.isPresent
  }

  open func clearForm() {
    Log.i("Need to be implemented")
  }
  
  open func registration() -> FyreKitRegistration {
    let registration = FyreKitRegistration()
    registration.password = password
    return registration
  }
  
  open func register(completion: @escaping (Bool) -> Void) {
    showProgressView = false
    
    ApiService.register(registration: registration()) {
      [unowned self](result: Result<Bool, Error>) in
      DispatchQueue.main.async { [self] in showProgressView = false }
      switch result {
      case .success:
        completion(true)
      case .failure(let authError):
        DispatchQueue.main.async { self.error = authError as? ApiError }
        completion(false)
      }
    }
  }
}
