//
//  LaunchCoordinator.swift
//  
//
//  Created by Dane Wilson on 10/14/22.
//

import SwiftUI

class LaunchCoordinator : Coordinator {
  var rootViewController: UIViewController {
    return launchViewController
  }

  private let launchViewController = StartPageController()
}
