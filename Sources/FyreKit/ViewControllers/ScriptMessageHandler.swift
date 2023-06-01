//
//  ScriptMessageHandler.swift
//  FyreKit
//
//  Created by Dane Wilson on 9/21/21.
//

import WebKit

public protocol ScriptMessageDelegate: AnyObject {
  func addActionButton(_ button: TurboButton)
  func addMenuButton(label: String, _ menuOptions: [TurboButton])
  func addSegmentedPicker(buttons: [TurboButton])
  func addMapLink(location: FyreKitLocation)
  func dismissModal(path: String)
}

public class ScriptMessageHandler: NSObject, WKScriptMessageHandler {
  private weak var delegate: ScriptMessageDelegate?
  
  public init(delegate: ScriptMessageDelegate) {
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
      Log.i("Script message error")
      return
    }
    
    switch name {
    case "ActionButton":
      let button = TurboButton(body)
      delegate?.addActionButton(button)
    case "Modal":
      let options = body["options"] as! [String: Any]
      let action = options["action"] as! String
      let url = options["url"] as! String
      
      if (action == "dismiss") {
        delegate?.dismissModal(path: url)
      }
    case "SegmentedPicker":
      let btnArray = body["buttons"] as! [[String: Any]]
      let buttons = TurboButton.buildButtons(btnArray)
      delegate?.addSegmentedPicker(buttons: buttons)
    case "ActionSheetMenu":
      let options = body["options"] as! [[String: Any]]
      let icon = body["icon"] as! String
      let menuOptions = TurboButton.buildButtons(options)
//      var menuOptions: [[String: String]] = []
//      for option in options {
//        if (option["visible"] as! Bool) {
//          let type = option["type"] as? String ?? "default"
//          let url = option["url"] as? String ?? ""
//          let script = option["script"] as? String ?? ""
//          menuOptions.append([
//            "name": option["name"] as! String, "url": url,
//            "script": script, "type": type,
//          ])
//        }
//      }

      delegate?.addMenuButton(label: icon, menuOptions)
    case "MapLink":
      let latitude = body["latitude"] as! Double
      let longitude = body["longitude"] as! Double
      delegate?.addMapLink(location: FyreKitLocation(latitude: latitude, longitude: longitude))
    default:
      Log.i("Unsupported message type for \(name)")
    }
  }
}
