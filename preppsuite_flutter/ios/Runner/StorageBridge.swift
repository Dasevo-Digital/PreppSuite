import Flutter
import UIKit
import UniformTypeIdentifiers

/// Everything the app needs from storage the user picked.
///
/// iOS never hands out a path that keeps working. A folder or file chosen
/// in the document picker comes back as a *security-scoped* URL whose
/// access dies with the process — and unlike macOS, where this app simply
/// turns the sandbox off, there is no such escape here.
///
/// What survives is a bookmark: a blob that can be resolved back into the
/// same URL on a later launch. So the picker stores one and hands Dart an
/// opaque `bookmark://<id>` instead of a path. Dart never sees the blob,
/// and the scheme is what tells the Dart side which reader to use — the
/// same trick Android's `content://` plays.
///
/// The method names match `MainActivity.kt` exactly. That is deliberate:
/// one Dart implementation drives both, so the layout written into a
/// shared folder is the same one on either platform.
final class StorageBridge: NSObject {
  static let channelName = "preppsuite/storage"

  /// Where the bookmarks live between launches. Small — one blob per
  /// folder or archive the user ever picked.
  private static let bookmarksKey = "preppsuite.storageBookmarks"

  private static let scheme = "bookmark://"

  private let channel: FlutterMethodChannel

  /// Set while the picker is open; there is only ever one.
  private var pendingPick: FlutterResult?

  /// Descriptors for archives being read in ranges, by uri.
  ///
  /// A map or encyclopedia archive is gigabytes and is read a few
  /// kilobytes at a time. Reopening it per read — and re-entering the
  /// security scope each time — is the difference between a map that pans
  /// and one that stutters.
  private var openFiles: [String: OpenFile] = [:]

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

  @discardableResult
  static func register(with messenger: FlutterBinaryMessenger) -> StorageBridge {
    let bridge = StorageBridge(messenger: messenger)
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
      pick(folder: true, result)
    case "pickFile":
      pick(folder: false, result)
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
    case "excludeFromBackup":
      result(excludeFromBackup(arguments["path"] as? String ?? ""))
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

  private func pick(folder: Bool, _ result: @escaping FlutterResult) {
    pendingPick?(nil)
    pendingPick = result

    // asCopy is false on purpose. The default copies the chosen file into
    // the app's container, which for a country map extract or a Wikipedia
    // archive means several gigabytes written twice — and then thrown
    // away with the next cache sweep, taking the archive with it.
    let picker = UIDocumentPickerViewController(
      forOpeningContentTypes: folder ? [.folder] : [.item],
      asCopy: false
    )
    picker.delegate = self
    picker.allowsMultipleSelection = false
    picker.shouldShowFileExtensions = true

    guard let presenter = Self.topViewController() else {
      pendingPick = nil
      result(nil)
      return
    }
    presenter.present(picker, animated: true)
  }

  /// Turns a picked URL into something that still works next week.
  ///
  /// The bookmark has to be made while the security scope is held, or it
  /// records a URL the app will not be allowed to reopen.
  private func remember(_ url: URL) -> [String: String]? {
    let scoped = url.startAccessingSecurityScopedResource()
    defer { if scoped { url.stopAccessingSecurityScopedResource() } }

    guard let data = try? url.bookmarkData() else { return nil }

    let identifier = UUID().uuidString
    var store = UserDefaults.standard.dictionary(forKey: Self.bookmarksKey) as? [String: Data] ?? [:]
    store[identifier] = data
    UserDefaults.standard.set(store, forKey: Self.bookmarksKey)

    return ["uri": Self.scheme + identifier, "label": url.lastPathComponent]
  }

  // MARK: - Bookmarks

  private func resolve(_ uri: String) -> URL? {
    guard uri.hasPrefix(Self.scheme) else { return nil }
    let identifier = String(uri.dropFirst(Self.scheme.count))

    var store = UserDefaults.standard.dictionary(forKey: Self.bookmarksKey) as? [String: Data] ?? [:]
    guard let data = store[identifier] else { return nil }

    var stale = false
    guard let url = try? URL(resolvingBookmarkData: data, bookmarkDataIsStale: &stale) else {
      return nil
    }

    // A stale bookmark still resolves; it just will not survive many more
    // launches unless it is written again.
    if stale {
      let scoped = url.startAccessingSecurityScopedResource()
      defer { if scoped { url.stopAccessingSecurityScopedResource() } }
      if let fresh = try? url.bookmarkData() {
        store[identifier] = fresh
        UserDefaults.standard.set(store, forKey: Self.bookmarksKey)
      }
    }
    return url
  }

  /// Runs [body] with the security scope held, or returns nil when the
  /// bookmark no longer resolves — which happens when the folder is
  /// deleted, or the app is reinstalled.
  private func withAccess<T>(_ uri: String, _ body: (URL) -> T?) -> T? {
    guard let url = resolve(uri) else { return nil }
    let scoped = url.startAccessingSecurityScopedResource()
    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
    return body(url)
  }

  // MARK: - Folder operations

  /// Keeps a file out of iCloud's backup.
  ///
  /// An archive lands in this app's Documents folder, which iOS backs up
  /// by default — so without this a multi-gigabyte encyclopedia would be
  /// uploaded to the user's iCloud, over their connection and against
  /// their storage quota. Apple asks for this flag on anything that can
  /// simply be downloaded again.
  ///
  /// Takes a plain path rather than a bookmark: what this marks is a file
  /// the app wrote itself, inside its own container, where there is no
  /// security scope to open.
  private func excludeFromBackup(_ path: String) -> Bool {
    guard !path.isEmpty else { return false }

    var url = URL(fileURLWithPath: path)
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    do {
      try url.setResourceValues(values)
      return true
    } catch {
      return false
    }
  }

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
        try file.handle.seek(toOffset: offset)
        let data = try file.handle.read(upToCount: length) ?? Data()
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

  // MARK: - Presentation

  private static func topViewController() -> UIViewController? {
    let scene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
      ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first

    var controller = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
      ?? scene?.windows.first?.rootViewController
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    return controller
  }
}

extension StorageBridge: UIDocumentPickerDelegate {
  func documentPicker(
    _ controller: UIDocumentPickerViewController,
    didPickDocumentsAt urls: [URL]
  ) {
    guard let result = pendingPick else { return }
    pendingPick = nil

    guard let url = urls.first else {
      result(nil)
      return
    }
    result(remember(url))
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pendingPick?(nil)
    pendingPick = nil
  }
}
