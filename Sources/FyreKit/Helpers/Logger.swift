//
//  Logger.swift
//  
//
//  Created by Dane Wilson on 10/11/22.
//

import SwiftUI

public class Log {
  public class func i(_ message: String) {
    print("[\(FyreKit.appName)] \(message)")
  }
}
