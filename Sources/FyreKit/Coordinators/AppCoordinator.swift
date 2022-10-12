//
//  AppCoordinator.swift
//  FyreKit
//
//  Created by Dane Wilson on 3/15/22.
//

import SafariServices
import SwiftUI
import Turbo
import UIKit
import WebKit
import KeychainAccess
 
class AppCoordinator : NSObject {
  private static var sharedProcessPool = WKProcessPool()

  var rootViewController: UIViewController { navigationController }
  var window: UIWindow?
  var notificationCenter = NotificationCenter.default
  
  private let rootURL = FyreKit.rootURL
  private let navigationController = TurboViewController()
//  private let navigationController = UINavigationController()

  private var unAuthenticated = !FyreKit.hasAuthToken
  private var authenticated: String?
  private var nextActionButton: TurboButton?
  private var segmentedButtons: [TurboButton]?
  private var menuOptions: [[String: String]]?

  // MARK: - Authentication

  private func promptForAuthentication() {
    let authURL = rootURL.appendingPathComponent("/sign-in")
    let properties = pathConfiguration.properties(for: authURL)
    route(url: authURL, options: VisitOptions(), properties: properties)
  }

  // MARK: - Sessions

  private lazy var session = makeSession()
  private lazy var modalSession = makeSession()
  private let viewController = VisitableViewController()

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

  // MARK: - Path Configuration

  private lazy var pathConfiguration = PathConfiguration(sources: [
    .file(Bundle.main.url(forResource: "TurboConfig", withExtension: "json")!),
    .server(rootURL.appendingPathComponent("turbo.json"))
  ])
  
  // Mark: - Navbar Configuration
  private func setupNavBar() {
    if let navbar = session.pathConfiguration?.settings["navbar"] as? Dictionary<String, String> {
      print("FyreKit::Navbar", navbar)
      
      let navigationBar = navigationController.navigationBar

      let standardAppearance = UINavigationBarAppearance()
      standardAppearance.configureWithOpaqueBackground()
      standardAppearance.titleTextAttributes = [.foregroundColor: UIColor(hexRGB: navbar["foreground"]) as Any]
//            standardAppearance.backgroundColor = UIColor(hexRGB: navbar["background"])
      navigationBar.standardAppearance = standardAppearance;

      let scrollEdgeAppearance = UINavigationBarAppearance()
      scrollEdgeAppearance.configureWithOpaqueBackground()
      scrollEdgeAppearance.titleTextAttributes = [.foregroundColor: UIColor(hexRGB: navbar["background"]) as Any]
//            scrollEdgeAppearance.backgroundColor = UIColor(hexRGB: navbar["foreground"])
      navigationBar.scrollEdgeAppearance = scrollEdgeAppearance
    }
  }

