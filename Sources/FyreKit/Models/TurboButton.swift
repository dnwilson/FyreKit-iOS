//
//  TurboButton.swift
//  
//
//  Created by Dane Wilson on 10/11/22.
//

import UIKit

public struct TurboButton {
  public var title: String?
  public var icon: String?
  public var path: String?
  public var type: String?
  public var script: String?
  public var alertMessage: String?
  public var alertTitle: String?
  public var isDanger: Bool { type == "danger" }
  public var isGet: Bool { path != nil }
  public var isScript: Bool { !isGet || ((script?.isPresent) != nil) }

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

public class TurboUIBarButton: UIBarButtonItem {
  var actionString: String = ""
}
