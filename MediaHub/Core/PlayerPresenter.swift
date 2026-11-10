import Foundation
import Observation

/// Owns which playback is on screen and whether it is minimised into Picture in Picture.
///
/// The player used to be a `fullScreenCover` owned by Detail / Downloads, which tied the engine's
/// lifetime to that cover: dismissing the player always shut the engine down, so the PiP window
/// had to stay on top of a placeholder page. The presenter lifts that decision to the app root:
/// the `PlayerScreen` stays mounted (hidden) while PiP is open, so the rest of the app can be used
/// and the PiP window keeps playing. A full close (no PiP) still removes the screen and its engine.
@MainActor @Observable
final class PlayerPresenter {
    /// The playback that should be presented. nil = no player at all; non-nil + minimized = PiP.
    private(set) var request: PlayRequest?
    /// Episode browser handed to the player (shows only; the player owns its lifetime).
    private(set) var provider: EpisodeProvider?
    /// PiP is running and the full-screen player is hidden so the rest of the app is usable.
    private(set) var minimized = false

    func play(_ request: PlayRequest, provider: EpisodeProvider?) {
        self.request = request
        self.provider = provider
        minimized = false
    }

    /// Hide the player screen but keep the engine and the PiP window alive.
    func minimize() {
        guard request != nil else { return }
        minimized = true
    }

    /// Bring the full-screen player back (PiP's restore button, or a future "now playing" bar).
    func restore() {
        minimized = false
    }

    /// Tear the playback down: the root removes `PlayerScreen`, which shuts the engine down.
    func close() {
        request = nil
        provider = nil
        minimized = false
    }
}
