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
  var type: String?
  var script: String?
  var alertMessage: String?
  var alertTitle: String?
  var isDanger: Bool { type == "danger" }
  var isGet: Bool { path != nil }
  var isScript: Bool { !isGet || ((script?.isPresent) != nil) }

  public init(_ params: [String: Any]) {
    self.title = params["title"] as? String
    self.icon = params["icon"] as? String
    self.path = params["path"] as? String
    self.script = params["script"] as? String
    self.alertMessage = params["alertMessage"] as? String
    self.alertTitle = params["alertTitle"] as? String
    self.type = params["type"] as? String ?? "default"
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
