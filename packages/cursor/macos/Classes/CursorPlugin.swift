import Cocoa
import FlutterMacOS

public class CursorPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "cursor", binaryMessenger: registrar.messenger)
    let instance = CursorPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "hide":
      NSCursor.hide()
      result(nil)
    case "show":
      NSCursor.unhide()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
