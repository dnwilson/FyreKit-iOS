//
//  File.swift
//  
//
//  Created by Dane Wilson on 10/14/22.
//

import Foundation
import UIKit
import Turbo
import WebKit
import SwiftUI
import SafariServices

class FyreKitViewController : UINavigationController {
  private lazy var tabBar = makeTabBar()
  private lazy var session = makeSession()
  private lazy var modalSession = makeSession()
  private lazy var settings = loadSettings()
  private static var sharedProcessPool = WKProcessPool()
  
  private var nextActionButton: TurboButton?
  private var segmentedButtons: [TurboButton]?
  private var menuOptions: [[String: String]]?
  
  var notificationCenter = NotificationCenter.default
  
  private lazy var pathConfiguration = PathConfiguration(sources: [
    .file(Bundle.main.url(forResource: "TurboConfig", withExtension: "json")!),
    .server(FyreKit.fullUrl("turbo.json"))
  ])
  
  override func viewDidLoad() {
    super.viewDidLoad()

    loadNavBar()
    loadTabBar()
    loadTabs()
    loadHome()
    
    self.title = FyreKit.appName
    
    Log.i("Main app loaded")
    visit(url: FyreKit.rootURL, options: VisitOptions(action: .replace),
          properties: pathConfiguration.properties(for: FyreKit.rootURL))
  }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    tabBar.invalidateIntrinsicContentSize()
  }
  
  func visit(url: URL, options: VisitOptions, properties: PathProperties) {
    let action = options.action
    if (presentedViewController != nil) {
      print("TURBO: presented", presentedViewController)
      dismiss(animated: true)
    }

    let viewController = TurboViewController(url: url)
    viewController.title = self.title

    if url.path == "/", !viewControllers.isEmpty {
      print("TURBO: is home and view.empty", url.path == "/", !viewControllers.isEmpty)
      popViewController(animated: true)
      viewControllers = Array() + [viewController]
      session.visit(viewController)
    } else if isModal(properties) {
      print("TURBO: is modal", isModal(properties))
      present(viewController, animated: true)
      modalSession.visit(viewController)
    } else if isReplace(properties) {
      viewControllers = Array(viewControllers.dropLast()) + [viewController]
      session.visit(viewController)
      session.reload()
    } else if session.activeVisitable?.visitableURL == url {
      let viewControllers = viewControllers.dropLast()
      setViewControllers(viewControllers + [viewController], animated: false)
      session.visit(viewController)
    } else if action == .advance {
      pushViewController(viewController, animated: true)
      session.visit(viewController)
    } else if action == .replace {
      viewControllers = Array() + [viewController]
      session.visit(viewController)
    } else if action == .restore {
      popViewController(animated: true)
      session.visit(viewController)
    } else {
      pushViewController(viewController, animated: true)
      session.visit(viewController)
    }
  }
  
  func makeTabBar() -> UITabBar {
    let tabBar = UITabBar()
    tabBar.delegate = self
    tabBar.frame = CGRect(x: 0, y: self.view.frame.height, width: self.view.frame.width, height: 0)
    tabBar.items = []
    self.view.addSubview(tabBar)
    tabBar.translatesAutoresizingMaskIntoConstraints = false
    tabBar.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
    tabBar.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
    tabBar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
    return tabBar
  }

  func loadSettings() -> Dictionary<String, AnyObject> {
    let text: String = ApiService.get("turbo.json")
    if let json = FyreKit.stringToDictionary(text: text) {
      return (json["settings"] as? Dictionary<String, AnyObject>)!
    }
    return [:]
  }
  
  func loadHome() {
    let url = FyreKit.rootURL
    let properties = pathProperties(url.absoluteString)
    visit(url: url, options: VisitOptions(action: .replace), properties: properties)
  }
  
  func loadNavBar() {
    if let navbar = settings["navbar"] as? Dictionary<String, String> {
      
      let standardAppearance = UINavigationBarAppearance()
      standardAppearance.configureWithOpaqueBackground()
      standardAppearance.titleTextAttributes = [.foregroundColor: UIColor(FyreKit.primaryColor) as Any]
      standardAppearance.backgroundColor = UIColor(FyreKit.bgColor)
      navigationBar.standardAppearance = standardAppearance;

      let scrollEdgeAppearance = UINavigationBarAppearance()
      scrollEdgeAppearance.configureWithOpaqueBackground()
      scrollEdgeAppearance.titleTextAttributes = [.foregroundColor: UIColor(FyreKit.primaryColor) as Any]
      scrollEdgeAppearance.backgroundColor = UIColor(FyreKit.bgColor)
      navigationBar.scrollEdgeAppearance = scrollEdgeAppearance
    }
  }
  
  func loadTabBar() {
    if let tabbar = settings["tabbar"] as? Dictionary<String, String> {
      UITabBar.appearance().barTintColor = UIColor(FyreKit.bgColor)
      UITabBar.appearance().tintColor = UIColor(FyreKit.primaryColor)
      UITabBar.appearance().unselectedItemTintColor = UIColor(FyreKit.disabledPrimaryColor)
    }
  }
  
  func loadTabs(_ authenticated: Bool = false) {
    tabBar.items?.removeAll()
    if let tabs = settings["tabs"] as? [Dictionary<String, AnyObject>] {
      for (index, tab) in tabs.enumerated() {
        let title = tab["title"] as? String
        let icon_ios = tab["icon_ios"] as? String
//        let protected = tab["protected"] as? Bool ?? false
        let image = UIImage(systemName: icon_ios!)
        let tabBarItem = UITabBarItem(title: title, image: image, tag: index)

        tabBar.items?.append(tabBarItem)
      }
      if (tabBar.items!.count > 0) {
        tabBar.selectedItem = tabBar.items![0]
      }
    }
    if (tabBar.items!.count > 0) {
      tabBar.frame = CGRect(x: 0, y: self.view.frame.height - self.view.safeAreaInsets.bottom + 49.0, width: self.view.frame.width, height: 49)
      tabBar.isHidden = false
      tabBar.layer.zPosition = 0
    }
    else {
      tabBar.frame = CGRect(x: 0, y: self.view.frame.height, width: self.view.frame.width, height: 0)
      tabBar.isHidden = true
      tabBar.layer.zPosition = -1
    }
  }
  
  private func pathProperties(_ path : String) -> PathProperties {
    pathConfiguration.properties(for: FyreKit.fullUrl(path))
  }
  
  private func makeSession() -> Session {
    let configuration = WKWebViewConfiguration()
    configuration.applicationNameForUserAgent = FyreKit.userAgent
    configuration.processPool = Self.sharedProcessPool
    
    let scriptMessageHandler = ScriptMessageHandler(delegate: self)
    configuration.userContentController.add(scriptMessageHandler, name: "nativeApp")

    let session = Session(webViewConfiguration: configuration)
    session.webView.allowsLinkPreview = false
    session.delegate = self
    session.pathConfiguration = pathConfiguration
    return session
  }
  
  func sendNotificationToken() {
    if (FyreKit.pushTokenSaved) { return }
    
    let webView = self.session.webView
    let script = "window.bridge.register(\"\(FyreKit.pushToken)\", 'ios');"
    
    webView.evaluateJavaScript(script) { object, error in
      if error != nil {
        // handle error
        FyreKit.setKeychainValue(false, key: "PushTokenSaved")
      } else if object != nil {
        // success
        FyreKit.setKeychainValue(true, key: "PushTokenSaved")
      }
    }
  }

  func isModal(_ properties: PathProperties) -> Bool {
    let presentation = properties["presentation"] as? String
    return presentation == "modal"
  }
  
  func isReplace(_ properties: PathProperties) -> Bool {
    let presentation = properties["presentation"] as? String
    return presentation == "replace"
  }
  
  func isRestore(_ properties: PathProperties) -> Bool {
    let presentation = properties["presentation"] as? String
    return presentation == "restore"
  }
}

