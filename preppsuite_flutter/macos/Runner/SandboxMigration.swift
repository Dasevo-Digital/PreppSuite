import Foundation

/// Carries the household into the sandbox container, once.
///
/// Up to 0.13.1 this app ran unsandboxed, so its database sat in the real
/// `~/Library/Application Support/de.status403.preppsuite/` and its
/// settings in the real `~/Library/Preferences/`. Sandboxed, neither is
/// visible: the app sees only its container.
///
/// macOS does migrate those two places into a container by itself — but
/// only when it creates the container, and only then. A container that
/// already exists (an earlier sandboxed build, a stray launch) makes the
/// system skip it silently, and the app comes up with an empty household
/// while the real one sits a few directories away, unreachable. That is
/// not a rare case; it is what this machine looked like.
///
/// So it is done here, explicitly, and early: before the Flutter engine
/// runs any Dart, because Dart's own migration would otherwise find the
/// container's empty Documents folder first and settle for it.
///
/// Reading the old locations needs the temporary-exception entitlements in
/// `Release.entitlements`. They are only for this, and they can go once no
/// installation is coming from before 0.14.0 any more.
enum SandboxMigration {
  private static let doneKey = "preppsuite.sandboxMigrationDone"

  /// Read from the running bundle, never written down.
  ///
  /// `PreppSuite Test.app` is the same build under
  /// `de.status403.preppsuite.test`, and the whole point of it is that it
  /// cannot touch the real household. A hardcoded identifier here would
  /// have the test copy adopt the production data on its first launch —
  /// quietly, and exactly once, which is the worst way to find out.
  private static var bundleId: String {
    Bundle.main.bundleIdentifier ?? "de.status403.preppsuite"
  }

  static func runIfNeeded() {
    let defaults = UserDefaults.standard
    guard !defaults.bool(forKey: doneKey) else { return }

    adoptDatabases()
    adoptPreferences()

    defaults.set(true, forKey: doneKey)
  }

  /// The user's actual home, not the container the sandbox pretends is
  /// one — `NSHomeDirectory()` returns the latter in here.
  private static var realHome: URL {
    if let directory = getpwuid(getuid())?.pointee.pw_dir {
      return URL(fileURLWithPath: String(cString: directory))
    }
    return URL(fileURLWithPath: NSHomeDirectory())
  }

  /// Where `path_provider` will look: Application Support inside the
  /// container, under the bundle identifier.
  private static var target: URL? {
    guard let base = FileManager.default.urls(
      for: .applicationSupportDirectory, in: .userDomainMask
    ).first else { return nil }
    return base.appendingPathComponent(bundleId, isDirectory: true)
  }

  private static func adoptDatabases() {
    let source = realHome
      .appendingPathComponent("Library/Application Support", isDirectory: true)
      .appendingPathComponent(bundleId, isDirectory: true)
    guard let target = target else { return }

    let manager = FileManager.default
    guard let entries = try? manager.contentsOfDirectory(
      at: source, includingPropertiesForKeys: nil
    ) else { return }

    try? manager.createDirectory(at: target, withIntermediateDirectories: true)

    for entry in entries {
      let name = entry.lastPathComponent
      // The household database and the per-archive full-text indexes, each
      // possibly with the two journal files SQLite writes beside it.
      guard name.hasPrefix("preppsuite"), name.contains(".sqlite") else { continue }

      let destination = target.appendingPathComponent(name)
      // Never over a file already there: an empty database that the app
      // has already opened would otherwise be replaced mid-flight, and a
      // second run would undo the first.
      guard !manager.fileExists(atPath: destination.path) else { continue }

      // Copied, not moved. The original stays readable where it is, so
      // going back to 0.13.x remains possible and a failure here cannot
      // cost anybody their household.
      try? manager.copyItem(at: entry, to: destination)
    }
  }

  private static func adoptPreferences() {
    let source = realHome
      .appendingPathComponent("Library/Preferences", isDirectory: true)
      .appendingPathComponent("\(bundleId).plist")

    guard let stored = NSDictionary(contentsOf: source) as? [String: Any] else { return }

    let defaults = UserDefaults.standard
    for (key, value) in stored {
      // AppKit's own remembered state — panel sizes, the last directory a
      // panel showed. The container has its own and they do not transfer
      // meaningfully.
      if key.hasPrefix("NS") || key.hasPrefix("com.apple.") { continue }
      // The old file wins over anything already in the container. The
      // container's copy comes either from the system's own migration —
      // in which case it is the same content — or from an older sandboxed
      // launch, in which case it is stale. The unsandboxed app is the one
      // that was actually in use, so its settings are the current ones.
      defaults.set(value, forKey: key)
    }
  }
}
