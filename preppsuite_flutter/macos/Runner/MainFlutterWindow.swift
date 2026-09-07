import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
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
    StorageBridge.register(with: flutterViewController.registrar(forPlugin: "StorageBridge"))

    super.awakeFromNib()
  }
}