  func start() {
    log("PUSH TOKEN = \(FyreKit.keychain["push-token"]!)")
    // Listen for login changes
    notificationCenter.addObserver(self, selector: #selector(loggedIn), name: NSNotification.Name("User Logged In"), object: nil)

    if FyreKit.hasAuthToken && FyreKit.loggedIn {
      setupNavBar()
      navigationController.tabBar.delegate = self
      route(url: FyreKit.rootURL.absoluteURL, options: VisitOptions(action: .advance), properties: [:])
    } else {
      FyreKit.keychain["access-token"] = nil
      let viewController = UIHostingController(rootView: StartPage())
      navigationController.setViewControllers([viewController], animated: true)
      visit(viewController: viewController, with: VisitOptions(action: .replace))
    }
  }
  
  func route(url: URL, options: VisitOptions, properties: PathProperties) {
    // This is a simplified version of how you might build out the routing
    // and navigation functions of your app. In a real app, these would be separate objects
    // Dismiss any modals when receiving a new navigation
    if navigationController.presentedViewController != nil {
      navigationController.dismiss(animated: true)
    }
    
    // Special case of navigating home, issue a reload
    if url.path == "/", !navigationController.viewControllers.isEmpty {
      navigationController.popViewController(animated: false)
      session.reload()
      return
    }
    
    // stops the page from double rendering on redirect
    let visitableURL = session.activeVisitable?.visitableURL == url || unAuthenticated
    let action = visitableURL ? .replace : options.action
    
    // - Create view controller appropriate for url/properties
    // - Navigate to that with the correct presentation
    // - Initiate the visit with Turbo
    let viewController = makeViewController(for: url, properties: properties)
    navigate(to: viewController, action: action, properties: properties)
    visit(viewController: viewController, with: options, modal: isModal(properties))
  }
  
  private func isModal(_ properties: PathProperties) -> Bool {
    // For simplicity, we're using string literals for various keys and values of the path configuration
    // but most likely you'll want to define your own enums these properties
    return properties["presentation"] as? String == "modal"
  }
  
  private func makeViewController(for url: URL, properties: PathProperties = [:]) -> UIViewController {
    // There are many options for determining how to map urls to view controllers
    // The demo uses the path configuration for determining which view controller and presentation
    // to use, but that's completely optional. You can use whatever logic you prefer to determine
    // how you navigate and route different URLs.
    if let viewController = properties["view-controller"] as? String {
      switch viewController {
//      case "map":
//        let map = MapLinksController()
//        map.url = url
//        return map
//        
//        let params = url.query?.components(separatedBy: "&").map({
//          $0.components(separatedBy: "=")
//        }).reduce(into: [String:String]()) { dict, pair in
//          if pair.count == 2 {
//            dict[pair[0]] = pair[1]
//          }
//        }
//        print("PARAMS", params!)
//        
//        let location = TMSLocation(latitude: params!["latitude"]!, longitude: params!["longitude"]!)
//        return MapLinkController(location: location)
      case "sign-in":
        let view = StartPage()
        return UIHostingController(rootView: view)
      default:
        assertionFailure("Invalid view controller, defaulting to WebView")
      }
    }
        
    return ViewController(url: url)
  }
  
  private func navigate(to viewController: UIViewController, action: VisitAction, properties: PathProperties = [:], animated: Bool = true) {
    
    // We support three types of navigation in the app: advance, replace, and modal
    if isModal(properties) {
      if viewController is UIAlertController {
        navigationController.present(viewController, animated: animated, completion: nil)
      } else {
        let modalNavController = UINavigationController(rootViewController: viewController)
        navigationController.present(modalNavController, animated: animated)
      }
    } else if action == .replace {
      let viewControllers = Array(navigationController.viewControllers.dropLast()) + [viewController]
      navigationController.setViewControllers(viewControllers, animated: false)
    } else {
      navigationController.pushViewController(viewController, animated: animated)
    }
  }
  
  private func visit(viewController: UIViewController, with options: VisitOptions, modal: Bool = false) {
    guard let visitable = viewController as? Visitable else { return }
    
    // Each Session corresponds to a single web view. A good rule of thumb
    // is to use a session per navigation stack. Here we're using a different session
    // when presenting a modal. We keep that around for any modal presentations so
    // we don't have to create more than we need since each new session incurs a cold boot visit cost
    if modal {
      modalSession.visit(visitable, options: options)
    } else {
      session.visit(visitable, options: options)
    }
  }
  
  @objc
  private func loggedIn() {
    let visitable = VisitableViewController(url: FyreKit.rootURL)
    session.visit(visitable, options: VisitOptions(action: .replace))
    session.reload()
    navigationController.dismiss(animated: true)
    navigationController.setViewControllers([visitable], animated: false)
    navigationController.tabBar.delegate = self
    navigationController.showTabBar()
    
    sendNotificationToken()
  }
  
  func sendNotificationToken() {
    let token: String = FyreKit.keychain["push-token"]!
    if (!FyreKit.hasPushToken) {
      let webView = self.session.webView
      let script = "window.bridge.register(\"\(token)\", 'ios');"
      
      webView.evaluateJavaScript(script) { object, error in
        if error != nil {
          // handle error
          FyreKit.setPushTokenSaved(false)
        } else if object != nil {
          // success
          FyreKit.setPushTokenSaved(true)
        }
      }
    }
  }
}

extension AppCoordinator: UITabBarDelegate {
  func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    let url : URL
    let properties = PathProperties()

    switch(item.tag) {
    case 1:
      var string = URLComponents(string: FyreKit.fullUrl("orders").absoluteString)
      string?.queryItems = [URLQueryItem(name: "scope", value: "previous")]
      url = (string?.url)!
    case 2:
      url = FyreKit.fullUrl("notifications")
    case 3:
      url = FyreKit.fullUrl("help")
    case 4:
      url = FyreKit.fullUrl("profile")
    default:
      url = FyreKit.rootURL
    }
    
    route(url: url, options: VisitOptions(action: .replace), properties: properties)
  }
  
//  func makeTabBar() -> UITabBar {
//    let tabBar = UITabBar()
//    tabBar.delegate = self
//    tabBar.frame = CGRect(x: 0, y: self.view.frame.height, width: self.view.frame.width, height: 0)
//    tabBar.items = []
//    self.view.addSubview(tabBar)
//    tabBar.translatesAutoresizingMaskIntoConstraints = false
//    tabBar.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
//    tabBar.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
//    tabBar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
//    return tabBar
//  }
}

extension AppCoordinator: SessionDelegate {
  func sessionWebViewProcessDidTerminate(_ session: Turbo.Session) {
  }
  
  func session(_ session: Session, didProposeVisit proposal: VisitProposal) {
    route(url: proposal.url, options: proposal.options, properties: proposal.properties)
  }

  func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, error: Error) {
    if let turboError = error as? TurboError, case let .http(statusCode) = turboError, statusCode == 401 {
      log("ERROR CODE: \(turboError) -- \(statusCode)")
    } else if let errorPresenter = visitable as? ErrorPresenter {
      errorPresenter.presentError(error) { [weak self] in
        self?.session.reload()
      }
    } else {
      let alert = UIAlertController(title: "Visit failed!", message: error.localizedDescription, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
      navigationController.present(alert, animated: true)
    }
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
      self.authenticated = html as? String
    })
  }
}

