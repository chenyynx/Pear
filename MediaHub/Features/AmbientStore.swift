import SwiftUI

/// One page-colour candidate: a row's artwork, its average colour and a small copy of the art
/// for the blurred wash.
struct Ambient {
    /// The row that owns the colour (hero, continue, theme, catalogue…).
    let id: String
    /// The artwork identity. When it changes, the wash crossfades even if the row is the same.
    let key: String
    let color: Color
    let image: UIImage?
}

/// Decides which row supplies the page colour.
///
/// Every feed row reports its top position; the row whose top is the last one to pass the
/// focal line wins. That makes the whole page change colour as the feed scrolls, not just
/// when the hero changes.
@MainActor @Observable
final class AmbientStore {
    static let shared = AmbientStore()

    private(set) var current: Ambient?
    private var ambients: [String: Ambient] = [:]
    private var tops: [String: CGFloat] = [:]

    /// Global y of the line that decides which row owns the page colour: a little below the top,
    /// where the eye lands while scrolling.
    private let focal: CGFloat = 240

    /// Called by a row once its representative artwork has a colour.
    func register(id: String, key: String, color: Color?, image: UIImage?) {
        guard let color else { return }
        let ambient = Ambient(id: id, key: key, color: color, image: image)
        ambients[id] = ambient
        // The hero updates its artwork without its frame moving: refresh the wash in place.
        if current?.id == id {
            if current?.key != key {
                withAnimation(.easeInOut(duration: 0.9)) { current = ambient }
            }
        } else {
            resolve()
        }
    }

    /// Called by every row as it moves. Rounded by the caller, so scrolling doesn't re-render per pixel.
    func updateTop(id: String, minY: CGFloat) {
        tops[id] = minY
        resolve()
    }

    private func resolve() {
        // Only rows that already have a colour can own the wash; anything still loading is skipped
        // instead of freezing the page on the previous row.
        let ready = tops.filter { ambients[$0.key] != nil }
        guard !ready.isEmpty else { return }
        // Last row whose top has passed the focal line; before any has, the first row.
        let passed = ready.filter { $0.value <= focal }.max { $0.value < $1.value }
        let chosen = passed?.key ?? ready.min { $0.value < $1.value }?.key
        guard let chosen, let ambient = ambients[chosen] else { return }
        if current?.key != ambient.key {
            withAnimation(.easeInOut(duration: 0.8)) { current = ambient }
        }
    }
}

/// Reports a row's position and, when it has artwork, loads that artwork's average colour and a
/// small copy of the image for the blurred wash.
private struct AmbientSource: ViewModifier {
    let id: String
    let url: URL?

    func body(content: Content) -> some View {
        content
            // Global coordinates: the focal line is a fixed place on the screen. Rounded to
            // 8pt steps so a scroll doesn't touch the store on every frame.
            .onGeometryChange(for: CGFloat.self) { proxy in
                (proxy.frame(in: .global).minY / 8).rounded() * 8
            } action: { minY in
                AmbientStore.shared.updateTop(id: id, minY: minY)
            }
            .task(id: url) {
                guard let url else { return }
                let color = await ImagePipeline.shared.averageColor(for: url)
                // Small on purpose: it is blurred into a colour field, never shown as a picture.
                let image = await ImagePipeline.shared.image(for: url, maxPixel: 360)
                guard !Task.isCancelled, let color else { return }
                AmbientStore.shared.register(id: id, key: url.absoluteString,
                                             color: Color(uiColor: color), image: image)
            }
    }
}

extension View {
    /// Marks a feed row as a source of the page colour.
    func ambientSource(id: String, url: URL?) -> some View {
        modifier(AmbientSource(id: id, url: url))
    }

    /// Reports a row's position without loading artwork (the hero loads its own).
    func ambientTop(id: String) -> some View {
        onGeometryChange(for: CGFloat.self) { proxy in
            (proxy.frame(in: .global).minY / 8).rounded() * 8
        } action: { minY in
            AmbientStore.shared.updateTop(id: id, minY: minY)
        }
    }
}

/// Full-screen wash driven by `AmbientStore`.
struct AmbientBackdrop: View {
    @State private var store = AmbientStore.shared

    var body: some View {
        HeroBackdrop(image: store.current?.image,
                     key: store.current?.key ?? "",
                     tint: store.current?.color)
    }
}
