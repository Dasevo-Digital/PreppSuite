// Measures what an offline text recognition on this machine would cost
// and deliver, before any of it is built into the app.
//
// It is deliberately not a part of PreppSuite: it renders a PDF page the
// way PDFium would and hands the bitmap to Apple's Vision framework, which
// is what a macOS or iOS build would use. What comes out is a time and a
// text, and the text can be held against a known original.
//
//   swiftc -O tool/ocr_probe/ocr_probe.swift -o <out>/ocr_probe
//   ocr_probe <datei.pdf> [--dpi 300] [--pages 3] [--language de-DE]
//
// Prints one line of JSON per page and a summary line, so the numbers can
// be read by a script instead of by eye.

import Foundation
import ImageIO
import PDFKit
import UniformTypeIdentifiers
import Vision

struct Options {
    var path: String = ""
    var dpi: Double = 300
    var pages: Int = 3
    var language: String = "de-DE"
    var fast = false
    var correction = true
    var revision = 0
    /// Wie klein eine Zeile sein darf, als Anteil der Bildhoehe.
    ///
    /// Vision setzt hier von Haus aus 1/32. Auf einer A4-Doppelseite bei
    /// 200 dpi sind das 51 Pixel — mehr als dreimal die Hoehe einer
    /// normalen Textzeile. Die Erkennung uebergeht sie dann vollstaendig
    /// und meldet trotzdem Zuversicht 1,000. Genau so verlor ein Lauf
    /// ueber die BBK-Broschuere 50 000 von 52 000 Zeichen.
    var minimumTextHeight = 0.008
    var dumpDirectory: String?
    /// Writes the bitmap that was actually handed to the recognition.
    /// Worth having: the first thing to doubt when text goes missing is
    /// the page, and the only way to settle it is to look at it.
    var pngDirectory: String?
}

func parseArguments() -> Options {
    var options = Options()
    var rest = Array(CommandLine.arguments.dropFirst())
    while let argument = rest.first {
        rest.removeFirst()
        switch argument {
        case "--dpi": options.dpi = Double(rest.removeFirst()) ?? 300
        case "--pages": options.pages = Int(rest.removeFirst()) ?? 3
        case "--language": options.language = rest.removeFirst()
        case "--dump": options.dumpDirectory = rest.removeFirst()
        case "--png": options.pngDirectory = rest.removeFirst()
        case "--fast": options.fast = true
        case "--no-correction": options.correction = false
        case "--revision": options.revision = Int(rest.removeFirst()) ?? 0
        case "--min-height":
            options.minimumTextHeight = Double(rest.removeFirst()) ?? 0.008
        default: options.path = argument
        }
    }
    return options
}

/// Renders a page the way a PDF viewer would.
///
/// Through Core Graphics and not PDFKit, and that is the whole point.
/// The PDFKit route — size the bitmap from `bounds(for:)`, then
/// `draw(with:to:)` — silently clipped a third of every page of the BBK
/// booklet, whose pages carry a `/Rotate 90`. Nothing looked broken: the
/// text that survived was perfect, only a column was missing, and the
/// same page read whole on Android. `getDrawingTransform` is the answer
/// Core Graphics has for exactly this: it fits the page into the given
/// rectangle and takes the rotation with it.
func render(page: CGPDFPage, dpi: Double) -> CGImage? {
    let box = page.getBoxRect(.mediaBox)
    let turned = page.rotationAngle % 180 != 0
    let scale = dpi / 72.0
    let width = Int(((turned ? box.height : box.width) * scale).rounded())
    let height = Int(((turned ? box.width : box.height) * scale).rounded())
    guard width > 0, height > 0,
          let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            // sRGB and not grayscale: it costs nothing here and keeps the
            // bitmap the same shape as anything a camera or scanner hands
            // over.
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
          )
    else { return nil }

    context.setFillColor(gray: 1, alpha: 1)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    // Die Vergroesserung hier und nicht in `getDrawingTransform`: gibt
    // man dem Transform das Pixelrechteck, faellt die Seite bei 200 dpi
    // auf halbe Groesse in eine Ecke. Der Transform bekommt deshalb das
    // Rechteck in Punkten und macht nur, wofuer es ihn braucht — Drehung
    // und Ursprung.
    context.scaleBy(x: scale, y: scale)
    context.concatenate(
        page.getDrawingTransform(
            .mediaBox,
            rect: CGRect(
                x: 0,
                y: 0,
                width: turned ? box.height : box.width,
                height: turned ? box.width : box.height
            ),
            rotate: 0,
            preserveAspectRatio: true
        )
    )
    context.drawPDFPage(page)
    return context.makeImage()
}

