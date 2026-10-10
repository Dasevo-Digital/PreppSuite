import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  /// Kept alive for the life of the window: it owns the open archive
  /// descriptors and the security scopes they hang on.
  ///
  /// Not optional decoration. The channel handler holds the bridge weakly
  /// so the two do not retain each other, which means dropping the result
  /// of `register` deallocates it on the spot — and every later call is
  /// then silently discarded: no panel, no error, no log line, and a Dart
  /// future that never completes. `AppDelegate.swift` on iOS keeps its
  /// own reference for the same reason.
  private var storage: StorageBridge?

  /// Held for the same reason: reading scanned pages (#66).
  private var textRecognition: TextRecognitionBridge?

  override func awakeFromNib() {
    // Before the engine exists, so no setting is read from the empty
    // defaults first.
    takeOverFormerPreferences()

    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    storage = StorageBridge.register(
      with: flutterViewController.registrar(forPlugin: "StorageBridge")
    )
    textRecognition = TextRecognitionBridge.register(
      with: flutterViewController.registrar(forPlugin: "TextRecognitionBridge").messenger
    )

    super.awakeFromNib()
  }
}

/// The bundle identifiers this app had until 2.x.
private let formerIdentifiers = [
  "de.dasevo.preppsuite": "de.status403.preppsuite",
  "de.dasevo.preppsuite.test": "de.status403.preppsuite.test",
]

/// Carries the settings over from the former identifier, once.
///
/// `shared_preferences` keeps them in `NSUserDefaults`, which macOS files
/// under the bundle identifier — a plist in the old container, not in the
/// folder `former_identity.dart` moves. Without this a new identifier
/// would start with every setting at its default: language, theme, the
/// region for warnings.
///
/// Only keys the plugin owns (`flutter.`), and only while none exist here:
/// a defaults domain that has been written to under the new identifier is
/// this installation's own. The old plist is read, never changed.
private func takeOverFormerPreferences() {
  guard let current = Bundle.main.bundleIdentifier,
    let former = formerIdentifiers[current]
  else { return }
  let defaults = UserDefaults.standard
  let owned = { (key: String) in key.hasPrefix("flutter.") }
  if defaults.dictionaryRepresentation().keys.contains(where: owned) { return }

  // Inside the sandbox NSHomeDirectory() is the container; the old one
  // sits beside it under the real home.
  guard let entry = getpwuid(getuid()),
    let home = String(validatingUTF8: entry.pointee.pw_dir)
  else { return }
  let file =
    "\(home)/Library/Containers/\(former)/Data/Library/Preferences/\(former).plist"
  guard let values = NSDictionary(contentsOfFile: file) as? [String: Any] else {
    return
  }
  for (key, value) in values where owned(key) {
    defaults.set(value, forKey: key)
  }
}
