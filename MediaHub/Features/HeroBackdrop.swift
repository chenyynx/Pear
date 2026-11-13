import SwiftUI

/// Full-page wash taken from the current hero artwork.
///
/// The cached hero image is blurred and veiled with the page colour, so the whole feed sits on a
/// colour that belongs to what you are looking at. It is fixed behind the scroll view: scrolling
/// reveals other parts of the wash, and a new hero crossfades into a new colour.
struct HeroBackdrop: View {
    let image: UIImage?
    /// Identity of the shown artwork; changing it crossfades the layer.
    let key: String
    let tint: Color?
    /// Scroll position of the feed, clamped by the caller. Drifts the wash a little as you move.
    var scroll: CGFloat = 0
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            DS.Palette.background
            GeometryReader { geo in
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        // Overscan and blur hide the image's own edges; the result is a colour field,
                        // not a picture, so it can sit under text without competing with it.
                        .scaleEffect(1.4)
                        .offset(y: -min(scroll, 1200) * 0.12)
                        .clipped()
                        .blur(radius: 60)
                        // Veil: stronger in light mode, where a raw wash would fight black text.
                        .overlay { DS.Palette.background.opacity(scheme == .dark ? 0.5 : 0.62) }
                        .overlay { (tint ?? .clear).opacity(scheme == .dark ? 0.28 : 0.16) }
                        .transition(.opacity)
                        .id(key)
                }
            }
        }
        .animation(.easeInOut(duration: 0.9), value: key)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
