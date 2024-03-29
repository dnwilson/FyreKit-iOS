//
//  FyreKitViewController.swift
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

public protocol StartPageDelegate: AnyObject {
  func login()
  func turboVisit(url: String)
}

public class FyreKitViewController : UINavigationController {
  private lazy var tabBar = makeTabBar()
  private lazy var session = makeSession()
  private lazy var modalSession = makeSession()
  private lazy var settings = loadSettings()
  private static var sharedProcessPool = WKProcessPool()
  
  private var nextActionButton: TurboButton?
  private var segmentedButtons: [TurboButton]?
  private var menuOptions: [TurboButton]?
  
  var notificationCenter = NotificationCenter.default
  private var url = FyreKit.rootURL

  public static func visitUrl(url: URL) -> FyreKitViewController {
    let viewController = FyreKitViewController()
    viewController.url = url
    
    return viewController
  }

  private lazy var pathConfiguration = PathConfiguration(sources: [
    .file(Bundle.main.url(forResource: "TurboConfig", withExtension: "json")!),
    .server(FyreKit.fullUrl("turbo.json"))
  ])
  
  public override func viewDidLoad() {
    super.viewDidLoad()

    if (FyreKit.loggedIn) {
      loadNavBar()
      loadTabBar()
      loadTabs()
      loadHome()
      url = FyreKit.rootURL
      navigationBar.isHidden = false
      self.title = FyreKit.appName
    } else {
      url = FyreKit.fullUrl("sign-in")
      tabBar.isHidden = true
    }
    
    visit(url: url, options: VisitOptions(action: .replace),
          properties: pathConfiguration.properties(for: url))
  }
  
