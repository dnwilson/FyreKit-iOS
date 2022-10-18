//
//  TurboButton.swift
//  
//
//  Created by Dane Wilson on 10/11/22.
//

import UIKit

public struct TurboButton {
  var title: String?
  var icon: String?
  var path: String?
  var script: String?
  var isGet: Bool { path != nil }
  var isScript: Bool { !isGet }

  public init(_ message: [String: Any]) {
    self.title = message["title"] as? String
    self.icon = message["icon"] as? String
    self.path = message["path"] as? String
    self.script = message["script"] as? String
  }
  
  public static func buildButtons(_ buttons: [[String: Any]]) -> [TurboButton] {
    var list: [TurboButton] = []
    for button in buttons { list.append(TurboButton(button)) }

    return list
  }
}

class TurboUIBarButton: UIBarButtonItem {
  var actionString: String = ""
}
