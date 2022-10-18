//
//  File.swift
//  
//
//  Created by Dane Wilson on 10/12/22.
//

import SwiftUI

public extension UIColor {
  convenience init?(hexRGBA: String?) {
    guard let rgba = hexRGBA, let val = Int(rgba.replacingOccurrences(of: "#", with: ""), radix: 16) else {
      return nil
    }
    self.init(red: CGFloat((val >> 24) & 0xff) / 255.0, green: CGFloat((val >> 16) & 0xff) / 255.0, blue: CGFloat((val >> 8) & 0xff) / 255.0, alpha: CGFloat(val & 0xff) / 255.0)
  }
  
  convenience init?(hexRGB: String?) {
    guard let rgb = hexRGB else {
      return nil
    }
    self.init(hexRGBA: rgb + "ff")
  }
}

extension UIAlertAction {
  var titleTextColor: UIColor? {
    get {
      return self.value(forKey: "titleTextColor") as? UIColor
    } set {
      self.setValue(newValue, forKey: "titleTextColor")
    }
  }
}
