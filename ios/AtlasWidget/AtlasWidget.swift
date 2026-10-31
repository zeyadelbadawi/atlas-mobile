import SwiftUI
import WidgetKit

/// What the app last wrote for the widget (lib/app/home_widgets.dart),
/// already in its language. A plain value: the widget only lays it out.
struct ContinueEntry: TimelineEntry {
  let date: Date
  let signedIn: Bool
  let rtl: Bool
  let label: String
  let academy: String
  let course: String
  let lesson: String
  let percent: Int
  let percentText: String
  let due: String
  let empty: String
  let path: String

  var hasCourse: Bool { signedIn && !course.isEmpty }

  /// The App Group the app writes into (`PlatformHomeWidgets.appGroup`).
  static let appGroup = "group.com.atlas.atlasMobile"

  static func read(at date: Date = .now) -> ContinueEntry {
    let d = UserDefaults(suiteName: appGroup)
    func text(_ key: String, _ fallback: String = "") -> String {
      d?.string(forKey: key) ?? fallback
    }
    return ContinueEntry(
      date: date,
      signedIn: d?.bool(forKey: "signedIn") ?? false,
      rtl: d?.bool(forKey: "rtl") ?? true,
      label: text("label", "متابعة التعلّم"),
      academy: text("academy", "Atlas"),
      course: text("course"),
      lesson: text("lesson"),
      percent: min(max(d?.integer(forKey: "percent") ?? 0, 0), 100),
      percentText: text("percentText"),
      due: text("due"),
      empty: text("empty", "سجّل الدخول إلى أطلس لترى كورساتك هنا."),
      path: text("path", "/home")
    )
  }

  /// The widget gallery's sample.
  static let preview = ContinueEntry(
    date: .now, signedIn: true, rtl: true, label: "متابعة التعلّم",
    academy: "Atlas", course: "التفاضل والتكامل",
    lesson: "التالي: النهايات من جهة واحدة", percent: 29, percentText: "تم ٢٩٪",
    due: "التسليم الثلاثاء ٨:٠٠ م: واجب الاتصال", empty: "", path: "/home")
}

/// The app refreshes the widget whenever something changes
/// (`HomeWidget.updateWidget`), so the timeline never asks again on its own.
struct ContinueProvider: TimelineProvider {
  func placeholder(in context: Context) -> ContinueEntry { .preview }

  func getSnapshot(in context: Context, completion: @escaping (ContinueEntry) -> Void) {
    completion(context.isPreview ? .preview : .read())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<ContinueEntry>) -> Void) {
    completion(Timeline(entries: [.read()], policy: .never))
  }
}

/// Atlas's tokens (lib/design/tokens), light and dark.
private enum Palette {
  static let accent = Color(light: 0x1B398D, dark: 0x709DFF)
  static let gold = Color(light: 0x8A5A00, dark: 0xF0BF4C)
  static let progress = Color(light: 0xE0A424, dark: 0xE0A424)
  static let track = Color(light: 0xE8EDFA, dark: 0x1C2A4F)
  static let ink = Color(light: 0x141A29, dark: 0xECEEF3)
  static let inkSecondary = Color(light: 0x5C657A, dark: 0x9CA3B4)
  static let surface = Color(light: 0xFFFFFF, dark: 0x161B27)
}

private extension Color {
  init(light: UInt32, dark: UInt32) {
    self.init(uiColor: UIColor { traits in
      let hex = traits.userInterfaceStyle == .dark ? dark : light
      return UIColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: 1)
    })
  }
}

struct ContinueView: View {
  let entry: ContinueEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(entry.label)
          .font(.caption.weight(.bold))
          .foregroundStyle(Palette.accent)
          .lineLimit(1)
        Spacer(minLength: 8)
        if family != .systemSmall {
          Text(entry.academy)
            .font(.caption)
            .foregroundStyle(Palette.inkSecondary)
            .lineLimit(1)
        }
      }
      if entry.hasCourse {
        Text(entry.course)
          .font(.headline)
          .foregroundStyle(Palette.ink)
          .lineLimit(2)
        if !entry.lesson.isEmpty {
          Text(entry.lesson)
            .font(.footnote)
            .foregroundStyle(Palette.inkSecondary)
            .lineLimit(family == .systemSmall ? 2 : 1)
        }
        Spacer(minLength: 4)
        HStack(spacing: 8) {
          ProgressView(value: Double(entry.percent), total: 100)
            .tint(Palette.progress)
            .background(Palette.track, in: Capsule())
          Text(entry.percentText)
            .font(.caption2)
            .foregroundStyle(Palette.inkSecondary)
            .lineLimit(1)
        }
        if family != .systemSmall, !entry.due.isEmpty {
          Text(entry.due)
            .font(.caption)
            .foregroundStyle(Palette.gold)
            .lineLimit(1)
            .padding(.top, 2)
        }
      } else {
        Spacer(minLength: 4)
        Text(entry.empty)
          .font(.subheadline)
          .foregroundStyle(Palette.inkSecondary)
        Spacer(minLength: 0)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    // The app's language, not the phone's, decides the direction.
    .environment(\.layoutDirection, entry.rtl ? .rightToLeft : .leftToRight)
    .containerBackground(Palette.surface, for: .widget)
    .widgetURL(Self.url(for: entry.path))
  }

  /// `atlaswidget://open?homeWidget&path=…`, which home_widget hands to
  /// the app (lib/app/home_widgets.dart reads `path`).
  static func url(for path: String) -> URL? {
    var c = URLComponents()
    c.scheme = "atlaswidget"
    c.host = "open"
    // home_widget only takes links that carry `homeWidget`.
    c.queryItems = [
      URLQueryItem(name: "homeWidget", value: nil),
      URLQueryItem(name: "path", value: path),
    ]
    return c.url
  }
}

struct AtlasContinueWidget: Widget {
  let kind = "AtlasContinueWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: ContinueProvider()) { entry in
      ContinueView(entry: entry)
    }
    .configurationDisplayName("متابعة التعلّم")
    .description("الكورس الجاري، ودرسك التالي، وأقرب موعد تسليم.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

@main
struct AtlasWidgetBundle: WidgetBundle {
  var body: some Widget {
    AtlasContinueWidget()
  }
}
