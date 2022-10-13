//
//  RegistrationViewModel.swift
//  FyreKit
//
//  Created by Dane Wilson on 1/25/22.
//

import SwiftUI

public class RegistrationViewModel: ObservableObject {
  @Published var id = ""
  @Published var code = ""
  @Published var phoneNumber = ""
  @Published var firstName = ""
  @Published var lastName = ""
  @Published var dreNumber = ""
  @Published var email = ""
  @Published var password = ""
  @Published var agreeTerms = false
  
  @Published var showProgressView = false
  @Published var error: ApiError?
  
  public var privacyUrl = FyreKit.fullUrl("privacy-policy")
  public var termsUrl = FyreKit.fullUrl("terms-of-service")
  
  public init(number: String) {
    self.phoneNumber = number
  }
  
  public var submitDisabled: Bool {
    firstName.isEmpty || lastName.isEmpty || email.isEmpty || dreNumber.isEmpty ||
    phoneNumber.isEmpty || password.isEmpty || agreeTerms == false
  }
  
  public var isValid: Bool {
    phoneNumberValid || !(code.isEmpty && phoneNumber.isEmpty)
  }
  
  public var phoneNumberValid: Bool {
    let phoneRegex = "^[0-9+]{0,1}+[0-9]{5,16}$"
    let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
    return phoneTest.evaluate(with: phoneNumber)
  }

  public func clearForm() {
    phoneNumber = ""
    firstName = ""
    lastName = ""
    dreNumber = ""
    email = ""
    password = ""
  }

  public func register(completion: @escaping (Bool) -> Void) {
    showProgressView = true
    let registration = Registration(
      phoneNumber: phoneNumber, firstName: firstName, lastName: lastName,
      dreNumber: dreNumber, email: email, password: password,
      agreeToLegalTerms: agreeTerms
    )
    URLSession.shared.register(registration: registration) {
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
