import Flutter
import UIKit
import GoogleSignIn

private func installCrashDebugHooks() {
  NSSetUncaughtExceptionHandler { exception in
    NSLog("[GSI CRASH][iOS] Uncaught exception name: \(exception.name.rawValue)")
    NSLog("[GSI CRASH][iOS] Reason: \(exception.reason ?? "unknown")")
    NSLog("[GSI CRASH][iOS] UserInfo: \(exception.userInfo ?? [:])")
    NSLog("[GSI CRASH][iOS] CallStack: \(exception.callStackSymbols.joined(separator: "\\n"))")
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {

  private func logGoogleSignInConfig() {
    guard let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] else {
      NSLog("[GSI DEBUG][iOS] CFBundleURLTypes not found in Info.plist")
      return
    }

    let schemes = urlTypes
      .compactMap { $0["CFBundleURLSchemes"] as? [String] }
      .flatMap { $0 }

    NSLog("[GSI DEBUG][iOS] URL schemes in Info.plist: \(schemes)")
    let hasGoogleScheme = schemes.contains { $0.hasPrefix("com.googleusercontent.apps") }
    NSLog("[GSI DEBUG][iOS] Google URL scheme present: \(hasGoogleScheme)")
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    NSLog("[GSI DEBUG][iOS] App launched. Initializing plugins...")
    installCrashDebugHooks()
    NSLog("[GSI DEBUG][iOS] Installed uncaught exception handler")
    logGoogleSignInConfig()
    GeneratedPluginRegistrant.register(with: self)
    NSLog("[GSI DEBUG][iOS] Plugins registered")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    NSLog("[GSI DEBUG][iOS] openURL received: \(url.absoluteString)")

    // Handle Google Sign-In URL scheme
    if url.scheme?.hasPrefix("com.googleusercontent.apps") == true {
      let handled = GIDSignIn.sharedInstance.handle(url)
      NSLog("[GSI DEBUG][iOS] GIDSignIn handled URL: \(handled)")
      return handled
    }
    
    // Fall back to other handlers
    NSLog("[GSI DEBUG][iOS] URL not Google Sign-In, forwarding to super")
    return super.application(app, open: url, options: options)
  }
}
