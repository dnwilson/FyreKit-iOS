import SwiftUI
import KeychainAccess

@available(iOS 15, *)
public struct FyreKit {
  // MARK: - Keys
  enum Keys {
    enum Plist {
      static let rootURL = "ROOT_URL"
      static let demoURL = "DEMO_URL"
      static let sendPushToken = "SEND_PUSH_TOKEN"
    }
  }

  private init() {
  }
  
  private static let preferences: UserDefaults = {
    return UserDefaults.standard
  }()
  
  public static func toggleDemoMode() {
    preferences.set(!preferences.bool(forKey: "DemoMode"), forKey: "DemoMode")
  }
  
  public static var appName: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
  public static var loggedIn: Bool = preferences.bool(forKey: "LoggedIn")
  public static var isDemoMode: Bool = preferences.bool(forKey: "DemoMode")
  public static var hasPushToken: Bool = preferences.bool(forKey: "PushTokenSaved")
  public static var hasAuthToken: Bool = keychain["access-token"] != nil
  public static var authToken = keychain["access-token"]
  
  // MARK: - Plist
  private static let infoDictionary: [String: Any] = {
    guard let dict = Bundle.main.infoDictionary else {
      fatalError("Plist file not found")
    }
    return dict
  }()
  
  public static let keychain: Keychain = {
    return Keychain(service: Bundle.main.bundleIdentifier!)
  }()
  
  public static let userAgent: String = {
      let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
      return "\(appName) Turbo Native (iOS) /\(versionNumber)"
  }()
  
  public static var rootURL: URL {
    guard let rootURLstring = infoDictionary[Keys.Plist.rootURL] as? String else {
      fatalError("Root URL not set in plist for this environment")
    }
    
    guard let demoURL = infoDictionary[Keys.Plist.demoURL] as? String else {
      fatalError("Root URL not set in plist for this environment")
    }

    guard let url = URL(string: isDemoMode ? demoURL : rootURLstring) else {
      fatalError("Root URL is invalid")
    }

    return url
  }
  
  public static func fullUrl(_ url: String) -> URL {
    return rootURL.appendingPathComponent(url)
  }
  
  public static func setPushTokenSaved(_ isSaved: Bool) {
    preferences.set(isSaved, forKey: "PushTokenSaved")
  }
  
  public static func setPref(_ value: Any, key: String) {
    preferences.set(value, forKey: key)
  }
  
  public static func setKeychainValue(_ value: Any?, key: String) {
    keychain[key] = value as? String
  }
}
