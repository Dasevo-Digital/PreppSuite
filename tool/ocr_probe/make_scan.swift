// Turns a PDF that carries text into one that only carries pictures of
// it — what a scanner would have produced.
//
// Needed because measuring recognition on a PDF that already has a text
// layer measures nothing: it is far cleaner than any scan, and the page
// the app would actually be handed is a photograph of paper.
//
//   swiftc -O tool/ocr_probe/make_scan.swift -o <out>/make_scan
//   make_scan <text.pdf> <scan.pdf> [--dpi 200] [--quality 0.6]

import AppKit
import Foundation
import PDFKit
import UniformTypeIdentifiers

var input = ""
var output = ""
var dpi = 200.0
var quality = 0.6

var rest = Array(CommandLine.arguments.dropFirst())
while let argument = rest.first {
    rest.removeFirst()
    switch argument {
    case "--dpi": dpi = Double(rest.removeFirst()) ?? 200
    case "--quality": quality = Double(rest.removeFirst()) ?? 0.6
    default:
        if input.isEmpty { input = argument } else { output = argument }
    }
}

let inputURL = URL(fileURLWithPath: input)
guard !input.isEmpty, !output.isEmpty,
      let document = PDFDocument(url: inputURL),
      let graphics = CGPDFDocument(inputURL as CFURL)
else {
    FileHandle.standardError.write("make_scan: cannot open PDF\n".data(using: .utf8)!)
    exit(1)
}

let scanned = PDFDocument()
for index in 0..<document.pageCount {
    // Ueber Core Graphics und nicht ueber PDFKit, aus demselben Grund
    // wie im ocr_probe: der PDFKit-Weg schneidet eine gedrehte Seite an,
    // ohne dass es auffiele.
    guard let page = graphics.page(at: index + 1) else { continue }
    let box = page.getBoxRect(.mediaBox)
    let turned = page.rotationAngle % 180 != 0
    let scale = dpi / 72.0
    let pointsWide = turned ? box.height : box.width
    let pointsHigh = turned ? box.width : box.height
    let width = Int((pointsWide * scale).rounded())
    let height = Int((pointsHigh * scale).rounded())
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceGray(),
        bitmapInfo: CGImageAlphaInfo.none.rawValue
    ) else { continue }

    context.setFillColor(gray: 1, alpha: 1)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    context.scaleBy(x: scale, y: scale)
    context.concatenate(
        page.getDrawingTransform(
            .mediaBox,
            rect: CGRect(x: 0, y: 0, width: pointsWide, height: pointsHigh),
            rotate: 0,
            preserveAspectRatio: true
        )
    )
    context.drawPDFPage(page)
    guard let rendered = context.makeImage() else { continue }

    // Through JPEG on purpose: a scanner's own compression is part of
    // what a recognition has to cope with.
    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(
        data, UTType.jpeg.identifier as CFString, 1, nil
    ) else { continue }
    CGImageDestinationAddImage(
        destination,
        rendered,
        [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary
    )
    guard CGImageDestinationFinalize(destination),
          let image = NSImage(data: data as Data),
          let imagePage = PDFPage(image: image)
    else { continue }
    scanned.insert(imagePage, at: scanned.pageCount)
}

guard scanned.write(to: URL(fileURLWithPath: output)) else {
    FileHandle.standardError.write("make_scan: cannot write PDF\n".data(using: .utf8)!)
    exit(1)
}
print("\(scanned.pageCount) Seiten, \(Int(dpi)) dpi, JPEG \(quality)")
