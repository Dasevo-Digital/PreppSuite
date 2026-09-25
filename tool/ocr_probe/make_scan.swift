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

guard !input.isEmpty, !output.isEmpty,
      let document = PDFDocument(url: URL(fileURLWithPath: input))
else {
    FileHandle.standardError.write("make_scan: cannot open PDF\n".data(using: .utf8)!)
    exit(1)
}

let scanned = PDFDocument()
for index in 0..<document.pageCount {
    guard let page = document.page(at: index) else { continue }
    // A page may carry a /Rotate of its own — the BBK booklet that this
    // was first measured on carries 90 on every page. `bounds` reports
    // the box before that rotation, so a bitmap sized from it is
    // portrait while the content is landscape, and a third of every
    // line falls off the right-hand edge. Nothing about it looks
    // broken: the text that *is* recognised is perfect.
    let box = page.bounds(for: .mediaBox)
    let turned = page.rotation % 180 != 0
    let scale = dpi / 72.0
    let width = Int(((turned ? box.height : box.width) * scale).rounded())
    let height = Int(((turned ? box.width : box.height) * scale).rounded())
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
    // Lets PDFKit set up the rotation and the origin itself.
    page.transform(context, for: .mediaBox)
    page.draw(with: .mediaBox, to: context)
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
