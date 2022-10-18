//
//  FyreKitRegistration.swift
//  
//
//  Created by Dane Wilson on 10/13/22.
//

import Foundation

public protocol Registerable: Codable {
  var password : String { get set }
  
  func isValid() -> Bool
}

open class FyreKitRegistration : Registerable {
//  var phoneNumber: String = ""
//  var firstName: String = ""
//  var lastName: String = ""
//  var email: String = ""
  var agreeToLegalTerms: Bool = false
  public var password: String = ""
  
  open func isValid() -> Bool {
    return password.isPresent && agreeToLegalTerms
  }
}


extension String {
  public var isPresent : Bool {
    !isEmpty
  }
}
