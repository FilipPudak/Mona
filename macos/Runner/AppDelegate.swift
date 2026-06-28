import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    let controller = mainFlutterWindow?.flutterViewController as? FlutterViewController
    guard let messenger = controller?.engine.binaryMessenger else { return }
    let channel = FlutterMethodChannel(name: "device_timezone", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      if call.method == "getLocalTimezone" {
        result.success(TimeZone.current.identifier)
      } else {
        result.notImplemented()
      }
    }
  }
}
