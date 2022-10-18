//
//  FyreKitSceneController.swift
//  FyreKit
//
//  Created by Dane Wilson on 10/16/21.
//

import UIKit
import WebKit
import SafariServices
import Turbo

open class FyreKitSceneController: UIResponder, UIWindowSceneDelegate {
  public var window: UIWindow?

  open func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = scene as? UIWindowScene else { return }
    let window = UIWindow(windowScene: windowScene)
    let viewController = FyreKit.loggedIn ? FyreKitViewController() : StartPageController()
  
    window.rootViewController = viewController
    window.makeKeyAndVisible()
    self.window = window
  }
}
