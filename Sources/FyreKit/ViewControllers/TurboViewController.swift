//
//  TurboController.swift
//  FyreKit
//
//  Created by Dane Wilson on 10/5/22.
//

import SafariServices
import SwiftUI
import Turbo

class TurboViewController: UINavigationController, ErrorPresenter, UITabBarDelegate, UINavigationBarDelegate {
  let tabBar = UITabBar()
  let itemHome = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), tag: 0)
  let itemPastOrders = UITabBarItem(title: "Orders", image: UIImage(systemName: "clock.arrow.circlepath"), tag: 1)
  let itemNotifications = UITabBarItem(title: "Notifications", image: UIImage(systemName: "bell"), tag: 2)
  let itemHelp = UITabBarItem(title: "Help", image: UIImage(systemName: "questionmark.circle"), tag: 3)
  let itemProfile = UITabBarItem(title: "Profile", image: UIImage(systemName: "person"), tag: 4)

  override func viewDidLoad() {
    super.viewDidLoad()
    
    if #available(iOS 15.0, *) {
      navigationItem.backButtonDisplayMode = .minimal
    }
    
    view.backgroundColor = .systemBackground
    
    if presentingViewController != nil {
      navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissModal))
    }

    tabBar.backgroundColor = nil

    if #available(iOS 13, *) {
      // iOS 13:
      let appearance = tabBar.standardAppearance
//      appearance.configureWithOpaqueBackground()
//      appearance.configureWithTransparentBackground()
      appearance.backgroundColor = UIColor(FyreKit.colors.bgColor)
      appearance.shadowImage = nil
      appearance.shadowColor = nil
      tabBar.standardAppearance = appearance
    } else {
      // iOS 12 and below:
      tabBar.shadowImage = UIImage()
      tabBar.backgroundImage = UIImage()
    }
    
    tabBar.frame = CGRect(x: 0, y: self.view.frame.height - 75, width: self.view.frame.width, height: 49)
    
    tabBar.items = [itemHome, itemPastOrders, itemNotifications, itemHelp, itemProfile]
    tabBar.selectedItem = tabBar.selectedItem ?? itemHome

    showTabBar()
  }
  
  func showTabBar() {
    if (FyreKit.loggedIn) {
      self.view.addSubview(tabBar)
    }
  }
  
  @objc func dismissModal() {
    log("dismissing modal!")
    dismiss(animated: true)
  }
}
