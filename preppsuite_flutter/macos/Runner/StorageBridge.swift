import AppKit
import FlutterMacOS

/// Everything the app needs from storage the user picked.
///
/// The sandbox is on, so a folder or file chosen in a panel is reachable
/// only for as long as the process lives. What survives is a bookmark: a
/// blob that resolves back into the same URL on a later launch. The picker
/// stores one and hands Dart an opaque `bookmark://<id>` instead of a
/// path; the scheme is what tells the Dart side which reader to use.
///
/// The method names and the scheme match `StorageBridge.swift` on iOS and
/// `MainActivity.kt` on Android exactly. That is deliberate: one Dart
/// implementation drives all three.
///
/// The one thing that cannot be borrowed from the other platforms is the
/// panel. It has to run here, in the same native call that writes the
/// bookmark, because the permission hangs on the `NSURL` object the panel
/// returns and not on its path. Handing the path up to Dart and building a
/// `URL(fileURLWithPath:)` from it later loses the permission, and
/// `bookmarkData(.withSecurityScope)` then fails — which is why this does
/// not go through `file_picker`.
final class StorageBridge: NSObject {
  static let channelName = "preppsuite/storage"

  /// Where the bookmarks live between launches. Small — one blob per
  /// folder or archive the user ever picked.
  private static let bookmarksKey = "preppsuite.storageBookmarks"

  private static let scheme = "bookmark://"

  private let channel: FlutterMethodChannel

  /// Descriptors for archives being read in ranges, by uri.
  ///
  /// A map or encyclopedia archive is gigabytes and is read a few
  /// kilobytes at a time. Reopening it per read — and re-entering the
  /// security scope each time — is the difference between a map that pans
  /// and one that stutters.
  private var openFiles: [String: OpenFile] = [:]

  /// Scopes held open for the life of the process, by uri.
  ///
  /// What `resolvePath` is for: once the scope is held, the path it
  /// returns can be used with ordinary file I/O from Dart. That is how
  /// the download folder stays a plain directory the downloader writes
  /// into, instead of every write having to cross this channel.
  private var heldScopes: [String: URL] = [:]

  /// Reads happen here rather than on the main thread: a map being panned
  /// asks for tiles continuously, and file I/O in the middle of that is
  /// what turns smooth scrolling into jank.
  private let fileReads = DispatchQueue(label: "preppsuite.fileReads")

  private final class OpenFile {
    init(url: URL, handle: FileHandle, scoped: Bool) {
      self.url = url
      self.handle = handle
      self.scoped = scoped
    }

    let url: URL
    let handle: FileHandle
    let scoped: Bool

    func close() {
      try? handle.close()
      if scoped { url.stopAccessingSecurityScopedResource() }
    }
  }

  /// Deliberately NOT @discardableResult: the returned bridge must be
  /// held by the caller. The handler below captures it weakly, so a
  /// discarded result is deallocated immediately and every call is
  /// dropped without a trace — which is exactly what happened once.
  static func register(with registrar: FlutterPluginRegistrar) -> StorageBridge {
    let bridge = StorageBridge(messenger: registrar.messenger)
    bridge.channel.setMethodCallHandler { [weak bridge] call, result in
      bridge?.handle(call, result)
    }
    return bridge
  }