extension AppCoordinator: WKNavigationDelegate {
  func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    if navigationAction.navigationType == .linkActivated {
      // Any link that's not on the same domain as the Turbo root url will go through here
      // Other links on the domain, but that have an extension that is non-html will also go here
      // You can decide how to handle those, by default if you're not the navigationDelegate
      // the Session will open them in the default browser

      let url = navigationAction.request.url!

      // For this demo, we'll load files from our domain in a SafariViewController so you
      // don't need to leave the app. You might expand this in your app
      // to open all audio/video/images in a native media viewer
      if url.host == rootURL.host, !url.pathExtension.isEmpty {
        let safariViewController = SFSafariViewController(url: url)
        navigationController.present(safariViewController, animated: true)
      } else {
        UIApplication.shared.open(url)
      }

      decisionHandler(.cancel)
    } else {
      decisionHandler(.allow)
    }
  }
}

extension AppCoordinator: WKUIDelegate {
  func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo,
               completionHandler: @escaping () -> Void) {
    
    let alertController = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
      completionHandler()
    }))
    
    navigationController.present(alertController, animated: true, completion: nil)
  }
}

extension AppCoordinator: ScriptMessageDelegate {
  func dismissModal() {
    if ((navigationController.presentedViewController) != nil) {
      navigationController.dismiss(animated: true)
      session.reload()
    }
  }
  
  func addMenuButton(_ menu: [[String: String]]) {
    menuOptions = menu
    let actionButton = TurboUIBarButton(
      image: UIImage(systemName: "ellipsis"),// 🤩
      style: .plain,
      target: self,
      action: #selector(self.openMenu(sender:))
    )
    
    navigationController.visibleViewController?
        .navigationItem.rightBarButtonItem = actionButton
  }
  
  func addActionButton(_ button: TurboButton) {
    nextActionButton = button
    let actionButton = TurboUIBarButton(
      image: button.icon != nil ? UIImage(systemName: button.icon!) : nil, // 🤩
      style: .plain,
      target: self,
      action: #selector(self.visitActionButtonURL(sender:))
    )
    actionButton.title = button.title

    navigationController.visibleViewController?
        .navigationItem.rightBarButtonItem = actionButton
  }
  
  func addSegmentedPicker(buttons: [TurboButton]) {
    segmentedButtons = buttons
    let titles = buttons.map { $0.title! }
    let segmentedControl = UISegmentedControl(items: titles)
    
    segmentedControl.selectedSegmentIndex = buttons.firstIndex(where: { URL(string: $0.path!) == session.activeVisitable?.visitableURL}) ?? 0
    
    segmentedControl.backgroundColor = UIColor(Color.white)
    segmentedControl.selectedSegmentTintColor = UIColor(primaryColor)
    segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor(primaryColor)], for: .normal)
    segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    segmentedControl.sizeToFit()
    segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    navigationController.visibleViewController?
        .navigationItem.titleView = segmentedControl
  }
  
  @objc private func segmentChanged(_ sender: UISegmentedControl) {
    if let buttons = segmentedButtons {
      let button = buttons[sender.selectedSegmentIndex]
      route(url: URL(string: button.path!)!, options: VisitOptions(action: .replace), properties: [:])
    }
    
    segmentedButtons = nil
  }

  @objc private func visitActionButtonURL(sender: TurboUIBarButton) {
    if let button = nextActionButton {
      if button.isGet {
        let url = button.path!
        let properties = pathConfiguration.properties(for: url)
        
        route(url: URL(string: url)!, options: VisitOptions(action: .advance), properties: properties)
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
              self.route(url: url, options: VisitOptions(action: .advance), properties: [:])
            }
            confirmButton.titleTextColor = UIColor.red
            newAlert.addAction(confirmButton)
            
            // Present new alert modal
            self.rootViewController.present(newAlert, animated: true, completion: {
                print("completion block")
            })
          } else {
            
          }

          let action: VisitAction = (option["method"] ?? "" == "replace") ? .replace : .advance
          let properties = self.pathConfiguration.properties(for: url)
          self.route(url: url, options: VisitOptions(action: action), properties: properties)
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

      rootViewController.present(alert, animated: true, completion: {
          print("completion block")
      })
    }
  }
}

import UIKit
class TurboUIBarButton: UIBarButtonItem {
  var actionString: String = ""
}

extension UIAlertAction {
  var titleTextColor: UIColor? {
    get {
      return self.value(forKey: "titleTextColor") as? UIColor
    } set {
      self.setValue(newValue, forKey: "titleTextColor")
    }
  }
}

extension UIColor {
  convenience init?(hexRGBA: String?) {
    guard let rgba = hexRGBA, let val = Int(rgba.replacingOccurrences(of: "#", with: ""), radix: 16) else {
      return nil
    }
    self.init(red: CGFloat((val >> 24) & 0xff) / 255.0, green: CGFloat((val >> 16) & 0xff) / 255.0, blue: CGFloat((val >> 8) & 0xff) / 255.0, alpha: CGFloat(val & 0xff) / 255.0)
  }
  
  convenience init?(hexRGB: String?) {
    guard let rgb = hexRGB else {
      return nil
    }
    self.init(hexRGBA: rgb + "ff")
  }
}