  public override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    tabBar.invalidateIntrinsicContentSize()
  }
  
  func visit(url: URL, options: VisitOptions, properties: PathProperties) {
    let action = options.action
    
    if (presentedViewController != nil) {
      dismiss(animated: true)
    }
    
    let viewController = makeViewController(for: url, properties: properties)
    viewController.title = self.title
  
    // We support three types of navigation in the app: advance, replace, and modal
    if isModal(properties) {
      let modalNavController = UINavigationController(rootViewController: viewController)
      
      if (url.absoluteString.contains("orders/new")) {
        modalNavController.isModalInPresentation = true
      }
      present(modalNavController, animated: true)
    } else if(isReplace(properties)) {
      let viewControllers = Array(viewControllers.dropLast()) + [viewController]
      setViewControllers(viewControllers, animated: false)
      completeVisit(viewController: viewController as! VisitableViewController, options: options, properties: properties)
      session.reload()
      return
    } else if action == .replace {
      let viewControllers = [viewController]
      setViewControllers(viewControllers, animated: false)
    } else {
      pushViewController(viewController, animated: true)
    }
    
    completeVisit(viewController: viewController, options: options, properties: properties)
  }
  
  func completeVisit(viewController: UIViewController, options: VisitOptions, properties: PathProperties) {
    guard let visitable = viewController as? Visitable else { return }
    
    // Each Session corresponds to a single web view. A good rule of thumb
    // is to use a session per navigation stack. Here we're using a different session
    // when presenting a modal. We keep that around for any modal presentations so
    // we don't have to create more than we need since each new session incurs a cold boot visit cost
    if isModal(properties) {
      modalSession.visit(visitable, options: options)
    } else {
      session.visit(visitable, options: options)
    }
  }
  
  private func makeViewController(for url: URL, properties: PathProperties = [:]) -> UIViewController {
    // There are many options for determining how to map urls to view controllers
    // The demo uses the path configuration for determining which view controller and presentation
    // to use, but that's completely optional. You can use whatever logic you prefer to determine
    // how you navigate and route different URLs.
//    if let viewController = properties["view-controller"] as? String {
//      switch viewController {
//      case "sign-in":
//        let startPage = StartPageController(delegate: self)
//        startPage.url = url
//        navigationBar.isHidden = true
//        tabBar.isHidden = true
//        return startPage
//      default:
//        assertionFailure("Invalid view controller, defaulting to WebView")
//      }
//    }
    
    return TurboViewController(url: url)
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
    if settings["navbar"] is Dictionary<String, String> {
      
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
    if settings["tabbar"] is Dictionary<String, String> {
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
  
  public func sendNotificationToken() {
    if (FyreKit.pushToken != nil) { return }
    
    let webView = self.session.webView

    if let token = FyreKit.pushToken {
      let script = "window.bridge.register('\(token)', 'ios')"

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
  public func session(_ session: Turbo.Session, didFailRequestForVisitable visitable: Turbo.Visitable, error: Error) {
    if let turboError = error as? TurboError, case let .http(statusCode) = turboError, statusCode == 401 {
      Log.i("Session Error: \(turboError) -- \(statusCode)")
      FyreKit.resetPrefs()
      FyreKit.setPref(false, key: "LoggedIn")
      FyreKit.setKeychainValue(nil, key: "access-token")
      visit(url: url, options: VisitOptions(action: .replace),
            properties: pathConfiguration.properties(for: FyreKit.fullUrl("sign-in")))
    } else if let errorPresenter = visitable as? ErrorPresenter {
      errorPresenter.presentError(error) { [weak self] in
        if (session == self?.modalSession) {
          self?.modalSession.reload()
        } else {
          self?.session.reload()
        }
      }
    } else {
      let alert = UIAlertController(title: "Visit failed!", message: error.localizedDescription, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
      navigationController?.present(alert, animated: true)
    }
  }
  
  public func session(_ session: Turbo.Session, didProposeVisit proposal: Turbo.VisitProposal) {
    visit(url: proposal.url, options: proposal.options, properties: proposal.properties)
  }
  
  public func sessionWebViewProcessDidTerminate(_ session: Turbo.Session) {
  }
  
  public func sessionDidStartRequest(_ session: Session) {
  }
  
  // When a form submission completes in the modal session, we need to
  // manually clear the snapshot cache in the default session, since we
  // don't want potentially stale cached snapshots to be used
  public func sessionDidFinishFormSubmission(_ session: Session) {
    if (session == modalSession) {
      self.session.clearSnapshotCache()

      if (url == FyreKit.fullUrl("sign-in")) {
        dismiss(animated: true)
      }
    }
  }
  
  public func sessionDidLoadWebView(_ session: Session) {
    session.webView.navigationDelegate = self
    session.webView.uiDelegate = self
  }
  
  public func sessionDidFinishRequest(_ session: Session) {
    let script = "document.querySelector(\"meta[name='turbo:authenticated']\").content"
    session.webView.evaluateJavaScript(script, completionHandler: { (html: Any?, error: Error?) in
      Log.i("Turbo is logged in? - \(String(describing: html))")
    })
    
    sendNotificationToken()
  }
}

extension FyreKitViewController : UITabBarDelegate {
  public func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    let tabs = settings["tabs"] as? [Dictionary<String, AnyObject>]
    let tab = tabs![item.tag] as Dictionary<String, AnyObject>
    guard var path = tab["visit"] as? String else { return }
    
    path = (path == "/profile") ? "\(path)s/\(FyreKit.userId)" : path
    let url = FyreKit.fullUrl(path)
    let properties = pathProperties(url.absoluteString)
    visit(url: url, options: VisitOptions(action: .replace), properties: properties)
  }
}

extension FyreKitViewController : WKNavigationDelegate {
  public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    if navigationAction.navigationType == .linkActivated {
      // Any link that's not on the same domain as the Turbo root url will go through here
      // Other links on the domain, but that have an extension that is non-html will also go here
      // You can decide how to handle those, by default if you're not the navigationDelegate
      // the Session will open them in the default browser
      
      let url = navigationAction.request.url!
      
      // For this demo, we'll load files from our domain in a SafariViewController so you
      // don't need to leave the app. You might expand this in your app
      // to open all audio/video/images in a native media viewer
      if url.host == FyreKit.rootURL.host, !url.pathExtension.isEmpty {
        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true)
      } else {
        UIApplication.shared.open(url)
      }
      
      decisionHandler(.cancel)
    } else {
      decisionHandler(.allow)
    }
  }
}

extension FyreKitViewController : WKUIDelegate {
  public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo,
                      completionHandler: @escaping () -> Void) {

    let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
      completionHandler()
    }))

    if (presentedViewController != nil) {
      presentedViewController?.present(alertController, animated: true, completion: nil)
    } else {
      present(alertController, animated: true, completion: nil)
    }
  }
//
//  public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
//
//    let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
//
//    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
//      completionHandler(true)
//    }))
//
//    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
//      completionHandler(false)
//    }))
//
//    present(alertController, animated: true, completion: nil)
//  }
//
//  public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
//
//    let alertController = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
//
//    alertController.addTextField { (textField) in
//      textField.text = defaultText
//    }
//
//    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
//      if let text = alertController.textFields?.first?.text {
//        completionHandler(text)
//      } else {
//        completionHandler(defaultText)
//      }
//    }))
//
//    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
//      completionHandler(nil)
//    }))
//
//    present(alertController, animated: true, completion: nil)
//  }
}

