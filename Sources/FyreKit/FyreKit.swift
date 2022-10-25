import KeychainAccess
import SwiftUI
import Turbo

@available(iOS 15, *)
public struct FyreKit {
  public static var registerable: Registerable = FyreKitRegistration()
  
  // MARK: - Keys
  enum Keys {
    enum Plist {
      static let rootURL = "ROOT_URL"
      static let demoURL = "DEMO_URL"
      static let sendPushToken = "SEND_PUSH_TOKEN"
      static let appName = "APP_NAME"
    }
  }
  
  public static let accentColor = getColorFromConfig("ACCENT_COLOR")
  public static let bgColor = getColorFromConfig("BG_COLOR")
  public static let borderColor = getColorFromConfig("BORDER_COLOR")
  public static let disabledPrimaryColor = getColorFromConfig("PRIMARY_COLOR").opacity(0.25)
  public static let headingColor = getColorFromConfig("PRIMARY_COLOR")
  public static let primaryColor = getColorFromConfig("PRIMARY_COLOR")
  public static let textColor = getColorFromConfig("TEXT_COLOR")
  
  public static let baseFont = getFontFromConfig("BASE_FONT")
  public static let headingFont = getFontFromConfig("HEADING_FONT")

  public static var defaults: [String: [String: Any]] {
    return(
      [
        "colors" : [
          "ACCENT_COLOR" : Color(red: 226 / 255, green: 28 / 255, blue: 33 / 255),
          "BG_COLOR" : Color(red: 249 / 255, green: 251 / 255, blue: 253 / 255),
          "BORDER_COLOR" : Color(red: 227 / 255, green: 235 / 255, blue: 246 / 255),
          "PRIMARY_COLOR" : Color(red: 20 / 255, green: 136 / 255, blue: 229 / 255),
          "TEXT_COLOR" : Color(red: 72 / 255, green: 79 / 255, blue: 82 / 255)
        ],
        "fonts" : [
          "BASE_FONT": "OpenSans-Regular",
          "HEADING_FONT": "Poppins-Regular"
        ]
      ]
    )
  }
  
  
  private static func getColorFromConfig(_ key: String) -> Color {
    if let colorValues = infoDictionary[key] as? String {
      let array = colorValues.components(separatedBy: ", ")
      let red = Double(array[0])! / 255
      let green = Double(array[1])! / 255
      let blue = Double(array[2])! / 255
      
      return Color(red: red, green: green, blue: blue)
    } else {
      return defaults["colors"]?[key] as! Color
    }
  }
  
  private static func getFontFromConfig(_ key: String) -> String {
    if let font = infoDictionary[key] as? String {
      return font
    } else {
      return defaults["fonts"]?[key] as! String
    }
  }


  private init() {
  }
  
  public static func stringToDictionary(text: String) -> [String: Any]? {
    if let data = text.data(using: .utf8) {
      do {
        return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
      }
      catch {
        Log.i(error.localizedDescription)
      }
    }
    return nil
  }
  
  public static let preferences: UserDefaults = {
    return UserDefaults.standard
  }()
  
  public static func toggleDemoMode() {
    preferences.set(!preferences.bool(forKey: "DemoMode"), forKey: "DemoMode")
  }

  public static var appName : String { infoDictionary[Keys.Plist.appName] as? String ?? "FyreKit" }
  public static var loggedIn : Bool { preferences.bool(forKey: "LoggedIn") }
  public static var isDemoMode : Bool { preferences.bool(forKey: "DemoMode") }
  public static var pushTokenSaved : Bool { preferences.bool(forKey: "PushTokenSaved") }
  public static var hasAuthToken : Bool { authToken?.isPresent ?? false }
  public static var authToken : String? { keychain["access-token"] }
  public static var pushToken : String? { keychain["push-token"] }
  public static var loginHeaderMessage : String { infoDictionary["LOGIN_HEADER_MESSAGE"] as? String ?? "FyreKit" }
  
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
    return URL(string: url, relativeTo: rootURL)!
  }

  public static func setPref(_ value: Any, key: String) {
    preferences.set(value, forKey: key)
  }
  
  public static func setKeychainValue(_ value: Any?, key: String) {
    keychain[key] = value as? String
  }
}
