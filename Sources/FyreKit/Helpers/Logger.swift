//
//  Logger.swift
//  
//
//  Created by Dane Wilson on 10/11/22.
//

import Foundation

extension NSObject {
  public func log(_ message: String) {
    print("\(FyreKit.appName): \(message)")
  }
}
