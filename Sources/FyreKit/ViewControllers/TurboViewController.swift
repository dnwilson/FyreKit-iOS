//
//  TurboViewController.swift
//  FyreKit
//
//  Created by Dane Wilson on 10/5/22.
//

import SafariServices
import SwiftUI
import Turbo

final class TurboViewController: VisitableViewController, ErrorPresenter {
  override func viewDidLoad() {
    super.viewDidLoad()

    if #available(iOS 14.0, *) {
      navigationItem.backButtonDisplayMode = .minimal
    }
    
    view.backgroundColor = .systemBackground

    if presentingViewController != nil {
      navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissModal))
    }
  }


  @objc func dismissModal() {
    dismiss(animated: true)
  }
}
