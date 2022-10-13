//
//  PhoneNumberViewModel.swift
//  
//
//  Created by Dane Wilson on 10/11/22.
//

import SwiftUI

public class PhoneNumberViewModel: ObservableObject {
  @Published var id = ""
  @Published var number = ""
  @Published var code = ""
  @Published var status = ""
  @Published var waitingForCode = false
  @Published var showProgressView = false
  @Published var error: ApiError?
  
  public var isValid: Bool {
    return !number.isEmpty || !(code.isEmpty && number.isEmpty)
  }
  
  public var disabled: Bool {
    return !isValid || showProgressView == true
  }
  
  public func checkPhoneNumber(completion: @escaping (Bool) -> Void) {
    showProgressView = true
    
    let url = FyreKit.fullUrl("phone-numbers")
    let data = [
      "phone_number": [
        "phone_number": number
      ]
    ]
    
    URLSession.shared.post(
      url: url, body: data, expecting: PhoneNumber.self
    ) { [weak self] result in
      
      DispatchQueue.main.async {
        self!.showProgressView = false
      }
      switch result {
      case .success(let phoneNumber):
        DispatchQueue.main.async {
          if let _id = phoneNumber.id { self?.id = _id }
          self?.code = phoneNumber.code ?? ""
          self?.status = phoneNumber.status ?? ""
        }
        completion(true)
      case .failure(let responseError):
        DispatchQueue.main.async {
          let apiError = responseError as? ApiError
          self?.number = ""
          self?.code = ""
          self?.id = ""
          self?.status = ""
          self?.waitingForCode = apiError?.code == 202
          self!.error = responseError as? ApiError
        }
        completion(false)
      }
    }
  }
  
  public func verifyPhoneNumber(completion: @escaping (Bool) -> Void) {
    showProgressView = true
    
    let url = FyreKit.fullUrl("phone-numbers/\(String(describing: id))/verify")
    let data = [
      "phone_number": [
        "id": id,
        "phone_number": number,
        "code": code
      ]
    ]
    
    URLSession.shared.post(
      url: url, body: data, expecting: PhoneNumber.self
    ) { [weak self] result in
      
      DispatchQueue.main.async {
        self!.showProgressView = false
      }
      switch result {
      case .success(let phoneNumber):
        DispatchQueue.main.async {
          self?.waitingForCode = true
          self?.number = phoneNumber.phoneNumber
          self?.id = phoneNumber.id ?? ""
          self?.code = phoneNumber.code ?? ""
        }
        completion(true)
      case .failure(let responseError):
        DispatchQueue.main.async {
          let apiError = responseError as? ApiError
          self?.waitingForCode = apiError?.code == 202
          self!.error = responseError as? ApiError
        }
        completion(false)
      }
    }
  }
}
