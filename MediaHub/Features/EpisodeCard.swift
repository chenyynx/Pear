import SwiftUI

/// Episode card in the same landscape unit as Continue Watching: a 16:9 still with badges,
/// then the episode number, title, a two-line synopsis and the runtime on the page background.
/// The tint is the still's average colour (cached by ImagePipeline), so each card gets its own mood.
struct EpisodeCard<Actions: View>: View {
    let ep: EpisodeItem
    let selected: Bool
    let watched: Bool
    var upNext = false
    /// Download state for this episode (nil = not downloaded): drives the badge.
    var download: DownloadRecord? = nil
    let onTap: () -> Void
    @ViewBuilder let actions: () -> Actions
    @Environment(ThemeStore.self) private var theme
    @Environment(\.wideLayout) private var wide
    @State private var tint: Color?

    /// The loading placeholder in the carousel reserves the phone row; the real card follows `wide`.
    static var placeholderWidth: CGFloat { DS.Card.landscapeWidthPhone }
    static var placeholderHeight: CGFloat { DS.Card.landscapeWidthPhone * 9 / 16 + 96 }

    private var width: CGFloat { DS.Card.landscapeWidth(wide: wide) }

    /// Not aired yet: the artwork is greyed out and the card says when it comes out.
    private var upcoming: Bool { ep.isUpcoming }

    private var runtime: String? {
        guard let m = ep.runtime, m > 0 else { return nil }
        return m >= 60 ? (m % 60 == 0 ? "\(m / 60)h" : "\(m / 60)h \(m % 60)m") : "\(m)m"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            art
            text
        }
        .frame(width: width, alignment: .leading)
        .contextMenu { actions() }
        .animation(.easeOut(duration: 0.3), value: tint == nil)
        .task(id: ep.image) {
            tint = nil
            guard let u = ep.image, let c = await ImagePipeline.shared.averageColor(for: u), !Task.isCancelled else { return }
            tint = Color(uiColor: c)
        }
    }

    private var art: some View {
        Color.clear
            .aspectRatio(DS.Card.landscapeAspect, contentMode: .fit)
            .frame(width: width)
            .overlay { StillImage(url: ep.image, size: width) }
            // The still's own colour washes the bottom, so the card still carries the episode's mood.
            .overlay { if let tint { tint.opacity(0.16).transition(.opacity) } }
            .overlay {
                LinearGradient(stops: [.init(color: .clear, location: 0.55),
                                       .init(color: .black.opacity(0.5), location: 1)],
                               startPoint: .top, endPoint: .bottom)
            }
            .saturation(upcoming ? 0.1 : 1)
            .opacity(upcoming ? 0.65 : 1)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    if watched { badge("checkmark.circle.fill", "Watched") }
                    else if upNext { badge(nil, "UP NEXT", fill: theme.accent, text: theme.onAccent) }
                    if let download { downloadBadge(download, below: watched || upNext) }
                }
            }
            .overlay(alignment: .topTrailing) {
                if let r = ep.rating, r > 0 { ratingBadge(r) }
            }
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.landscape, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.landscape, style: .continuous)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            }
            // Deliberately faint: the card is already busy with artwork and text, so the selection should whisper.
            .selectionRing(selected, radius: DS.Radius.landscape, width: 1, intensity: 0.35)
            // Whole card opens the sources sheet; the "..." sits on top so it takes its own taps.
            .overlay { Button(action: onTap) { Color.clear.contentShape(Rectangle()) }.buttonStyle(PressableStyle()) }
            .overlay(alignment: .bottomTrailing) {
                Menu { actions() } label: {
                    Image(systemName: "ellipsis").font(.system(size: 15, weight: .bold)).foregroundStyle(.white.opacity(0.85))
                        .frame(width: 44, height: 40).contentShape(Rectangle())
                }
                .padding(.trailing, 4).padding(.bottom, 2)
            }
            .contentShape(RoundedRectangle(cornerRadius: DS.Radius.landscape, style: .continuous))
    }

    private var text: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text("EPISODE \(ep.id)").font(.system(size: 11, weight: .semibold)).tracking(0.8)
                    .foregroundStyle(.secondary)
                if ep.isTopRated {
                    ShimmerText(text: String(localized: "TOP RATED"), symbol: "star.fill",
                                color: Color(red: 0.92, green: 0.62, blue: 0.05), size: 11, tracking: 0.3)
                }
                Spacer(minLength: 0)
            }
            .lineLimit(1)
            Text(ep.name).font(DS.TypeStyle.cardTitle).lineLimit(1)
                .opacity(upcoming ? 0.7 : 1)
            if let o = ep.overview, !o.isEmpty {
                Text(o).font(DS.TypeStyle.caption).foregroundStyle(.secondary).lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            Group {
                if let airs = ep.airsOn {
                    Label("Airs on \(airs)", systemImage: "calendar")
                        .font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                } else {
                    // New episodes announce themselves in words until you've watched them, like "Airs on" does.
                    let fresh = watched ? nil : ep.freshness
                    HStack(spacing: 6) {
                        if let f = fresh {
                            ShimmerText(text: f.text, symbol: "sparkles",
                                        color: Color(red: 0.92, green: 0.32, blue: 0.28), size: 12, weight: .medium, tracking: 0)
                            if runtime != nil { Text("·").foregroundStyle(.tertiary) }
                        }
                        Text(runtime ?? (fresh == nil ? " " : "")).font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .lineLimit(1)
                }
            }
            .padding(.top, 2)
        }
        .frame(width: width, alignment: .leading)
        .allowsHitTesting(false)
    }

    /// Episode ratings come from TMDB, so the badge carries the TMDB mark.
    private func ratingBadge(_ r: Double) -> some View {
        HStack(spacing: 5) {
            RatingLogo(label: "TMDB", height: 11)
            Text(String(format: "%.1f", r)).monospacedDigit()
        }
        .font(.caption2.bold()).foregroundStyle(.white)
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(.black.opacity(0.55), in: Capsule())
        .padding(10)
        .allowsHitTesting(false)
    }

    /// Saved / saving state. Solid accent once the file is on the device.
    private func downloadBadge(_ d: DownloadRecord, below: Bool) -> some View {
        let symbol: String, label: String
        switch d.state {
        case .done: symbol = "arrow.down.circle.fill"; label = String(localized: "Downloaded")
        case .downloading: symbol = "arrow.down.circle"; label = "\(Int(d.progress * 100))%"
        case .paused: symbol = "pause.circle"; label = String(localized: "Paused")
        case .queued: symbol = "clock"; label = String(localized: "Queued")
        case .failed: symbol = "exclamationmark.triangle.fill"; label = String(localized: "Failed")
        }
        let done = d.state == .done
        return HStack(spacing: 4) { Image(systemName: symbol); Text(label).monospacedDigit() }
            .font(.caption2.bold()).foregroundStyle(done ? theme.onAccent : .white)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(done ? theme.accent : Color.black.opacity(0.55), in: Capsule())
            .padding(.leading, 10).padding(.top, below ? 0 : 10)
            .allowsHitTesting(false)
    }

    private func badge(_ symbol: String?, _ label: String, fill: Color = .black.opacity(0.55), text: Color = .white) -> some View {
        HStack(spacing: 4) {
            if let symbol { Image(systemName: symbol) }
            Text(label)
        }
        .font(.caption2.bold()).foregroundStyle(text)
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(fill, in: Capsule())
        .padding(10)
        .allowsHitTesting(false)
    }
}

