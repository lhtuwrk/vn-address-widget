import SwiftUI
import WidgetKit

/// Placeholder WidgetKit entry proving the extension target links the shared
/// Rust core (ADR 0002 §7: both widgets link the core from phase0/03
/// onward). Real content — reading `widget/last_result.json` (M2a) or a live
/// lookup (M2b) — is phase2/02.
struct VnaddrEntry: TimelineEntry {
    let date: Date
    let corePing: Int32?
}

struct VnaddrProvider: TimelineProvider {
    func placeholder(in context: Context) -> VnaddrEntry {
        VnaddrEntry(date: Date(), corePing: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (VnaddrEntry) -> Void) {
        completion(VnaddrEntry(date: Date(), corePing: callCore()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VnaddrEntry>) -> Void) {
        let entry = VnaddrEntry(date: Date(), corePing: callCore())
        completion(Timeline(entries: [entry], policy: .never))
    }

    /// Calls the statically-linked core directly (ADR 0002 §9) — the
    /// extension resolves these symbols at link time, unlike the Dart side's
    /// `DynamicLibrary.process()` runtime lookup.
    private func callCore() -> Int32? {
        guard vnaddr_abi_version() == 1 else { return nil }
        return vnaddr_ping()
    }
}

struct VnaddrWidgetView: View {
    var entry: VnaddrProvider.Entry

    var body: some View {
        VStack(alignment: .leading) {
            Text("VN Address Widget")
                .font(.caption)
            if let ping = entry.corePing {
                Text("core linked (ping=\(ping))")
                    .font(.caption2)
            } else {
                Text("core not linked")
                    .font(.caption2)
            }
        }
        .padding()
    }
}

struct VnaddrWidget: Widget {
    let kind: String = "VnaddrWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VnaddrProvider()) { entry in
            // ADR 0002 §6: iOS 16 floor. Interactive elements (tap-to-copy)
            // require iOS 17+ and are a distinct layout, not built here yet
            // (see the ADR's "Open questions — widget/screen UX").
            VnaddrWidgetView(entry: entry)
        }
        .configurationDisplayName("VN Address")
        .description("Shows your current administrative address.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