func recognise(
    image: CGImage,
    language: String,
    fast: Bool,
    correction: Bool,
    revision: Int,
    minimumTextHeight: Double
) throws -> (text: String, confidence: Double) {
    let request = VNRecognizeTextRequest()
    if revision > 0 { request.revision = revision }
    request.recognitionLevel = fast ? .fast : .accurate
    request.recognitionLanguages = language.isEmpty ? [] : [language]
    request.automaticallyDetectsLanguage = language.isEmpty
    request.usesLanguageCorrection = correction
    request.minimumTextHeight = Float(minimumTextHeight)
    try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])

    let observations = request.results ?? []
    var lines: [String] = []
    var confidenceSum = 0.0
    var counted = 0
    for observation in observations {
        guard let best = observation.topCandidates(1).first else { continue }
        lines.append(best.string)
        confidenceSum += Double(best.confidence)
        counted += 1
    }
    return (lines.joined(separator: "\n"), counted == 0 ? 0 : confidenceSum / Double(counted))
}

let options = parseArguments()
let url = URL(fileURLWithPath: options.path)
guard !options.path.isEmpty,
      let document = PDFDocument(url: url),
      let graphics = CGPDFDocument(url as CFURL)
else {
    FileHandle.standardError.write("ocr_probe: cannot open PDF\n".data(using: .utf8)!)
    exit(1)
}

// What the PDF already carries. A page that has text needs no recognition
// at all, and the measurement has to say which case it is looking at.
var embeddedCharacters = 0
for index in 0..<document.pageCount {
    embeddedCharacters += document.page(at: index)?.string?.count ?? 0
}

var totalRender = 0.0
var totalRecognise = 0.0
var totalCharacters = 0
let pageCount = min(options.pages, document.pageCount)

for index in 0..<pageCount {
    // One pool per page, and it is not optional. Measured over 210
    // pages without it: peak memory 2.39 GB, because every page bitmap
    // and every recognition stays alive until the process ends. With
    // it the same run stays flat. On a phone the difference is between
    // a feature and a process the system kills.
    autoreleasepool {
    // Seitenzahlen: Core Graphics zaehlt ab eins.
    guard let page = graphics.page(at: index + 1) else { return }

    let renderStart = Date()
    guard let image = render(page: page, dpi: options.dpi) else { return }
    let renderSeconds = Date().timeIntervalSince(renderStart)

    let recogniseStart = Date()
    let result = (try? recognise(
        image: image,
        language: options.language,
        fast: options.fast,
        correction: options.correction,
        revision: options.revision,
        minimumTextHeight: options.minimumTextHeight
    )) ?? (text: "", confidence: 0.0)
    let recogniseSeconds = Date().timeIntervalSince(recogniseStart)

    totalRender += renderSeconds
    totalRecognise += recogniseSeconds
    totalCharacters += result.text.count

    if let directory = options.pngDirectory {
        let file = URL(fileURLWithPath: directory)
            .appendingPathComponent("page-\(index + 1).png")
        if let destination = CGImageDestinationCreateWithURL(
            file as CFURL, UTType.png.identifier as CFString, 1, nil
        ) {
            CGImageDestinationAddImage(destination, image, nil)
            CGImageDestinationFinalize(destination)
        }
    }

    if let directory = options.dumpDirectory {
        let file = URL(fileURLWithPath: directory)
            .appendingPathComponent("page-\(index + 1).txt")
        try? result.text.write(to: file, atomically: true, encoding: .utf8)
    }

    let line = """
    {"page":\(index + 1),"pixels":\(image.width)x\(image.height),\
    "render_s":\(String(format: "%.3f", renderSeconds)),\
    "ocr_s":\(String(format: "%.3f", recogniseSeconds)),\
    "characters":\(result.text.count),\
    "confidence":\(String(format: "%.3f", result.confidence))}
    """
    print(line)
    }
}

print("""
{"file":"\(URL(fileURLWithPath: options.path).lastPathComponent)",\
"pages_in_document":\(document.pageCount),"pages_measured":\(pageCount),\
"embedded_characters":\(embeddedCharacters),\
"dpi":\(Int(options.dpi)),"language":"\(options.language)",\
"render_s_total":\(String(format: "%.3f", totalRender)),\
"ocr_s_total":\(String(format: "%.3f", totalRecognise)),\
"characters_total":\(totalCharacters)}
""")
