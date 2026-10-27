#!/usr/bin/env python3
"""Exercise the actual macOS storage dispatcher without starting an app.

Only the Flutter transport and preferences are replaced. Foundation's
bookmarks, file coordination and writes run unchanged, in a temporary folder.
"""

import os
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

STUBS = r'''
import Foundation
typealias FlutterResult = (Any?) -> Void
typealias FlutterMethodCallHandler = (FlutterMethodCall, @escaping FlutterResult) -> Void
protocol FlutterBinaryMessenger {}
struct TestMessenger: FlutterBinaryMessenger {}
class FlutterPluginRegistrar { var messenger: FlutterBinaryMessenger { TestMessenger() } }
class FlutterMethodCall {
  let method: String
  let arguments: Any?
  init(_ method: String, _ arguments: Any?) { self.method = method; self.arguments = arguments }
}
class FlutterMethodChannel {
  static var handler: FlutterMethodCallHandler?
  init(name: String, binaryMessenger: FlutterBinaryMessenger) {}
  func setMethodCallHandler(_ callback: @escaping FlutterMethodCallHandler) { Self.handler = callback }
}
class FlutterError: NSObject {
  let code: String
  init(code: String, message: String?, details: Any?) { self.code = code }
}
class FlutterStandardTypedData { init(bytes: Data) {} }
let FlutterMethodNotImplemented = NSObject()
final class TestDefaults {
  static let standard = TestDefaults()
  private var values: [String: Any] = [:]
  func dictionary(forKey key: String) -> [String: Any]? { values[key] as? [String: Any] }
  func set(_ value: Any?, forKey key: String) { values[key] = value }
}
'''

PROBE = r'''
let bridge = StorageBridge.register(with: FlutterPluginRegistrar())
func call(_ method: String, _ arguments: [String: Any]) -> Any? {
  var answered = false
  var reply: Any?
  FlutterMethodChannel.handler!(FlutterMethodCall(method, arguments)) { value in
    answered = true
    reply = value
  }
  precondition(answered, "storage dispatcher did not answer")
  return reply
}
func write(_ uri: String, _ path: String) -> Any? {
  call("write", ["uri": uri, "path": path, "contents": "test contents"])
}
let root = URL(fileURLWithPath: ProcessInfo.processInfo.environment["STORAGE_CHECK_DIRECTORY"]!)
try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
guard let remembered = call("remember", ["path": root.path]) as? [String: String],
      let uri = remembered["uri"] else {
  fatalError("temporary folder bookmark could not be created")
}
precondition(write("bookmark://missing-test-handle", "test.json") is FlutterError)
print("storage: missing bookmark rejected")
precondition(write(uri, "nested/test.json") == nil)
let stored = try String(contentsOf: root.appendingPathComponent("nested/test.json"), encoding: .utf8)
precondition(stored == "test contents")
print("storage: coordinated write persisted")
try Data([1]).write(to: root.appendingPathComponent("blocked"))
precondition(write(uri, "blocked/test.json") is FlutterError)
print("storage: invalid parent rejected")
try FileManager.default.createDirectory(at: root.appendingPathComponent("directory.json"), withIntermediateDirectories: true)
precondition(write(uri, "directory.json") is FlutterError)
print("storage: failed coordinated write rejected")
withExtendedLifetime(bridge) {}
'''


def main():
    source = (ROOT / "preppsuite_flutter/macos/Runner/StorageBridge.swift").read_text()
    source = source.replace("import FlutterMacOS", "")
    source = source.replace("UserDefaults.standard", "TestDefaults.standard")
    with tempfile.TemporaryDirectory(prefix="storage-check-") as directory:
        env = dict(os.environ, STORAGE_CHECK_DIRECTORY=str(Path(directory) / "data"))
        return subprocess.run(
            ["xcrun", "swift", "-swift-version", "5", "-module-cache-path",
             str(Path(directory) / "modules"), "-"],
            input=STUBS + source + PROBE, text=True, env=env,
        ).returncode


if __name__ == "__main__":
    raise SystemExit(main())
