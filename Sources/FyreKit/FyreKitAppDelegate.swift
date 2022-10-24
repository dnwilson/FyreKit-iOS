//
//  FyreKitAppDelegate.swift
//  
//
//  Created by Dane Wilson on 10/13/22.
//

import Firebase
import FirebaseMessaging
import UIKit
import UserNotifications

open class FyreKitAppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {

  public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    FirebaseApp.configure()
    Messaging.messaging().delegate = self
    UNUserNotificationCenter.current().delegate = self
    
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { success, _ in
      guard success else { return }

      FyreKit.setPref(true, key: FyreKit.Keys.Plist.sendPushToken)
    }
    
    application.registerForRemoteNotifications()

    // Override point for customization after application launch.
    return true
  }
  
  public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    messaging.token { token, _ in
      guard let token =  token else {
        return
      }
      FyreKit.setKeychainValue(token, key: "push-token")
    }
  }
}

extension UIApplication {
  var keyWindow: UIWindow? {
    // Get connected scenes
    return UIApplication.shared.connectedScenes
    // Keep only active scenes, onscreen and visible to the user
      .filter { $0.activationState == .foregroundActive }
    // Keep only the first `UIWindowScene`
      .first(where: { $0 is UIWindowScene })
    // Get its associated windows
      .flatMap({ $0 as? UIWindowScene })?.windows
    // Finally, keep only the key window
      .first(where: \.isKeyWindow)
  }
}
