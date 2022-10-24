//
//  Credentials.swift
//  FyreKit
//
//  Created by Dane Wilson on 9/21/21.
//

public protocol Authenticatable : Encodable {
  var phoneNumber: String { get set }
  var password: String { get set }
}
