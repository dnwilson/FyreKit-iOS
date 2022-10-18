//
//  StartPageController.swift
//  FyreKit
//
//  Created by Dane Wilson on 10/13/21.
//

import SwiftUI
import UIKit

class StartPageController: UIHostingController<StartPage> {
  var notificationCenter = NotificationCenter.default
  public var window: UIWindow?

  init() {
    super.init(rootView: StartPage())
    notificationCenter.addObserver(self, selector: #selector(loggedIn), name: NSNotification.Name("User Logged In"), object: nil)
  }
  
  @available(*, unavailable)
  @objc dynamic required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  @objc
  private func loggedIn() {
    guard let window = self.keyWindow else {
      Log.i("Error launching FyreKitViewController")
      return
    }

    let viewController = FyreKitViewController()
    window.rootViewController = viewController
    viewController.sendNotificationToken()
  }
  
  var keyWindow: UIWindow? {
    // Get connected scenes
    return UIApplication.shared.connectedScenes
      // Keep only active scenes, onscreen and visible to the user
      .filter { $0.activationState == .foregroundActive }
      // Keep only the first `UIWindowScene`
      .first(where: { $0 is UIWindowScene })
      // Get its associated windows
      .flatMap({ $0 as? UIWindowScene })?.windows
      // Finally, keep only the key window
      .first(where: \.isKeyWindow)
  }
}
