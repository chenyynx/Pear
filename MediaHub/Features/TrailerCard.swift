import SwiftUI
import SafariServices

/// Trailer card in the same landscape unit as episodes and Continue Watching: a 16:9 thumbnail
/// with a play button, then the kind ("TRAILER") and the title on the page background.
struct TrailerCard: View {
    let video: TMDBClient.Video
    let onTap: () -> Void
    @Environment(\.wideLayout) private var wide
    @State private var tint: Color?

    private var width: CGFloat { DS.Card.landscapeWidth(wide: wide) }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Color.clear
                    .aspectRatio(DS.Card.landscapeAspect, contentMode: .fit)
                    .frame(width: width)
                    .overlay { RemoteImage(url: video.thumbnail, size: width) }
                    // The thumbnail's own colour washes the card, one cached request per trailer.
                    .overlay { if let tint { tint.opacity(0.2).transition(.opacity) } }
                    .overlay {
                        Image(systemName: "play.fill").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                            .frame(width: 44, height: 44).background(.black.opacity(0.38), in: Circle())
                            .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 0.5))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.landscape, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: DS.Radius.landscape, style: .continuous)
                            .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(video.type.uppercased()).font(.system(size: 11, weight: .semibold)).tracking(0.8)
                        .foregroundStyle(.secondary)
                    Text(video.name).font(DS.TypeStyle.cardTitle).lineLimit(2).multilineTextAlignment(.leading)
                }
                .frame(width: width, alignment: .leading)
            }
        }
        .buttonStyle(PressableStyle())
        .animation(.easeOut(duration: 0.3), value: tint == nil)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(video.type): \(video.name)")
        .accessibilityAddTraits(.isButton)
        .task(id: video.key) {
            tint = nil
            guard let u = video.thumbnail, let c = await ImagePipeline.shared.averageColor(for: u), !Task.isCancelled else { return }
            tint = Color(uiColor: c)
        }
    }
}

/// In-app browser for opening a trailer.
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: url) }
    func updateUIViewController(_ vc: SFSafariViewController, context: Context) {}
}
