import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "device_timezone",
      binaryMessenger: engineBridge.engine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "getLocalTimezone" {
        result.success(TimeZone.current.identifier)
      } else {
        result.notImplemented()
      }
    }
  }
}