extension FyreKitViewController : SessionDelegate {
  func session(_ session: Turbo.Session, didFailRequestForVisitable visitable: Turbo.Visitable, error: Error) {
    if let turboError = error as? TurboError, case let .http(statusCode) = turboError, statusCode == 401 {
      Log.i("Session Error: \(turboError) -- \(statusCode)")
//      promptForAuthentication()
    } else if let errorPresenter = visitable as? ErrorPresenter {
      errorPresenter.presentError(error) { [weak self] in
        self?.session.reload()
      }
    } else {
      let alert = UIAlertController(title: "Visit failed!", message: error.localizedDescription, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
      navigationController?.present(alert, animated: true)
    }
  }
  
  func session(_ session: Turbo.Session, didProposeVisit proposal: Turbo.VisitProposal) {
    visit(url: proposal.url, options: proposal.options, properties: proposal.properties)
  }
  
  func sessionWebViewProcessDidTerminate(_ session: Turbo.Session) {
  }

  func sessionDidStartRequest(_ session: Session) {
  }

  func sessionDidLoadWebView(_ session: Session) {
    session.webView.navigationDelegate = self
    session.webView.uiDelegate = self
  }

  func sessionDidFinishRequest(_ session: Session) {
    let script = "document.querySelector(\"meta[name='turbo:authenticated']\").content"
    session.webView.evaluateJavaScript(script, completionHandler: { (html: Any?, error: Error?) in
      Log.i("Session did finish - \(String(describing: html))")
    })
  }
}

extension FyreKitViewController : UITabBarDelegate {
  func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    let tabs = settings["tabs"] as? [Dictionary<String, AnyObject>]
    let tab = tabs![item.tag] as Dictionary<String, AnyObject>
    guard let path = tab["visit"] as? String else { return }