  private init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    super.init()
  }

  // MARK: - Dispatch

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any] ?? [:]

    switch call.method {
    case "pick":
      pick(folder: true, message: arguments["dialogTitle"] as? String, result)
    case "pickFile":
      pick(folder: false, message: arguments["dialogTitle"] as? String, result)
    case "resolvePath":
      result(resolvePath(arguments["uri"] as? String ?? ""))
    case "openFile":
      result(openFile(arguments["uri"] as? String ?? ""))
    case "readRange":
      readRange(
        arguments["uri"] as? String ?? "",
        offset: (arguments["offset"] as? NSNumber)?.uint64Value ?? 0,
        length: (arguments["length"] as? NSNumber)?.intValue ?? 0,
        result
      )
    case "closeFile":
      closeFile(arguments["uri"] as? String ?? "")
      result(nil)
    case "ensureWritable":
      result(ensureWritable(arguments["uri"] as? String ?? ""))
    case "list":
      result(list(arguments["uri"] as? String ?? "", arguments["path"] as? String ?? ""))
    case "read":
      result(read(arguments["uri"] as? String ?? "", arguments["path"] as? String ?? ""))
    case "write":
      write(
        arguments["uri"] as? String ?? "",
        path: arguments["path"] as? String ?? "",
        contents: arguments["contents"] as? String ?? ""
      )
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Picking

  private func pick(folder: Bool, message: String?, _ result: @escaping FlutterResult) {
    // NSOpenPanel is main-thread only.
    DispatchQueue.main.async {
      let panel = NSOpenPanel()
      panel.canChooseDirectories = folder
      panel.canChooseFiles = !folder
      panel.allowsMultipleSelection = false
      panel.canCreateDirectories = folder
      if let message = message { panel.message = message }

      panel.begin { response in
        guard response == .OK, let url = panel.url else {
          // Cancelled. Told apart from a failure below, because the two
          // look identical from Dart and only one of them is a bug.
          result(nil)
          return
        }
        do {
          result(try self.remember(url))
        } catch {
          // Silence here is what makes this impossible to diagnose: the
          // panel closes, nothing changes, and nobody learns why. The
          // Dart side turns this into a message on screen.
          NSLog("PreppSuite: bookmark for %@ failed: %@",
                url.path, String(describing: error))
          result(FlutterError(
            code: "bookmark-failed",
            message: String(describing: error),
            details: url.path
          ))
        }
      }
    }
  }

  /// Turns a picked URL into something that still works next week.
  ///
  /// Made here and now, while the URL is the one the panel handed over:
  /// that object carries the permission, and nothing reconstructed from
  /// its path does.
  private func remember(_ url: URL) throws -> [String: String] {
    let data = try url.bookmarkData(
      options: .withSecurityScope,
      includingResourceValuesForKeys: nil,
      relativeTo: nil
    )

    let identifier = UUID().uuidString
    var store = UserDefaults.standard.dictionary(forKey: Self.bookmarksKey) as? [String: Data] ?? [:]
    store[identifier] = data
    UserDefaults.standard.set(store, forKey: Self.bookmarksKey)

    // The path comes along because a caller may want to write into the
    // folder with ordinary file I/O; the handle alone is only good for
    // storing. Whoever uses it must call resolvePath on a later launch.
    return [
      "uri": Self.scheme + identifier,
      "label": url.lastPathComponent,
      "path": url.path,
    ]
  }

  // MARK: - Bookmarks

  private func resolve(_ uri: String) -> URL? {
    guard uri.hasPrefix(Self.scheme) else { return nil }
    let identifier = String(uri.dropFirst(Self.scheme.count))

    var store = UserDefaults.standard.dictionary(forKey: Self.bookmarksKey) as? [String: Data] ?? [:]
    guard let data = store[identifier] else { return nil }

    var stale = false
    guard let url = try? URL(
      resolvingBookmarkData: data,
      options: .withSecurityScope,
      relativeTo: nil,
      bookmarkDataIsStale: &stale
    ) else { return nil }

    // A stale bookmark still resolves; it just will not survive many more
    // launches unless it is written again. Rewriting needs the scope held,
    // or the fresh blob records a URL the app may not reopen.
    if stale {
      let scoped = url.startAccessingSecurityScopedResource()
      defer { if scoped { url.stopAccessingSecurityScopedResource() } }
      if let fresh = try? url.bookmarkData(
        options: .withSecurityScope,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      ) {
        store[identifier] = fresh
        UserDefaults.standard.set(store, forKey: Self.bookmarksKey)
      }
    }
    return url
  }

  /// Runs [body] with the security scope held, or returns nil when the
  /// bookmark no longer resolves — which happens when the folder is
  /// deleted, or the volume it sits on is not mounted.
  private func withAccess<T>(_ uri: String, _ body: (URL) -> T?) -> T? {
    guard let url = resolve(uri) else { return nil }
    let scoped = url.startAccessingSecurityScopedResource()
    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
    return body(url)
  }

  /// Resolves a stored handle into a path the app may actually use, and
  /// keeps the scope open so it stays usable.
  ///
  /// Deliberately never released: the folder is wanted for as long as the
  /// app runs, and macOS caps the number of open scopes far above the
  /// handful this app has.
  private func resolvePath(_ uri: String) -> String? {
    if let held = heldScopes[uri] { return held.path }
    guard let url = resolve(uri) else { return nil }
    guard url.startAccessingSecurityScopedResource() else { return nil }
    heldScopes[uri] = url
    return url.path
  }

  // MARK: - Folder operations

  private func ensureWritable(_ uri: String) -> Bool {
    return withAccess(uri) { root in
      guard FileManager.default.isWritableFile(atPath: root.path) else { return false }
      return directory(in: root, segments: ["preppsuite", "devices"], create: true) != nil
    } ?? false
  }

  private func list(_ uri: String, _ path: String) -> [String] {
    return withAccess(uri) { root -> [String] in
      guard let folder = directory(in: root, segments: Self.segments(path), create: false) else {
        return []
      }
      let entries = (try? FileManager.default.contentsOfDirectory(
        at: folder,
        includingPropertiesForKeys: [.isRegularFileKey]
      )) ?? []
      return entries.filter { (try? $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true }
        .map { $0.lastPathComponent }
    } ?? []
  }

  private func read(_ uri: String, _ path: String) -> String? {
    return withAccess(uri) { root -> String? in
      var segments = Self.segments(path)
      guard let name = segments.popLast(),
            let folder = directory(in: root, segments: segments, create: false)
      else { return nil }

      let file = folder.appendingPathComponent(name)
      var text: String?
      // Coordinated because the folder is the whole point of the feature
      // and it is normally a cloud one — iCloud Drive, Nextcloud. An
      // uncoordinated read of a file another device just wrote can find a
      // placeholder that has not been downloaded yet.
      var coordinationError: NSError?
      NSFileCoordinator().coordinate(readingItemAt: file, options: [], error: &coordinationError) { url in
        text = try? String(contentsOf: url, encoding: .utf8)
      }
      return text
    }
  }

  private func write(_ uri: String, path: String, contents: String) {
    _ = withAccess(uri) { root -> Bool? in
      var segments = Self.segments(path)
      guard let name = segments.popLast(),
            let folder = directory(in: root, segments: segments, create: true)
      else { return nil }

      let file = folder.appendingPathComponent(name)
      var coordinationError: NSError?
      NSFileCoordinator().coordinate(writingItemAt: file, options: .forReplacing, error: &coordinationError) { url in
        try? contents.write(to: url, atomically: true, encoding: .utf8)
      }
      return true
    }
  }

  private func directory(in root: URL, segments: [String], create: Bool) -> URL? {
    var current = root
    for segment in segments {
      current = current.appendingPathComponent(segment, isDirectory: true)

      var isDirectory: ObjCBool = false
      if FileManager.default.fileExists(atPath: current.path, isDirectory: &isDirectory) {
        if !isDirectory.boolValue { return nil }
        continue
      }
      guard create else { return nil }
      guard (try? FileManager.default.createDirectory(at: current, withIntermediateDirectories: true)) != nil
      else { return nil }
    }
    return current
  }

  private static func segments(_ path: String) -> [String] {
    return path.split(separator: "/").map(String.init)
  }

  // MARK: - Ranged reads, for the map and encyclopedia archives

  private func openFile(_ uri: String) -> Bool {
    closeFile(uri)

    guard let url = resolve(uri) else { return false }
    let scoped = url.startAccessingSecurityScopedResource()
    guard let handle = try? FileHandle(forReadingFrom: url) else {
      if scoped { url.stopAccessingSecurityScopedResource() }
      return false
    }
    // The scope stays open until closeFile: it is what the descriptor
    // hangs on, and reacquiring it per read would cost more than the read.
    openFiles[uri] = OpenFile(url: url, handle: handle, scoped: scoped)
    return true
  }

  private func readRange(
    _ uri: String,
    offset: UInt64,
    length: Int,
    _ result: @escaping FlutterResult
  ) {
    guard let file = openFiles[uri] else {
      result(FlutterError(code: "not-open", message: "no open descriptor for \(uri)", details: nil))
      return
    }

    fileReads.async {
      do {
        // The throwing pair only exists from 10.15.4; the deployment
        // target is 10.15. The older calls do the same thing but report
        // failure as an Objective-C exception, which Swift cannot catch —
        // so on those systems a bad read takes the app down rather than
        // returning an error. Accepted knowingly: it covers four point
        // releases of Catalina, and raising the minimum would shut out
        // machines that can otherwise run this fine.
        let data: Data
        if #available(macOS 10.15.4, *) {
          try file.handle.seek(toOffset: offset)
          data = try file.handle.read(upToCount: length) ?? Data()
        } else {
          file.handle.seek(toFileOffset: offset)
          data = file.handle.readData(ofLength: length)
        }
        DispatchQueue.main.async { result(FlutterStandardTypedData(bytes: data)) }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "read-failed", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  private func closeFile(_ uri: String) {
    openFiles.removeValue(forKey: uri)?.close()
  }
}
