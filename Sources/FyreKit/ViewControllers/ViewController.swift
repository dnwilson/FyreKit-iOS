//
//  ViewController.swift
//  FyreKit
//
//  Created by Dane Wilson on 10/16/21.
//

import UIKit
import Turbo

final class ViewController: VisitableViewController, ErrorPresenter, UITabBarDelegate {
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if #available(iOS 15.0, *) {
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
