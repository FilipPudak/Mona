import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override var engine: FlutterEngine? {
    return (window?.rootViewController as? FlutterViewController)?.engine
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "device_timezone",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "getLocalTimezone" {
        result.success(TimeZone.current.identifier)
      } else {
        result.notImplemented()
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
