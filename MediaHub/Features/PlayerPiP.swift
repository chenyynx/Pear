import SwiftUI
import AVKit
import AetherEngine

/// Picture in Picture for the player.
///
/// AetherEngine renders into an `AVPlayerLayer` it owns and hosts inside `AetherPlayerSurface`. `nativePlayerLayer`
/// hands back that same layer, so PiP wraps what is already on screen instead of mounting a second one.
/// It is nil whenever the session is not on the native AVPlayer path (AV1 without hardware decode, VP9, ...), which is
/// also the signal to hide the button: those sessions render into a sample-buffer layer that needs a different PiP source.
///
/// Lifetime: the player screen owns the engine, so it has to stay presented while the window is open. The video moves
/// into the PiP window and the screen shows a placeholder; the restore button in the window simply brings the app back.
@MainActor @Observable
final class PiPController: NSObject {
    /// Settings -> Playback -> Picture in Picture. Off means the feature does not exist: no controller is ever created
    /// (so no button, no automatic window when leaving the app) and an open window is closed.
    static let enabledKey = "player.pip"
    static var isEnabled: Bool { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }

    /// iOS says a PiP window can be opened for the current video. Drives whether the pill shows the button.
    private(set) var isAvailable = false
    /// The PiP window is open (or opening).
    private(set) var isActive = false
    /// The system refused to open the window.
    @ObservationIgnored var onFailure: (() -> Void)?
    /// The window opened. The player minimises itself, so the app is usable straight away.
    @ObservationIgnored var onStarted: (() -> Void)?
    /// The window's restore button was tapped: bring the full-screen player back before PiP stops.
    @ObservationIgnored var onRestoreUI: (() -> Void)?
    /// The window closed (X, or the system ended it). The player uses this to shut a hidden session down.
    @ObservationIgnored var onStopped: (() -> Void)?

    @ObservationIgnored private var controller: AVPictureInPictureController?
    /// The window is stopping because the user asked to return to the app, not because it was closed.
    @ObservationIgnored private var restoring = false
    @ObservationIgnored private var possibleObservation: NSKeyValueObservation?
    @ObservationIgnored private weak var layer: AVPlayerLayer?
    @ObservationIgnored private weak var engine: AetherEngine?

    /// Call whenever the engine may have a different layer: after (re)loads, once playback starts, episode switches.
    /// Cheap and idempotent. An open window is never rebuilt: the engine hands the item over in place.
    func refresh(engine: AetherEngine?) {
        self.engine = engine
        guard Self.isEnabled else { teardown(); return }
        guard !isActive else { return }
        guard AVPictureInPictureController.isPictureInPictureSupported(),
              let engine, let layer = engine.nativePlayerLayer else {
            teardown()
            return
        }
        if layer === self.layer, controller != nil { return }

        teardown()
        let c = AVPictureInPictureController(contentSource: .init(playerLayer: layer))
        c.delegate = self
        // Leaving the app while a video plays opens the window by itself, the way system players behave.
        c.canStartPictureInPictureAutomaticallyFromInline = true
        possibleObservation = c.observe(\.isPictureInPicturePossible, options: [.initial, .new]) { [weak self] _, change in
            let possible = change.newValue ?? false
            Task { @MainActor in self?.isAvailable = possible }
        }
        controller = c
        self.layer = layer
    }

    func toggle() {
        guard let controller else { return }
        if controller.isPictureInPictureActive { controller.stopPictureInPicture() }
        else { controller.startPictureInPicture() }
    }

    /// Closes the window and drops the controller. The player screen calls this when it goes away.
    func teardown() {
        possibleObservation = nil
        restoring = false
        if let controller {
            controller.delegate = nil
            if controller.isPictureInPictureActive { controller.stopPictureInPicture() }
        }
        controller = nil
        layer = nil
        isAvailable = false
        setActive(false)
    }

    private func setActive(_ on: Bool) {
        isActive = on
        // The engine keeps its pipeline alive while the window is open and hands items over in place on a next-episode load.
        engine?.pictureInPictureActive = on
        // Hand the active subtitle to AVKit inside the PiP window and take it back (to the
        // host overlay) when the video returns. A no-op for a track added after load.
        engine?.setNativeSubtitleRendering(on)
    }
}

extension PiPController: AVPictureInPictureControllerDelegate {
    // AVKit calls these on the main thread; handled synchronously so the engine flag is set before the app finishes backgrounding.
    nonisolated func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        MainActor.assumeIsolated { setActive(true) }
    }

    nonisolated func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        MainActor.assumeIsolated { onStarted?() }
    }

    nonisolated func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        MainActor.assumeIsolated {
            setActive(false)
            let wasRestoring = restoring
            restoring = false
            if !wasRestoring { onStopped?() }
        }
    }

    /// The user tapped the window's restore button. Present the player BEFORE letting PiP stop, so the
    /// video has a visible surface to land on. The completion handler must be called exactly once.
    nonisolated func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                                                restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        MainActor.assumeIsolated {
            restoring = true
            onRestoreUI?()
            completionHandler(true)
        }
    }

    nonisolated func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController,
                                                failedToStartPictureInPictureWithError error: Error) {
        MainActor.assumeIsolated {
            setActive(false)
            onFailure?()
        }
    }
}