    let url = FyreKit.fullUrl(path)
    Log.i("URL \(url)")
    let properties = pathProperties(url.absoluteString)
    visit(url: url, options: VisitOptions(action: .replace), properties: properties)
  }
}

extension FyreKitViewController : WKNavigationDelegate {
}


extension FyreKitViewController : WKUIDelegate {
}

extension FyreKitViewController : ScriptMessageDelegate {
  func addActionButton(_ button: TurboButton) {
    Log.i("implement add action button")
    
    nextActionButton = button
    let actionButton = TurboUIBarButton(
      image: button.icon != nil ? UIImage(systemName: button.icon!) : nil, // 🤩
      style: .plain,
      target: self,
      action: #selector(self.visitActionButtonURL(sender:))
    )
    actionButton.title = button.title
    visibleViewController?.navigationItem.rightBarButtonItem = actionButton
  }
  
  func addMenuButton(_ menu: [[String : String]]) {
    Log.i("implement add menu button")
    menuOptions = menu
    let actionButton = TurboUIBarButton(
      image: UIImage(systemName: "ellipsis"),// 🤩
      style: .plain,
      target: self,
      action: #selector(self.openMenu(sender:))
    )
    
    visibleViewController?.navigationItem.rightBarButtonItem = actionButton
  }
  