extension FyreKitViewController : ScriptMessageDelegate {
  public func addMapLink(location: FyreKitLocation) {
    MapLinkController.present(in: self, sourceView: view, location: location)
  }
  
  public func addActionButton(_ button: TurboButton) {
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
  
  public func addMenuButton(label: String = "ellipsis", _ menu: [TurboButton]) {
    menuOptions = menu
    if (menu.isEmpty) { return }
    
    let actionButton = TurboUIBarButton(
      image: nil,
      style: .plain,
      target: self,
      action: #selector(self.openMenu(sender:))
    )
    
    if (label == "ellipsis") {
      actionButton.image = UIImage(systemName: "ellipsis")
    } else {
      actionButton.title = label
    }

    visibleViewController?.navigationItem.rightBarButtonItem = actionButton
  }
  
  public func addSegmentedPicker(buttons: [TurboButton]) {
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
  
  public func dismissModal(path: String) {
    if (presentedViewController != nil) {
      dismiss(animated: true)
      let url = FyreKit.fullUrl(path)
      let properties = pathProperties(url.absoluteString)
      visit(url: url, options: VisitOptions(action: .replace), properties: properties)
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
        
        visit(url: URL(string: url)!, options: VisitOptions(action: .replace), properties: properties)
      } else {
        self.session.webView.evaluateJavaScript(button.script!) { _, _ in }
      }
    }
    //    nextActionButton = nil
  }
  
  @objc private func openMenu(sender: TurboUIBarButton) {
    if let buttons = menuOptions {
      let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
      
      for button in buttons {
        let alertAction = UIAlertAction(title: button.title, style: .default) { (_) in
          if (button.isDanger) {
            // Create new Alert modal
            let newAlert = UIAlertController(title: button.alertTitle, message: button.alertMessage, preferredStyle: .alert)

            newAlert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { (UIAlertAction) in
              Log.i("User click Dismiss button")
            }))

            // Alert modal confirmation button
            let confirmButton = UIAlertAction(title: button.title, style: .default) { (_) in
              Log.i("Confirm clicked -- script? \(button.isScript) --- \(String(describing: button.script))")
              if (button.isScript) {
                self.session.webView.evaluateJavaScript(button.script!) { _, _ in }
              } else {
                self.visit(url: FyreKit.fullUrl(button.path!), options: VisitOptions(action: .replace), properties: [:])
              }
            }
            //            confirmButton.titleTextColor = UIColor.red
            newAlert.addAction(confirmButton)

            // Present new alert modal
            self.present(newAlert, animated: true, completion: {
              Log.i("completion block")
            })
          }
          
          if (!button.isDanger) {
            if (button.isScript) {
              self.session.webView.evaluateJavaScript(button.script!) { _, _ in }
            } else {
              let properties = self.pathConfiguration.properties(for: button.path!)
              self.visit(url: FyreKit.fullUrl(button.path!), options: VisitOptions(action: .replace), properties: properties)
            }
          }
        }
        
        if (button.isDanger) {
          alertAction.titleTextColor = UIColor.red
        }
        
        if (button.icon != nil) {
          let image = UIImage(named: button.icon!)
          alertAction.setValue(image, forKey: "image")
        }
        
        alert.addAction(alertAction)
      }
      
      alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler:{ (UIAlertAction) in
        Log.i("User click Dismiss button")
      }))
      
      //uncomment for iPad Support
      //alert.popoverPresentationController?.sourceView = self.view
      if let popoverPresentationController = alert.popoverPresentationController {
        popoverPresentationController.sourceView = self.view
        popoverPresentationController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.size.height * 0.75, width: 0, height: 0)
      }
      
      present(alert, animated: true, completion: {
        Log.i("completion block")
      })
    }
  }
}

extension FyreKitViewController : StartPageDelegate {
  public func login() {
    viewDidLoad()
  }
  
  public func turboVisit(url: String) {
    let path = FyreKit.fullUrl(url)
    Log.i("turbo visit fired on delegate to url: \(path)...")
    visit(url: path, options: VisitOptions(action: .replace),
          properties: pathConfiguration.properties(for: path))
  }
}
  
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
