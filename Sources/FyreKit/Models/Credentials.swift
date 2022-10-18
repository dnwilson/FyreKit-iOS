//
//  Credentials.swift
//  FyreKit
//
//  Created by Dane Wilson on 9/21/21.
//

public class Credentials: Encodable {
  var password: String = ""
  var phoneNumber: String = ""
  var email: String = ""
  var username: String = ""

  var login : String {
    if (!username.isEmpty) {
      return username
    } else if (!email.isEmpty) {
      return email
    } else {
      return phoneNumber
    }
  }
}
