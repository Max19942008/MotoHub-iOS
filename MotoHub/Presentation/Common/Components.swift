import SwiftUI
import UIKit

/// Network image with the site's empty light gradient when the URL is empty or broken.
struct RemoteImage: View {
    let path: String?
    var contentMode: ContentMode = .fill

    var body: some View {
        if let url = AppConfig.imageURL(path) {
            AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.2))) { phase in
                if case .success(let image) = phase {
                    image.resizable().aspectRatio(contentMode: contentMode)
                } else {
                    ImagePlaceholder()
                }
            }
        } else {
            ImagePlaceholder()
        }
    }
}

struct ImagePlaceholder: View {
    var body: some View {
        LinearGradient(colors: [Color(argb: 0xFFFAFAFA), Color(argb: 0xFFE2E2E2)], startPoint: .top, endPoint: .bottom)
    }
}

/// Fills a box of the given size with an image, cropped (Flutter's BoxFit.cover).
struct CoverImage: View {
    let path: String?

    var body: some View {
        Color.clear
            .overlay { RemoteImage(path: path) }
            .clipped()
    }
}

/// Round member photo; members without one get the site's default avatar.
struct Avatar: View {
    let path: String?
    var size: CGFloat

    var body: some View {
        Group {
            if path == nil || path?.isEmpty == true {
                DefaultAvatar()
            } else {
                CoverImage(path: path)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

/// Grey square with a white silhouette, the site's defaultUser picture.
struct DefaultAvatar: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(argb: 0xFFEDEDED)
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .padding(geo.size.width * 0.12)
                    .offset(y: geo.size.width * 0.06)
            }
        }
    }
}

/// Picked photo -> JPEG of at most `maxSide` px (the backend takes png / jpg / jpeg).
enum ImageEncoding {
    static func jpeg(_ data: Data, maxSide: CGFloat = 1200, quality: CGFloat = 0.85) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: (image.size.width * scale).rounded(), height: (image.size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: quality)
    }
}

/// Confirm dialog contents shared by logout / delete prompts.
struct ConfirmAction: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let button: String
    let action: () -> Void
}

/// Spinner that explains the wait once it gets long (the server may be restarting).
struct LoadingView: View {
    @State private var slow = false

    var body: some View {
        VStack(spacing: 16) {
            ProgressView().controlSize(.large).tint(Brand.green)
            if slow {
                Text("Server uyg'onmoqda, bu bir daqiqagacha cho'zilishi mumkin…".tr)
                    .font(.poppins(14))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .task {
            try? await Task.sleep(for: .seconds(6))
            slow = true
        }
    }
}

struct MessageView: View {
    let systemImage: String
    let message: String
    var onRetry: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 44))
                .foregroundStyle(Color(argb: 0xFF9CA3AF))
            Text(message.tr)
                .font(.poppins(14))
                .multilineTextAlignment(.center)
                .foregroundStyle(Brand.ink)
            if let onRetry {
                Button(action: onRetry) {
                    Text("Qayta urinish".tr)
                        .font(.poppins(14, .semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Brand.green.opacity(0.15), in: Capsule())
                        .foregroundStyle(Brand.greenDark)
                }
                .padding(.top, 4)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

/// Wraps children onto new lines like text (Flutter's Wrap).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat? = nil

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var width: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + (lineSpacing ?? spacing)
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            width = max(width, x - spacing)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + (lineSpacing ?? spacing)
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

/// Thin horizontal rule (Flutter's Divider).
struct Rule: View {
    var color = Color(argb: 0xFFEAEAEA)

    var body: some View {
        color.frame(height: 1)
    }
}

/// The site's bar on pushed pages: dark with the logo; some pages also get a
/// back arrow (others use the green "Orqaga" button in the content).
struct LogoBar: View {
    var back = false
    @Environment(Router.self) private var router

    var body: some View {
        HStack(spacing: 4) {
            if back {
                Button { router.pop() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 44)
                }
                .accessibilityLabel("Orqaga".tr)
            }
            BrandLogo()
            Spacer()
        }
        .padding(.leading, back ? 4 : 16)
        .padding(.trailing, 16)
        .frame(height: 60)
        .background(Brand.ink.ignoresSafeArea(edges: .top))
    }
}

/// Green "← Orqaga" button at the top of sub-pages.
struct BackButton: View {
    @Environment(Router.self) private var router

    var body: some View {
        Button { router.pop() } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.left").font(.system(size: 15, weight: .semibold))
                Text("Orqaga".tr).font(.poppins(14, .medium))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .frame(height: 38)
            .background(Brand.siteGreen, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

extension View {
    /// A pushed page with the site's logo bar instead of the system navigation bar.
    func sitePage(back: Bool = false) -> some View {
        safeAreaInset(edge: .top, spacing: 0) { LogoBar(back: back) }
            .toolbar(.hidden, for: .navigationBar)
    }
}

/// Keeps the swipe-back gesture working on pages that hide the navigation bar.
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
