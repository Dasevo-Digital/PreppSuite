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

  /// Held while the bookmark store is read and written back. A pick adds to
  /// it on the main thread while a folder call on `fileReads` may write a
  /// stale bookmark anew (#410), and either could otherwise drop the
  /// other's entry.
  private static let bookmarksLock = NSLock()

  private static func updateBookmarks(_ change: (inout [String: Data]) -> Void) {
    bookmarksLock.lock()
    defer { bookmarksLock.unlock() }
    var store = UserDefaults.standard.dictionary(forKey: bookmarksKey) as? [String: Data] ?? [:]
    change(&store)
    UserDefaults.standard.set(store, forKey: bookmarksKey)
  }

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

  /// File work happens here rather than on the main thread, one call after
  /// another in the order Dart made them. A map being panned asks for tiles
  /// continuously, and file I/O in the middle of that is what turns smooth
  /// scrolling into jank. The shared folder's calls came later (#410): a
  /// device file of up to 64 MB or a picture of up to 24 MB written
  /// atomically into iCloud Drive or Nextcloud on the main thread froze the
  /// window.
  private let fileReads = DispatchQueue(label: "preppsuite.fileReads")

  /// Runs [work] on `fileReads` and answers on the main thread.
  ///
  /// Serial, so a write and the list or read after it happen in the order
  /// they were asked for, as they did on the main thread.
  private func onFileQueue(_ result: @escaping FlutterResult, _ work: @escaping () -> Any?) {
    fileReads.async {
      let value = work()
      DispatchQueue.main.async { result(value) }
    }
  }

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
    case "remember":
      remember(path: arguments["path"] as? String ?? "", result)
    case "openFile":
      result(openFile(arguments["uri"] as? String ?? "",
        token: arguments["fileToken"] as? String))
    case "readRange":
      readRange(
        arguments["fileToken"] as? String ?? arguments["uri"] as? String ?? "",
        offset: (arguments["offset"] as? NSNumber)?.uint64Value ?? 0,
        length: (arguments["length"] as? NSNumber)?.intValue ?? 0,
        result
      )
    case "closeFile":
      closeFile(arguments["fileToken"] as? String ?? arguments["uri"] as? String ?? "")
      result(nil)
    case "ensureWritable":
      onFileQueue(result) { self.ensureWritable(arguments["uri"] as? String ?? "") }
    case "list":
      onFileQueue(result) {
        self.list(arguments["uri"] as? String ?? "", arguments["path"] as? String ?? "")
      }
    case "read":
      onFileQueue(result) {
        self.read(arguments["uri"] as? String ?? "", arguments["path"] as? String ?? "",
          maxBytes: arguments["maxBytes"] as? Int ?? 64 * 1024 * 1024)
      }
    case "write":
      onFileQueue(result) {
        do {
          try self.write(
            arguments["uri"] as? String ?? "",
            path: arguments["path"] as? String ?? "",
            contents: arguments["contents"] as? String ?? ""
          )
          return nil
        } catch {
          return FlutterError(code: "write-failed", message: "The selected folder could not be written.", details: nil)
        }
      }
    case "delete":
      onFileQueue(result) {
        self.delete(arguments["uri"] as? String ?? "", arguments["path"] as? String ?? "")
      }
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
    Self.updateBookmarks { $0[identifier] = data }

    // The path comes along because a caller may want to write into the
    // folder with ordinary file I/O; the handle alone is only good for
    // storing. Whoever uses it must call resolvePath on a later launch.
    return [
      "uri": Self.scheme + identifier,
      "label": url.lastPathComponent,
      "path": url.path,
    ]
  }

  /// Makes a handle for a file the app already has access to.
  ///
  /// The app writes its own downloads into a folder the user picked, so
  /// it can reach the finished file right then — but only right then. A
  /// plain path into that folder is unusable on the next launch, when no
  /// scope is open, and the download would have to be hunted down by
  /// hand. So the path is turned into a bookmark while the door is still
  /// open, exactly as if it had been picked in a panel.
  private func remember(path: String, _ result: @escaping FlutterResult) {
    let url = URL(fileURLWithPath: path)
    guard FileManager.default.fileExists(atPath: url.path) else {
      result(nil)
      return
    }
    do {
      result(try remember(url))
    } catch {
      NSLog("PreppSuite: bookmark for %@ failed: %@", path, String(describing: error))
      result(nil)
    }
  }

  // MARK: - Bookmarks

  private func resolve(_ uri: String) -> URL? {
    guard uri.hasPrefix(Self.scheme) else { return nil }
    let identifier = String(uri.dropFirst(Self.scheme.count))

    let store = UserDefaults.standard.dictionary(forKey: Self.bookmarksKey) as? [String: Data] ?? [:]
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
        Self.updateBookmarks { $0[identifier] = fresh }
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
      var names: [String] = []
      var seen = Set<String>()
      for entry in entries
      where (try? entry.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true {
        // A file iCloud has not downloaded yet is a placeholder named
        // `.<name>.icloud` (#398). Listed as that, it was dropped by the
        // caller, which looks for `.json`, and never read: the other
        // devices' rows and pictures did not arrive while the run reported
        // success. Under its own name the caller reads it, and `read`
        // fetches it. Not fetched here: of the pictures only the missing
        // ones are read, and fetching all would undo what iOS freed.
        let name = Self.cloudPlaceholderTarget(entry.lastPathComponent) ?? entry.lastPathComponent
        if seen.insert(name).inserted { names.append(name) }
      }
      return names
    } ?? []
  }

  /// The name iCloud's placeholder `.<name>.icloud` stands for, or nil.
  ///
  /// iOS and macOS up to 13 keep such a placeholder in place of a file in
  /// iCloud Drive that is not on the device. Later systems, and other
  /// providers such as Nextcloud, list the file under its own name.
  private static func cloudPlaceholderTarget(_ name: String) -> String? {
    let suffix = ".icloud"
    guard name.hasPrefix("."), name.hasSuffix(suffix), name.count > suffix.count + 1 else {
      return nil
    }
    return String(name.dropFirst().dropLast(suffix.count))
  }

  private static func cloudPlaceholder(for file: URL) -> URL {
    return file.deletingLastPathComponent()
      .appendingPathComponent(".\(file.lastPathComponent).icloud")
  }

  /// How long a read waits for iCloud to download a file.
  ///
  /// The read blocks `fileReads`, and with it every other folder call and
  /// the map's tiles. After this it gives up with `read-failed`, which costs
  /// a device file or a picture only this run; the download goes on, and a
  /// later run reads the file.
  private static let downloadWait: TimeInterval = 30

  private static let readFailed = FlutterError(
    code: "read-failed", message: "The file could not be read.", details: nil)

  private func read(_ uri: String, _ path: String, maxBytes: Int) -> Any? {
    let limit = max(0, min(maxBytes, 64 * 1024 * 1024))
    return withAccess(uri) { root -> Any? in
      var segments = Self.segments(path)
      guard let name = segments.popLast(),
            let folder = directory(in: root, segments: segments, create: false)
      else { return nil }

      let file = folder.appendingPathComponent(name)
      let placeholder = Self.cloudPlaceholder(for: file)
      let files = FileManager.default
      // Asked for here as well as by the coordinated read below (#398), so
      // that the download goes on when the read stops waiting for it.
      let pending = !files.fileExists(atPath: file.path) && files.fileExists(atPath: placeholder.path)
      if pending { try? files.startDownloadingUbiquitousItem(at: file) }
      var text: Any?
      // Coordinated because the folder is the whole point of the feature
      // and it is normally a cloud one — iCloud Drive, Nextcloud. An
      // uncoordinated read of a file another device just wrote can find a
      // placeholder that has not been downloaded yet; a coordinated one
      // waits for the download. For an iCloud placeholder up to
      // `downloadWait` only, as its download no longer needs the read.
      // Other providers fetch for the read itself, so that one waits.
      let coordinator = NSFileCoordinator()
      let giveUp = DispatchWorkItem { coordinator.cancel() }
      if pending {
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + Self.downloadWait, execute: giveUp)
      }
      defer { giveUp.cancel() }
      var coordinationError: NSError?
      coordinator.coordinate(readingItemAt: file, options: [], error: &coordinationError) { url in
        do {
          let handle = try FileHandle(forReadingFrom: url)
          defer { handle.closeFile() }
          var data = Data()
          while data.count <= limit {
            let chunk: Data
            let count = min(8192, limit - data.count + 1)
            if #available(macOS 10.15.4, iOS 13.0, *) {
              chunk = try handle.read(upToCount: count) ?? Data()
            } else { chunk = handle.readData(ofLength: count) }
            if chunk.isEmpty { break }
            data.append(chunk)
          }
          if data.count > limit {
            text = FlutterError(code: "read-too-large", message: "File exceeds the read limit.", details: nil)
          } else { text = String(data: data, encoding: .utf8) ?? Self.readFailed }
        } catch {
          // Not nil where the file is there: nil says it is not, and the
          // caller may then write a new one over it. A placeholder is a
          // file that is there.
          let there = files.fileExists(atPath: url.path) || files.fileExists(atPath: placeholder.path)
          text = there ? Self.readFailed : nil
        }
      }
      if coordinationError != nil && text == nil { return Self.readFailed }
      return text
    }
  }

  private func write(_ uri: String, path: String, contents: String) throws {
    guard let root = resolve(uri) else { throw CocoaError(.fileNoSuchFile) }
    let scoped = root.startAccessingSecurityScopedResource()
    defer { if scoped { root.stopAccessingSecurityScopedResource() } }
    var segments = Self.segments(path)
    guard let name = segments.popLast(),
          let folder = directory(in: root, segments: segments, create: true)
    else { throw CocoaError(.fileWriteUnknown) }

    let file = folder.appendingPathComponent(name)
    var coordinationError: NSError?
    var written: Result<Void, Error>?
    NSFileCoordinator().coordinate(writingItemAt: file, options: .forReplacing, error: &coordinationError) { url in
      written = Result { try contents.write(to: url, atomically: true, encoding: .utf8) }
    }
    if let error = coordinationError { throw error }
    guard let outcome = written else { throw CocoaError(.fileWriteUnknown) }
    try outcome.get()
  }

  /// Removes one file inside the folder: a picture no row names any more
  /// (#376). Coordinated like a write, so a cloud provider that is still
  /// downloading the file is not handed a hole. False when there was
  /// nothing to remove or it could not go; either way the caller tries
  /// again on a later run.
  private func delete(_ uri: String, _ path: String) -> Bool {
    return withAccess(uri) { root -> Bool? in
      var segments = Self.segments(path)
      guard let name = segments.popLast(), name != ".", name != "..",
            !segments.contains(".."),
            let folder = directory(in: root, segments: segments, create: false)
      else { return false }
      let file = folder.appendingPathComponent(name)
      guard FileManager.default.fileExists(atPath: file.path) else {
        // Not downloaded (#398). Fetched, so that a later run finds the
        // file itself to remove rather than its placeholder.
        if FileManager.default.fileExists(atPath: Self.cloudPlaceholder(for: file).path) {
          try? FileManager.default.startDownloadingUbiquitousItem(at: file)
        }
        return false
      }
      var removed = false
      var coordinationError: NSError?
      NSFileCoordinator().coordinate(writingItemAt: file, options: .forDeleting, error: &coordinationError) { url in
        removed = (try? FileManager.default.removeItem(at: url)) != nil
      }
      return removed
    } ?? false
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

  private func openFile(_ uri: String, token: String? = nil) -> Bool {
    let key = token ?? uri
    closeFile(key)

    guard let url = resolve(uri) else { return false }
    let scoped = url.startAccessingSecurityScopedResource()
    guard let handle = try? FileHandle(forReadingFrom: url) else {
      if scoped { url.stopAccessingSecurityScopedResource() }
      return false
    }
    // The scope stays open until closeFile: it is what the descriptor
    // hangs on, and reacquiring it per read would cost more than the read.
    openFiles[key] = OpenFile(url: url, handle: handle, scoped: scoped)
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
        // target was 10.15. The older calls do the same thing but report
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
