//
//  SceneController.swift
//  FyreKit
//
//  Created by Dane Wilson on 10/16/21.
//

import UIKit
import WebKit
import SafariServices
import Turbo

final class SceneController: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?
  private let coordinator = AppCoordinator()

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = scene as? UIWindowScene else { return }
    makeAndAssignWindow(in: windowScene)
    coordinator.start()
  }
  
  private func makeAndAssignWindow(in windowScene: UIWindowScene) {
    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = coordinator.rootViewController
    window.makeKeyAndVisible()
    self.window = window
  }
}
