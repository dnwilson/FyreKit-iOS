//
//  ScriptMessageHandler.swift
//  FyreKit
//
//  Created by Dane Wilson on 9/21/21.
//

import WebKit

public protocol ScriptMessageDelegate: AnyObject {
  func addActionButton(_ button: TurboButton)
  func addMenuButton(_ menuOptions: [[String: String]])
  func addSegmentedPicker(buttons: [TurboButton])
//  func addMapLink(location: TMSLocation)
  func dismissModal()
}

public class ScriptMessageHandler: NSObject, WKScriptMessageHandler {
  private weak var delegate: ScriptMessageDelegate?
  
  init(delegate: ScriptMessageDelegate) {
    self.delegate = delegate
  }
  
  public func userContentController(
    _ userContentController: WKUserContentController,
    didReceive message: WKScriptMessage
  ) {
    guard
      let body = message.body as? [String: Any],
      let name = body["name"] as? String
    else {
      print("FyreKit: there was an error")
      return
    }
    
    print("FyreKit: JS message", name, "body", body)
    
    switch name {
    case "ActionButton":
      let button = TurboButton(body)
      delegate?.addActionButton(button)
    case "Modal":
      let options = body["options"] as! [String: Any]
      let action = options["action"] as! String
      
      if (action == "dismiss") {
        delegate?.dismissModal()
      }
    case "SegmentedPicker":
      let btnArray = body["buttons"] as! [[String: Any]]
      let buttons = TurboButton.buildButtons(btnArray)
      delegate?.addSegmentedPicker(buttons: buttons)
    case "ActionSheetMenu":
      let options = body["options"] as! [[String: Any]]

      var menuOptions: [[String: String]] = []
      for option in options {
        if (option["visible"] as! Bool) {
          let type = option["type"] as? String ?? "default"
          menuOptions.append([
            "name": option["name"] as! String,
            "url": option["url"] as! String,
            "type": type,
          ])
        }
      }

      delegate?.addMenuButton(menuOptions)
//    case "MapLink":
//      let latitude = body["latitude"] as! Double
//      let longitude = body["longitude"] as! Double
//      delegate?.addMapLink(location: TMSLocation(latitude: latitude, longitude: longitude))
    default:
      Log.i("Unsupported message type for \(name)")
    }
  }
}
