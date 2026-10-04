import SwiftUI
import WidgetKit

/// The overview's two lamps on the home screen (#105).
///
/// Draws what the app last published through home_widget into the shared
/// App Group: texts that are already translated, and two states that only
/// pick a colour. Nothing is computed here -- the lamps come from the same
/// Dart code as the overview, so the home screen cannot disagree with the
/// app. The Android twin is PreppSuiteWidgetProvider.kt.
private let appGroup = "group.de.dasevo.preppsuite"

struct LampsEntry: TimelineEntry {
  let date: Date
  let supplyState: String?
  let supplyText: String?
  let situationState: String?
  let situationText: String?
  let updatedText: String?
}

struct LampsProvider: TimelineProvider {
  func placeholder(in context: Context) -> LampsEntry { read() }

  func getSnapshot(in context: Context, completion: @escaping (LampsEntry) -> Void) {
    completion(read())
  }

  /// One entry and no schedule: the app asks for a reload whenever it
  /// publishes, and waking on a timer would only redraw the same data.
  func getTimeline(in context: Context, completion: @escaping (Timeline<LampsEntry>) -> Void) {
    completion(Timeline(entries: [read()], policy: .never))
  }

  private func read() -> LampsEntry {
    let data = UserDefaults(suiteName: appGroup)
    return LampsEntry(
      date: Date(),
      supplyState: data?.string(forKey: "supplyState"),
      supplyText: data?.string(forKey: "supplyText"),
      situationState: data?.string(forKey: "situationState"),
      situationText: data?.string(forKey: "situationText"),
      updatedText: data?.string(forKey: "updatedText"))
  }
}

struct LampsView: View {
  let entry: LampsEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      if let supply = entry.supplyText {
        lamp(colour: supplyColour(entry.supplyState), text: supply)
        lamp(colour: situationColour(entry.situationState), text: entry.situationText ?? "")
        Text(entry.updatedText ?? "")
          .font(.caption2)
          .foregroundColor(.secondary)
      } else {
        // Before the app has run once there is nothing to show, and a grey
        // lamp would look like an answer.
        Text(NSLocalizedString(
          "widget_open_app", value: "Open PreppSuite once to fill this in.", comment: ""))
          .font(.footnote)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .widgetBackgroundCompat()
  }

  private func lamp(colour: Color, text: String) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
      Circle().fill(colour).frame(width: 12, height: 12)
      Text(text).font(.footnote).lineLimit(2)
    }
  }

  /// The overview's lamp colours: the app's green and its amber.
  private func supplyColour(_ state: String?) -> Color {
    switch state {
    case "covered": return Color(red: 0x2E / 255, green: 0x7D / 255, blue: 0x32 / 255)
    case "short": return Color(red: 0xE0 / 255, green: 0xA9 / 255, blue: 0x00 / 255)
    default: return .gray
    }
  }

  /// A saturated scale, as on Android: the app's pale banner tones would
  /// disappear as a dot on a wallpaper. The text names the level.
  private func situationColour(_ state: String?) -> Color {
    switch state {
    case "extreme": return Color(red: 0xB7 / 255, green: 0x1C / 255, blue: 0x1C / 255)
    case "severe": return Color(red: 0xE6 / 255, green: 0x51 / 255, blue: 0x00 / 255)
    case "moderate": return Color(red: 0xF9 / 255, green: 0xA8 / 255, blue: 0x25 / 255)
    case "minor": return Color(red: 0xFD / 255, green: 0xD8 / 255, blue: 0x35 / 255)
    default: return .gray
    }
  }
}

private extension View {
  /// iOS 17 asks every widget for a container background; earlier systems
  /// draw the default one and only need the padding.
  @ViewBuilder
  func widgetBackgroundCompat() -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(.fill.tertiary, for: .widget)
    } else {
      padding()
    }
  }
}

@main
struct PreppSuiteWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "PreppSuiteWidget", provider: LampsProvider()) { entry in
      LampsView(entry: entry)
    }
    .configurationDisplayName("PreppSuite")
    .description(NSLocalizedString(
      "widget_description", value: "Supplies and situation at a glance", comment: ""))
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
