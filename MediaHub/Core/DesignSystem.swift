import SwiftUI

/// Shared design tokens for Pear.
///
/// Colours are semantic on purpose: they resolve through the trait collection, so every view
/// works in light and dark without branching on `colorScheme`. Brand art (the logo, the pear
/// animation, the accent) stays in `Brand` and `ThemeStore`.
enum DS {
    // MARK: - Colour

    enum Palette {
        /// Page background: system background (white in light, black in dark).
        static let background = SwiftUI.Color(uiColor: .systemBackground)
        /// Rows, panels and surfaces that sit on the background.
        static let surface = SwiftUI.Color(uiColor: .secondarySystemBackground)
        static let surfaceElevated = SwiftUI.Color(uiColor: .tertiarySystemBackground)
        /// Text and icons on artwork: always light, because artwork is treated as dark.
        static let onArt = SwiftUI.Color.white
        static let onArtSecondary = SwiftUI.Color.white.opacity(0.82)
        /// Scrim laid under text that sits on artwork.
        static let artScrim = SwiftUI.Color.black
        static let chipFill = SwiftUI.Color(uiColor: .tertiarySystemFill)
        static let separator = SwiftUI.Color(uiColor: .separator)
    }

    // MARK: - Spacing

    enum Space {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        /// Horizontal page margin. Every page lines up on this.
        static let page: CGFloat = 16
        /// Gap between two cards in a row or grid.
        static let cardGap: CGFloat = 12
        /// Gap between two sections of a feed.
        static let section: CGFloat = 30
    }

    // MARK: - Corner radius

    enum Radius {
        static let chip: CGFloat = 10
        /// Posters and small surfaces.
        static let card: CGFloat = 10
        /// 16:9 cards (continue watching, themes, episodes).
        static let landscape: CGFloat = 12
        /// Full-width banners and large panels.
        static let banner: CGFloat = 16
        /// Sheets and the big feature panels.
        static let sheet: CGFloat = 28
    }

    // MARK: - Type

    /// Text styles, not raw point sizes, so Dynamic Type keeps working. Sizes on a 393pt screen:
    /// largeTitle 34, title 28, title2 22, title3 20, body 17, subheadline 15, footnote 13, caption2 11.
    enum TypeStyle {
        static let pageTitle = Font.system(.largeTitle).bold()
        static let display = Font.system(.title).bold()
        static let section = Font.system(.title2).bold()
        static let rowTitle = Font.system(.title3).bold()
        static let body = Font.system(.body)
        static let bodyStrong = Font.system(.body).weight(.semibold)
        static let secondary = Font.system(.subheadline)
        static let cardTitle = Font.system(.subheadline).weight(.semibold)
        static let caption = Font.system(.footnote)
        static let micro = Font.system(.caption2).weight(.semibold)
    }

    // MARK: - Cards

    /// The whole app uses two card widths: one poster unit, and a landscape card two units wide.
    /// Nothing else is allowed in a row, which is what keeps the feed from jumping between sizes.
    enum Card {
        static let posterWidthPhone: CGFloat = 104
        static let posterWidthWide: CGFloat = 140
        static let landscapeWidthPhone: CGFloat = 208
        static let landscapeWidthWide: CGFloat = 280

        static let posterAspect: CGFloat = 2.0 / 3.0
        static let landscapeAspect: CGFloat = 16.0 / 9.0

        static let gap: CGFloat = 12
        /// Adaptive grid columns. The grid gives every card the same width, so a row is always even.
        static let gridMin: CGFloat = 104
        static let gridMax: CGFloat = 150

        static func posterWidth(wide: Bool) -> CGFloat { wide ? posterWidthWide : posterWidthPhone }
        static func landscapeWidth(wide: Bool) -> CGFloat { wide ? landscapeWidthWide : landscapeWidthPhone }

        static var gridColumns: [GridItem] {
            [GridItem(.adaptive(minimum: gridMin, maximum: gridMax), spacing: gap, alignment: .top)]
        }
    }

    // MARK: - Hero

    enum Hero {
        static let heightPhone: CGFloat = 600
        static let heightWide: CGFloat = 640
    }
}
