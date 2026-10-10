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

  /// Kept alive for the life of the app: it owns the open archive
  /// descriptors and the security scopes they hang on.
  private var storage: StorageBridge?

  /// Held for the same reason: reading scanned pages (#66).
  private var textRecognition: TextRecognitionBridge?

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Registered like a plugin rather than from the view controller, so it
    // has a messenger before any scene exists. The picker finds a
    // presenter for itself when it is actually opened.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PreppSuiteStorage") {
      storage = StorageBridge.register(with: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PreppSuiteTextRecognition") {
      textRecognition = TextRecognitionBridge.register(with: registrar.messenger())
    }
  }
}
