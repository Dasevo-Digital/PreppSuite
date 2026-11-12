import Flutter
import UIKit
import UserNotifications
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// The warning poll's task, as Dart registers it
  /// (`warningPollTaskUniqueName` in warning_background_worker.dart) and as
  /// Info.plist permits it.
  static let warningPollTask = "preppsuite.warningPoll.periodic"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Banners while the app is open (#345). Without a delegate iOS shows a
    // notification only when the app is in the background, and a warning
    // that arrived during a poll in the foreground was marked as told and
    // never seen. FlutterAppDelegate passes the calls on to the
    // notification plugin, which answers with the banner.
    UNUserNotificationCenter.current().delegate = self

    // The background poll (#345). BGTaskScheduler takes a task's launch
    // handler only before launching ends, and runs only identifiers listed
    // in Info.plist. Registered here, the plugin's own submit from Dart
    // finds the handler in place; the background engine gets every plugin
    // the poll needs: notifications, preferences, the keychain, SQLite.
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: AppDelegate.warningPollTask,
      earliestBeginInSeconds: NSNumber(value: 15 * 60)
    )

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
