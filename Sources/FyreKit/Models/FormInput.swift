//
//  FormInput.swift
//  
//
//  Created by Dane Wilson on 10/14/22.
//

import SwiftUI

public struct FormInput : Identifiable {
  public var id: String { String(self.label) }
  
  @State public var value : String
  public var label : String
  public var type : String
  
  public init(value: String, label: String, type: String) {
    self.value = value
    self.label = label
    self.type = type
  }
}
