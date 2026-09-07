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

  override func awakeFromNib() {
    // Before the engine exists, and therefore before any Dart runs: the
    // Dart side has a migration of its own that would otherwise settle
    // for the container's empty folders. See SandboxMigration.swift.
    SandboxMigration.runIfNeeded()

    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    storage = StorageBridge.register(
      with: flutterViewController.registrar(forPlugin: "StorageBridge")
    )

    super.awakeFromNib()
  }
}
