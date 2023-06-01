//
//  TurboViewController.swift
//  FyreKit
//
//  Created by Dane Wilson on 10/5/22.
//

import SafariServices
import SwiftUI
import Turbo

public final class TurboViewController: VisitableViewController, ErrorPresenter {
  public override func viewDidLoad() {
    super.viewDidLoad()

    if #available(iOS 14.0, *) {
      navigationItem.backButtonDisplayMode = .minimal
    }
    
    view.backgroundColor = .systemBackground
    if presentingViewController != nil {
      navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissModal))
    }
  }
  
  func addMenu() {
    navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissModal))
  }


  @objc func dismissModal() {
    dismiss(animated: true)
  }
}