  func addSegmentedPicker(buttons: [TurboButton]) {
    Log.i("implement add action button")
    segmentedButtons = buttons
    let titles = buttons.map { $0.title! }
    let segmentedControl = UISegmentedControl(items: titles)
    
    segmentedControl.selectedSegmentIndex = buttons.firstIndex(where: { URL(string: $0.path!) == session.activeVisitable?.visitableURL}) ?? 0
    
    segmentedControl.backgroundColor = UIColor(Color.white)
    segmentedControl.selectedSegmentTintColor = UIColor(FyreKit.primaryColor)
    segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor(FyreKit.primaryColor)], for: .normal)
    segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    segmentedControl.sizeToFit()
    segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    visibleViewController?.navigationItem.titleView = segmentedControl
  }
  
  func dismissModal() {
    Log.i("implement add dismiss modal")
    if (presentedViewController != nil) {
      dismiss(animated: true)
      session.reload()
    }
  }
  
  @objc private func segmentChanged(_ sender: UISegmentedControl) {
    if let buttons = segmentedButtons {
      let button = buttons[sender.selectedSegmentIndex]
      visit(url: URL(string: button.path!)!, options: VisitOptions(action: .replace), properties: [:])
    }
    
    segmentedButtons = nil
  }

  @objc private func visitActionButtonURL(sender: TurboUIBarButton) {
    if let button = nextActionButton {
      if button.isGet {
        let url = button.path!
        let properties = pathConfiguration.properties(for: url)
        
        visit(url: URL(string: url)!, options: VisitOptions(action: .advance), properties: properties)
      } else {
        self.session.webView.evaluateJavaScript(button.script!) { _, _ in }
      }
    }
//    nextActionButton = nil
  }
  
  @objc private func openMenu(sender: TurboUIBarButton) {
    if let options = menuOptions {
      let alert = UIAlertController(title: "User Options", message: "Please Select an Option", preferredStyle: .actionSheet)
      
      for option in options {
        let url = FyreKit.fullUrl(option["url"]!)
        let alertAction = UIAlertAction(title: option["name"], style: .default) { (_) in
          if (option["type"]! == "danger") {
            // Create new Alert modal
            let newAlert = UIAlertController(title: "Testing", message: "Are you sure you want to delete?", preferredStyle: .alert)
            
            newAlert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { (UIAlertAction)in
              print("User click Dismiss button")
            }))
            
            // Alert modal confirmation button
            let confirmButton = UIAlertAction(title: option["name"]!, style: .default) { (_) in
              self.visit(url: url, options: VisitOptions(action: .advance), properties: [:])
            }
//            confirmButton.titleTextColor = UIColor.red
            newAlert.addAction(confirmButton)
            
            // Present new alert modal
            self.present(newAlert, animated: true, completion: {
              print("completion block")
            })
          }
          
          let action: VisitAction = (option["method"] ?? "" == "replace") ? .replace : .advance
          let properties = self.pathConfiguration.properties(for: url)
          self.visit(url: url, options: VisitOptions(action: action), properties: properties)
        }
        
        if (option["type"]! == "danger") {
          alertAction.titleTextColor = UIColor.red
        }
        
        alert.addAction(alertAction)
      }
      
      alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler:{ (UIAlertAction)in
        print("User click Dismiss button")
      }))
      
      //uncomment for iPad Support
      //alert.popoverPresentationController?.sourceView = self.view
      
      present(alert, animated: true, completion: {
        print("completion block")
      })
    }
  }
}

//extension UIBarButtonItem {
//  private struct AssociatedObject {
//    static var key = "action_closure_key"
//  }
//
//  var actionClosure: (()->Void)? {
//    get {
//      return objc_getAssociatedObject(self, &AssociatedObject.key) as? ()->Void
//    }
//    set {
//      objc_setAssociatedObject(self, &AssociatedObject.key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//      target = self
//      action = #selector(didTapButton(sender:))
//    }
//  }
//
//  @objc func didTapButton(sender: Any) {
//    actionClosure?()
//  }
//}
// save
extension UIImage {
  func save(at directory: FileManager.SearchPathDirectory,
            pathAndImageName: String,
            createSubdirectoriesIfNeed: Bool = true,
            compressionQuality: CGFloat = 1.0)  -> URL? {
    do {
      let documentsDirectory = try FileManager.default.url(for: directory, in: .userDomainMask,
                                                           appropriateFor: nil,
                                                           create: false)
      return save(at: documentsDirectory.appendingPathComponent(pathAndImageName),
                  createSubdirectoriesIfNeed: createSubdirectoriesIfNeed,
                  compressionQuality: compressionQuality)
    } catch {
      Log.i("-- Error: \(error)")
      return nil
    }
  }

  func save(at url: URL,
            createSubdirectoriesIfNeed: Bool = true,
            compressionQuality: CGFloat = 1.0)  -> URL? {
    do {
      if createSubdirectoriesIfNeed {
          try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                  withIntermediateDirectories: true,
                                                  attributes: nil)
      }
      guard let data = jpegData(compressionQuality: compressionQuality) else { return nil }
      try data.write(to: url)
      return url
    } catch {
      Log.i("-- Error: \(error)")
      return nil
    }
  }
}

// load from path

extension UIImage {
  convenience init?(fileURLWithPath url: URL, scale: CGFloat = 1.0) {
    do {
      let data = try Data(contentsOf: url)
      self.init(data: data, scale: scale)
    } catch {
      Log.i("-- Error: \(error)")
      return nil
    }
  }
}

extension UIImageView {
  func fromUrl(url: URL) {
    DispatchQueue.global().async { [weak self] in
      if let data = try? Data(contentsOf: url) {
        if let image = UIImage(data: data) {
          DispatchQueue.main.async {
            self?.image = image
          }
        }
      }
    }
  }
}
