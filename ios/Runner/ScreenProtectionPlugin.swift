import AutomaticAssessmentConfiguration
import Flutter
import UIKit

/// iOS cannot block screen recording. It can say when the screen is being
/// recorded, mirrored or AirPlayed (`UIScreen.isCaptured`) and when a
/// screenshot was taken, so the lesson screen pauses and blurs the video
/// and the quiz hides its questions.
///
/// Quizzes can also run in Apple's assessment mode (`AEAssessmentSession`):
/// one app only, no screenshots, recording, notifications or dictation.
/// It needs the `com.apple.developer.automatic-assessment-configuration`
/// entitlement, which Apple grants on request; without it the session
/// fails to begin and the quiz goes on with detection only.
final class ScreenProtectionPlugin: NSObject, FlutterPlugin, FlutterStreamHandler,
  AEAssessmentSessionDelegate
{
  private var sink: FlutterEventSink?
  private var assessment: AEAssessmentSession?
  private var assessmentOn = false
  private var pendingStart: FlutterResult?

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
    case "setHideOverlays", "setDataSensitive":
      result(false)  // Android only
    case "startPin":
      startAssessment(result)
    case "stopPin":
      if let session = assessment, session.isActive { session.end() }
      assessmentOn = false
      result(true)
    case "isPinned":
      result(assessmentOn)
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

  // MARK: Assessment mode

  /// Answers `true` once the session began, `false` when it could not
  /// (no entitlement, another session, an older iOS).
  private func startAssessment(_ result: @escaping FlutterResult) {
    if assessmentOn { return result(true) }
    if pendingStart != nil { return result(false) }
    let session = AEAssessmentSession(configuration: AEAssessmentConfiguration())
    session.delegate = self
    assessment = session
    pendingStart = result
    session.begin()
  }

  func assessmentSessionDidBegin(_ session: AEAssessmentSession) {
    assessmentOn = true
    pendingStart?(true)
    pendingStart = nil
  }

  func assessmentSession(_ session: AEAssessmentSession, failedToBeginWithError error: Error) {
    assessmentOn = false
    assessment = nil
    pendingStart?(false)
    pendingStart = nil
  }

  func assessmentSession(_ session: AEAssessmentSession, wasInterruptedWithError error: Error) {
    // The system ended it (for example a phone call): the quiz is told,
    // records it, and ends the session.
    assessmentOn = false
    sink?(["pinned": false])
    session.end()
  }

  func assessmentSessionDidEnd(_ session: AEAssessmentSession) {
    assessmentOn = false
    if assessment === session { assessment = nil }
  }
}