/// A short label whose colour carries a soft highlight that sweeps across it now and then. One long linear animation
/// handed to Core Animation (no timeline, no per-frame SwiftUI work), and it holds still under Reduce Motion, in Low
/// Power Mode or when hot, on a page that isn't showing, and while the app is in the background.
private struct ShimmerText: View {
    let text: String
    var symbol: String? = nil
    let color: Color
    var size: CGFloat = 12
    var weight: Font.Weight = .bold
    var tracking: CGFloat = 0.8
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.pageActive) private var pageActive
    @Environment(\.scenePhase) private var scenePhase
    @State private var sweep = false

    private var animating: Bool {
        !reduceMotion && !PowerMode.shared.saving && pageActive && scenePhase == .active && !LayoutState.shared.pagesCovered
    }

    private var label: some View {
        HStack(spacing: 4) {
            if let symbol { Image(systemName: symbol) }
            Text(text)
        }
        .font(.system(size: size, weight: weight)).tracking(tracking)
    }

    var body: some View {
        label
            .foregroundStyle(color)
            .overlay {
                if animating {
                    GeometryReader { g in
                        LinearGradient(colors: [.clear, .white.opacity(0.95), .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(width: g.size.width * 0.5)
                            // Travels well past the label, so most of each cycle is a calm pause between sweeps.
                            .offset(x: sweep ? g.size.width * 2.5 : -g.size.width * 0.5)
                    }
                    .mask { label }
                    .allowsHitTesting(false)
                }
            }
            .task(id: animating) {
                var t = Transaction(); t.disablesAnimations = true
                withTransaction(t) { sweep = false }
                guard animating else { return }
                try? await Task.sleep(for: .milliseconds(60))
                guard !Task.isCancelled else { return }
                withAnimation(.linear(duration: 3.4).repeatForever(autoreverses: false)) { sweep = true }
            }
            .accessibilityLabel(text.capitalized)
    }
}
