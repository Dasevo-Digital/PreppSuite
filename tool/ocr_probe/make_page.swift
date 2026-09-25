// Typesets a text file into a PDF, so a measurement has a page whose
// exact wording is known.
//
// Needed because the only way to say how good a recognition is, is to
// hold it against an original — and an original has to be made, not
// found. The font is a parameter because it turned out to matter more
// than the resolution did.
//
//   swiftc -O tool/ocr_probe/make_page.swift -o <out>/make_page
//   make_page <text.txt> <seite.pdf> [--font Helvetica] [--size 11]

import AppKit
import CoreText
import Foundation

var input = ""
var output = ""
var fontName = "Helvetica"
var fontSize = 11.0

var rest = Array(CommandLine.arguments.dropFirst())
while let argument = rest.first {
    rest.removeFirst()
    switch argument {
    case "--font": fontName = rest.removeFirst()
    case "--size": fontSize = Double(rest.removeFirst()) ?? 11
    default:
        if input.isEmpty { input = argument } else { output = argument }
    }
}

guard !input.isEmpty, !output.isEmpty,
      let text = try? String(contentsOfFile: input, encoding: .utf8)
else {
    FileHandle.standardError.write("make_page: cannot read text\n".data(using: .utf8)!)
    exit(1)
}

let page = CGRect(x: 0, y: 0, width: 595, height: 842)  // A4 in points
let margin = 56.0
let frame = page.insetBy(dx: margin, dy: margin)

guard let font = CTFontCreateWithName(fontName as CFString, fontSize, nil) as CTFont?
else { exit(1) }

let paragraph = NSMutableParagraphStyle()
paragraph.lineSpacing = fontSize * 0.45
let attributed = NSAttributedString(
    string: text,
    attributes: [
        .font: font,
        .paragraphStyle: paragraph,
        .foregroundColor: NSColor.black,
    ]
)

var mediaBox = page
guard let context = CGContext(
    URL(fileURLWithPath: output) as CFURL, mediaBox: &mediaBox, nil
) else { exit(1) }

let framesetter = CTFramesetterCreateWithAttributedString(attributed)
var start = 0
var pages = 0
while start < attributed.length {
    context.beginPDFPage(nil)
    context.setFillColor(gray: 1, alpha: 1)
    context.fill(page)

    let path = CGPath(rect: frame, transform: nil)
    let ctFrame = CTFramesetterCreateFrame(
        framesetter, CFRangeMake(start, 0), path, nil
    )
    CTFrameDraw(ctFrame, context)
    let visible = CTFrameGetVisibleStringRange(ctFrame)
    context.endPDFPage()
    pages += 1
    if visible.length == 0 { break }
    start += visible.length
}
context.closePDF()
print("\(pages) Seiten, \(fontName) \(Int(fontSize)) pt")
