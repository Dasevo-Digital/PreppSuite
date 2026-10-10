import Vision
#if os(macOS)
  import FlutterMacOS
#else
  import Flutter
#endif

/// Reads the text on a scanned page with Apple's Vision (#66).
///
/// The page arrives as BGRA pixels drawn by PDFium on the Dart side, so
/// every platform reads the same image and this only has to recognise.
/// Nothing leaves the device: Vision is part of the system and runs on it.
///
/// The same file on macOS and iOS, apart from the Flutter import above.
/// See `lib/features/knowledge/application/text_recognition.dart`.
final class TextRecognitionBridge: NSObject {
  static let channelName = "de.dasevo.preppsuite/text_recognition"

  private let channel: FlutterMethodChannel

  /// Off the main thread: a page takes a tenth of a second on a Mac and
  /// longer on a phone, and the interface must keep drawing meanwhile.
  private let queue = DispatchQueue(
    label: "de.dasevo.preppsuite.text-recognition", qos: .userInitiated)

  /// Not @discardableResult, for the reason `StorageBridge.register` gives:
  /// the handler holds the bridge weakly, so a dropped result is a channel
  /// that silently answers nothing.
  static func register(with messenger: FlutterBinaryMessenger) -> TextRecognitionBridge {
    let bridge = TextRecognitionBridge(messenger: messenger)
    bridge.channel.setMethodCallHandler { [weak bridge] call, result in
      bridge?.handle(call, result)
    }
    return bridge
  }

  private init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    super.init()
  }

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any] ?? [:]
    let wanted = arguments["languages"] as? [String] ?? ["de-DE", "en-US"]
    switch call.method {
    case "support":
      result(languages(wanted).isEmpty ? "unsupported" : "available")
    case "recognize":
      guard let data = arguments["bgra"] as? FlutterStandardTypedData,
        let width = arguments["width"] as? Int,
        let height = arguments["height"] as? Int,
        width > 0, height > 0, data.data.count >= width * height * 4
      else {
        result(FlutterError(code: "arguments", message: "no page", details: nil))
        return
      }
      let languages = languages(wanted)
      queue.async {
        let answer: Any
        do {
          answer = try Self.recognize(
            data.data, width: width, height: height, languages: languages)
        } catch {
          answer = FlutterError(
            code: "recognition", message: error.localizedDescription, details: nil)
        }
        DispatchQueue.main.async { result(answer) }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Which of [wanted] this system's Vision can read. German arrived in
  /// Vision with macOS 13 and iOS 16; before that, English is what there
  /// is, and it still reads a German page's letters if not every umlaut.
  private func languages(_ wanted: [String]) -> [String] {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    guard let supported = try? request.supportedRecognitionLanguages() else { return [] }
    return wanted.filter { supported.contains($0) }
  }

  private static func recognize(
    _ pixels: Data, width: Int, height: Int, languages: [String]
  ) throws -> String {
    guard let provider = CGDataProvider(data: pixels as CFData),
      let image = CGImage(
        width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
        bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
        // BGRA in memory is little-endian ARGB, alpha first.
        bitmapInfo: CGBitmapInfo(
          rawValue: CGBitmapInfo.byteOrder32Little.rawValue
            | CGImageAlphaInfo.premultipliedFirst.rawValue),
        provider: provider, decode: nil, shouldInterpolate: false,
        intent: .defaultIntent)
    else { return "" }

    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    if !languages.isEmpty { request.recognitionLanguages = languages }
    try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
    return text(of: request.results ?? [])
  }

  /// The lines top to bottom, with a blank line where the gap above a line
  /// is more than one and a half of its own height -- a new block. The
  /// Dart side makes paragraphs of those.
  ///
  /// Vision's boxes are normalised with the origin at the bottom left, so
  /// "top to bottom" is a falling maxY.
  private static func text(of observations: [VNRecognizedTextObservation]) -> String {
    let lines = observations.compactMap { observation -> (box: CGRect, text: String)? in
      guard let candidate = observation.topCandidates(1).first else { return nil }
      return (observation.boundingBox, candidate.string)
    }.sorted { $0.box.maxY > $1.box.maxY }

    var out = ""
    var previous: CGRect?
    for line in lines {
      if let above = previous {
        let gap = above.minY - line.box.maxY
        out += gap > line.box.height * 1.5 ? "\n\n" : "\n"
      }
      out += line.text
      previous = line.box
    }
    return out
  }
}
