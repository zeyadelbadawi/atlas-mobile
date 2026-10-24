import Flutter
import UIKit

/// iOS cannot block screen recording. It can say when the screen is being
/// recorded, mirrored or AirPlayed (`UIScreen.isCaptured`) and when a
/// screenshot was taken, so the lesson screen pauses and blurs the video.
final class ScreenProtectionPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var sink: FlutterEventSink?

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = ScreenProtectionPlugin()
    let methods = FlutterMethodChannel(
      name: "atlas/screen_protection", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: methods)
    let events = FlutterEventChannel(
      name: "atlas/screen_capture/events", binaryMessenger: registrar.messenger())
    events.setStreamHandler(instance)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setSecure":
      result(false)  // not possible on iOS; the Dart side relies on isCaptured
    case "isCaptured":
      result(Self.captured)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    sink = events
    let center = NotificationCenter.default
    center.addObserver(
      self, selector: #selector(capturedChanged),
      name: UIScreen.capturedDidChangeNotification, object: nil)
    center.addObserver(
      self, selector: #selector(screenshotTaken),
      name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    events(["captured": Self.captured])
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    NotificationCenter.default.removeObserver(self)
    sink = nil
    return nil
  }

  @objc private func capturedChanged() {
    sink?(["captured": Self.captured])
  }

  @objc private func screenshotTaken() {
    sink?(["screenshot": true])
  }

  private static var captured: Bool {
    if #available(iOS 17.0, *) {
      return UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.screen.isCaptured }
        .contains(true)
    }
    return UIScreen.main.isCaptured
  }
}
