//
//  StartPageController.swift
//  FyreKit
//
//  Created by Dane Wilson on 10/13/21.
//

import SwiftUI
import UIKit
import Turbo

class StartPageController: UIHostingController<StartPage> {

  init() {
    super.init(rootView: StartPage())
  }
  
  @available(*, unavailable)
  @objc dynamic required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
